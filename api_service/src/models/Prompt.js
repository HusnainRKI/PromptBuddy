const { executeQuery, getPaginatedResults } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Prompt {
  static async findAll(options = {}) {
    const {
      page = 1,
      limit = 20,
      categoryId,
      search,
      tags = [],
      excludeTags = [],
      updatedAfter,
      sortBy = 'updated_at',
      sortOrder = 'DESC'
    } = options;

    let whereConditions = [];
    let params = [];

    // Category filter
    if (categoryId) {
      whereConditions.push('p.category_id = ?');
      params.push(categoryId);
    }

    // Search filter
    if (search) {
      whereConditions.push('MATCH(p.title, p.body) AGAINST(? IN BOOLEAN MODE)');
      params.push(`*${search}*`);
    }

    // Updated after filter (for sync)
    if (updatedAfter) {
      whereConditions.push('p.updated_at > ?');
      params.push(updatedAfter);
    }

    // Tag filters
    if (tags.length > 0) {
      const tagPlaceholders = tags.map(() => '?').join(',');
      whereConditions.push(`
        p.id IN (
          SELECT pt.prompt_id FROM prompt_tags pt 
          JOIN tags t ON pt.tag_id = t.id 
          WHERE t.name IN (${tagPlaceholders})
        )
      `);
      params.push(...tags);
    }

    if (excludeTags.length > 0) {
      const excludeTagPlaceholders = excludeTags.map(() => '?').join(',');
      whereConditions.push(`
        p.id NOT IN (
          SELECT pt.prompt_id FROM prompt_tags pt 
          JOIN tags t ON pt.tag_id = t.id 
          WHERE t.name IN (${excludeTagPlaceholders})
        )
      `);
      params.push(...excludeTags);
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';
    const orderClause = `ORDER BY p.${sortBy} ${sortOrder}`;

    const baseQuery = `
      SELECT p.*, 
             c.name as category_name,
             c.color as category_color,
             c.icon as category_icon,
             GROUP_CONCAT(DISTINCT t.name) as tags,
             GROUP_CONCAT(DISTINCT pv.variable_name) as variables
      FROM prompts p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN prompt_tags pt ON p.id = pt.prompt_id
      LEFT JOIN tags t ON pt.tag_id = t.id
      LEFT JOIN prompt_variables pv ON p.id = pv.prompt_id
      ${whereClause}
      GROUP BY p.id
      ${orderClause}
    `;

    const countQuery = `
      SELECT COUNT(DISTINCT p.id) as total
      FROM prompts p
      LEFT JOIN prompt_tags pt ON p.id = pt.prompt_id
      LEFT JOIN tags t ON pt.tag_id = t.id
      ${whereClause}
    `;

    const result = await getPaginatedResults(baseQuery, countQuery, params, page, limit);
    
    // Process results to convert strings to arrays
    result.data = result.data.map(prompt => ({
      ...prompt,
      tags: prompt.tags ? prompt.tags.split(',') : [],
      variables: prompt.variables ? prompt.variables.split(',') : []
    }));

    return result;
  }

  static async findById(id) {
    const query = `
      SELECT p.*, 
             c.name as category_name,
             c.color as category_color,
             c.icon as category_icon,
             GROUP_CONCAT(DISTINCT t.name) as tags,
             GROUP_CONCAT(DISTINCT pv.variable_name) as variables
      FROM prompts p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN prompt_tags pt ON p.id = pt.prompt_id
      LEFT JOIN tags t ON pt.tag_id = t.id
      LEFT JOIN prompt_variables pv ON p.id = pv.prompt_id
      WHERE p.id = ?
      GROUP BY p.id
    `;
    
    const results = await executeQuery(query, [id]);
    const prompt = results[0];
    
    if (!prompt) return null;
    
    return {
      ...prompt,
      tags: prompt.tags ? prompt.tags.split(',') : [],
      variables: prompt.variables ? prompt.variables.split(',') : []
    };
  }

  static async create(data) {
    const id = uuidv4();
    const { title, body, categoryId, language = 'en', tags = [] } = data;

    try {
      await executeQuery('START TRANSACTION');

      // Create the prompt
      const promptQuery = `
        INSERT INTO prompts (id, title, body, category_id, language)
        VALUES (?, ?, ?, ?, ?)
      `;
      await executeQuery(promptQuery, [id, title, body, categoryId, language]);

      // Parse and save variables
      const variables = this.parseVariables(body);
      if (variables.length > 0) {
        await this.saveVariables(id, variables);
      }

      // Save tags
      if (tags.length > 0) {
        await this.saveTags(id, tags);
      }

      await executeQuery('COMMIT');
      return await this.findById(id);

    } catch (error) {
      await executeQuery('ROLLBACK');
      throw error;
    }
  }

  static async update(id, data, updatedAt = null) {
    const { title, body, categoryId, language, tags } = data;
    
    try {
      await executeQuery('START TRANSACTION');

      // Check for conflicts if updatedAt is provided
      if (updatedAt) {
        const existing = await executeQuery(
          'SELECT updated_at FROM prompts WHERE id = ?', 
          [id]
        );
        
        if (existing.length === 0) {
          throw new Error('Prompt not found');
        }
        
        const serverUpdatedAt = new Date(existing[0].updated_at);
        const clientUpdatedAt = new Date(updatedAt);
        
        if (serverUpdatedAt > clientUpdatedAt) {
          throw new Error('Conflict: Server version is newer');
        }
      }

      const updates = [];
      const values = [];

      if (title !== undefined) {
        updates.push('title = ?');
        values.push(title);
      }
      if (body !== undefined) {
        updates.push('body = ?');
        values.push(body);
      }
      if (categoryId !== undefined) {
        updates.push('category_id = ?');
        values.push(categoryId);
      }
      if (language !== undefined) {
        updates.push('language = ?');
        values.push(language);
      }

      if (updates.length === 0 && !tags) {
        throw new Error('No fields to update');
      }

      if (updates.length > 0) {
        updates.push('updated_at = CURRENT_TIMESTAMP');
        values.push(id);

        const query = `UPDATE prompts SET ${updates.join(', ')} WHERE id = ?`;
        const result = await executeQuery(query, values);

        if (result.affectedRows === 0) {
          throw new Error('Prompt not found');
        }
      }

      // Update variables if body changed
      if (body !== undefined) {
        await executeQuery('DELETE FROM prompt_variables WHERE prompt_id = ?', [id]);
        const variables = this.parseVariables(body);
        if (variables.length > 0) {
          await this.saveVariables(id, variables);
        }
      }

      // Update tags if provided
      if (tags !== undefined) {
        await executeQuery('DELETE FROM prompt_tags WHERE prompt_id = ?', [id]);
        if (tags.length > 0) {
          await this.saveTags(id, tags);
        }
      }

      await executeQuery('COMMIT');
      return await this.findById(id);

    } catch (error) {
      await executeQuery('ROLLBACK');
      throw error;
    }
  }

  static async delete(id) {
    // Cascade deletes are handled by foreign key constraints
    const result = await executeQuery('DELETE FROM prompts WHERE id = ?', [id]);
    
    if (result.affectedRows === 0) {
      throw new Error('Prompt not found');
    }
    
    return { success: true, message: 'Prompt deleted successfully' };
  }

  static async incrementUsage(id) {
    await executeQuery(
      'UPDATE prompts SET usage_count = usage_count + 1, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [id]
    );
  }

  static async bulkOperations(operation, promptIds, data = {}) {
    try {
      await executeQuery('START TRANSACTION');

      const placeholders = promptIds.map(() => '?').join(',');

      switch (operation) {
        case 'delete':
          await executeQuery(`DELETE FROM prompts WHERE id IN (${placeholders})`, promptIds);
          break;
          
        case 'move_category':
          if (!data.categoryId) throw new Error('Category ID required for move operation');
          await executeQuery(
            `UPDATE prompts SET category_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id IN (${placeholders})`,
            [data.categoryId, ...promptIds]
          );
          break;
          
        default:
          throw new Error('Invalid bulk operation');
      }

      await executeQuery('COMMIT');
      return { success: true, affected: promptIds.length };

    } catch (error) {
      await executeQuery('ROLLBACK');
      throw error;
    }
  }

  static parseVariables(body) {
    const variableRegex = /\{\{([^}]+)\}\}/g;
    const variables = new Set();
    let match;

    while ((match = variableRegex.exec(body)) !== null) {
      const variableName = match[1].trim();
      if (variableName) {
        variables.add(variableName);
      }
    }

    return Array.from(variables);
  }

  static async saveVariables(promptId, variables) {
    if (variables.length === 0) return;

    const values = variables.map(variable => [promptId, variable]);
    const placeholders = values.map(() => '(?, ?)').join(',');
    
    const query = `INSERT INTO prompt_variables (prompt_id, variable_name) VALUES ${placeholders}`;
    await executeQuery(query, values.flat());
  }

  static async saveTags(promptId, tags) {
    if (tags.length === 0) return;

    // First, ensure all tags exist
    for (const tag of tags) {
      await executeQuery(
        'INSERT IGNORE INTO tags (name) VALUES (?)',
        [tag.trim()]
      );
    }

    // Get tag IDs
    const tagPlaceholders = tags.map(() => '?').join(',');
    const tagIds = await executeQuery(
      `SELECT id FROM tags WHERE name IN (${tagPlaceholders})`,
      tags
    );

    // Create associations
    const values = tagIds.map(tag => [promptId, tag.id]);
    const placeholders = values.map(() => '(?, ?)').join(',');
    
    const query = `INSERT INTO prompt_tags (prompt_id, tag_id) VALUES ${placeholders}`;
    await executeQuery(query, values.flat());
  }

  static async getRecentlyUsed(limit = 10) {
    const query = `
      SELECT p.*, c.name as category_name, c.color as category_color
      FROM prompts p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.usage_count > 0
      ORDER BY p.updated_at DESC
      LIMIT ?
    `;
    
    return await executeQuery(query, [limit]);
  }
}

module.exports = Prompt;
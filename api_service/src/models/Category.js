const { executeQuery, getPaginatedResults } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

class Category {
  static async findAll(page = 1, limit = 50) {
    const baseQuery = `
      SELECT c.*, 
             COUNT(p.id) as prompt_count
      FROM categories c 
      LEFT JOIN prompts p ON c.id = p.category_id 
      GROUP BY c.id 
      ORDER BY c.order_index ASC, c.name ASC
    `;
    
    const countQuery = `
      SELECT COUNT(DISTINCT c.id) as total 
      FROM categories c
    `;
    
    return await getPaginatedResults(baseQuery, countQuery, [], page, limit);
  }

  static async findById(id) {
    const query = `
      SELECT c.*, 
             COUNT(p.id) as prompt_count
      FROM categories c 
      LEFT JOIN prompts p ON c.id = p.category_id 
      WHERE c.id = ? 
      GROUP BY c.id
    `;
    
    const results = await executeQuery(query, [id]);
    return results[0] || null;
  }

  static async create(data) {
    const id = uuidv4();
    const { name, icon = 'folder', color = 0xFF2196F3 } = data;
    
    // Get the next order index
    const maxOrderResult = await executeQuery(
      'SELECT COALESCE(MAX(order_index), -1) + 1 as next_order FROM categories'
    );
    const orderIndex = maxOrderResult[0].next_order;
    
    const query = `
      INSERT INTO categories (id, name, icon, color, order_index)
      VALUES (?, ?, ?, ?, ?)
    `;
    
    await executeQuery(query, [id, name, icon, color, orderIndex]);
    return await this.findById(id);
  }

  static async update(id, data) {
    const { name, icon, color } = data;
    const updates = [];
    const values = [];
    
    if (name !== undefined) {
      updates.push('name = ?');
      values.push(name);
    }
    if (icon !== undefined) {
      updates.push('icon = ?');
      values.push(icon);
    }
    if (color !== undefined) {
      updates.push('color = ?');
      values.push(color);
    }
    
    if (updates.length === 0) {
      throw new Error('No fields to update');
    }
    
    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(id);
    
    const query = `UPDATE categories SET ${updates.join(', ')} WHERE id = ?`;
    const result = await executeQuery(query, values);
    
    if (result.affectedRows === 0) {
      throw new Error('Category not found');
    }
    
    return await this.findById(id);
  }

  static async delete(id, moveToCategory = null) {
    try {
      await executeQuery('START TRANSACTION');
      
      if (moveToCategory) {
        // Move prompts to another category
        await executeQuery(
          'UPDATE prompts SET category_id = ? WHERE category_id = ?',
          [moveToCategory, id]
        );
      } else {
        // Set category_id to NULL for orphaned prompts
        await executeQuery(
          'UPDATE prompts SET category_id = NULL WHERE category_id = ?',
          [id]
        );
      }
      
      // Delete the category
      const result = await executeQuery('DELETE FROM categories WHERE id = ?', [id]);
      
      if (result.affectedRows === 0) {
        throw new Error('Category not found');
      }
      
      await executeQuery('COMMIT');
      return { success: true, message: 'Category deleted successfully' };
      
    } catch (error) {
      await executeQuery('ROLLBACK');
      throw error;
    }
  }

  static async reorder(categoryOrders) {
    try {
      await executeQuery('START TRANSACTION');
      
      for (const { id, order_index } of categoryOrders) {
        await executeQuery(
          'UPDATE categories SET order_index = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
          [order_index, id]
        );
      }
      
      await executeQuery('COMMIT');
      return { success: true, message: 'Categories reordered successfully' };
      
    } catch (error) {
      await executeQuery('ROLLBACK');
      throw error;
    }
  }

  static async getWithPromptCounts() {
    const query = `
      SELECT c.*, 
             COUNT(p.id) as prompt_count
      FROM categories c 
      LEFT JOIN prompts p ON c.id = p.category_id 
      GROUP BY c.id 
      ORDER BY c.order_index ASC, c.name ASC
    `;
    
    return await executeQuery(query);
  }
}

module.exports = Category;
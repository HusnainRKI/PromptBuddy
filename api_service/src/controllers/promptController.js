const Prompt = require('../models/Prompt');
const { validationResult } = require('express-validator');

class PromptController {
  // GET /api/prompts
  static async getAllPrompts(req, res) {
    try {
      const {
        page = 1,
        limit = 20,
        categoryId,
        search,
        tags = '',
        excludeTags = '',
        updatedAfter,
        sortBy = 'updated_at',
        sortOrder = 'DESC'
      } = req.query;

      const options = {
        page: parseInt(page),
        limit: parseInt(limit),
        categoryId,
        search,
        tags: tags ? tags.split(',').map(t => t.trim()).filter(t => t) : [],
        excludeTags: excludeTags ? excludeTags.split(',').map(t => t.trim()).filter(t => t) : [],
        updatedAfter,
        sortBy,
        sortOrder: sortOrder.toUpperCase()
      };

      const result = await Prompt.findAll(options);
      
      res.json({
        success: true,
        data: result.data,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Get prompts error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch prompts',
        error: error.message
      });
    }
  }

  // GET /api/prompts/:id
  static async getPromptById(req, res) {
    try {
      const { id } = req.params;
      const prompt = await Prompt.findById(id);
      
      if (!prompt) {
        return res.status(404).json({
          success: false,
          message: 'Prompt not found'
        });
      }
      
      res.json({
        success: true,
        data: prompt
      });
    } catch (error) {
      console.error('Get prompt error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch prompt',
        error: error.message
      });
    }
  }

  // POST /api/prompts
  static async createPrompt(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { title, body, categoryId, language, tags } = req.body;
      
      const prompt = await Prompt.create({
        title,
        body,
        categoryId,
        language,
        tags: tags || []
      });
      
      res.status(201).json({
        success: true,
        data: prompt,
        message: 'Prompt created successfully'
      });
    } catch (error) {
      console.error('Create prompt error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create prompt',
        error: error.message
      });
    }
  }

  // PUT /api/prompts/:id
  static async updatePrompt(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { id } = req.params;
      const { title, body, categoryId, language, tags, updatedAt } = req.body;
      
      const prompt = await Prompt.update(id, {
        title,
        body,
        categoryId,
        language,
        tags
      }, updatedAt);
      
      res.json({
        success: true,
        data: prompt,
        message: 'Prompt updated successfully'
      });
    } catch (error) {
      console.error('Update prompt error:', error);
      
      if (error.message === 'Prompt not found') {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }
      
      if (error.message.includes('Conflict')) {
        return res.status(409).json({
          success: false,
          message: error.message,
          type: 'conflict'
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to update prompt',
        error: error.message
      });
    }
  }

  // DELETE /api/prompts/:id
  static async deletePrompt(req, res) {
    try {
      const { id } = req.params;
      
      const result = await Prompt.delete(id);
      
      res.json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('Delete prompt error:', error);
      
      if (error.message === 'Prompt not found') {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to delete prompt',
        error: error.message
      });
    }
  }

  // POST /api/prompts/:id/duplicate
  static async duplicatePrompt(req, res) {
    try {
      const { id } = req.params;
      const { title } = req.body;
      
      const originalPrompt = await Prompt.findById(id);
      if (!originalPrompt) {
        return res.status(404).json({
          success: false,
          message: 'Original prompt not found'
        });
      }
      
      const duplicatedPrompt = await Prompt.create({
        title: title || `${originalPrompt.title} (Copy)`,
        body: originalPrompt.body,
        categoryId: originalPrompt.category_id,
        language: originalPrompt.language,
        tags: originalPrompt.tags
      });
      
      res.status(201).json({
        success: true,
        data: duplicatedPrompt,
        message: 'Prompt duplicated successfully'
      });
    } catch (error) {
      console.error('Duplicate prompt error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to duplicate prompt',
        error: error.message
      });
    }
  }

  // PUT /api/prompts/:id/usage
  static async incrementUsage(req, res) {
    try {
      const { id } = req.params;
      
      await Prompt.incrementUsage(id);
      
      res.json({
        success: true,
        message: 'Usage count incremented'
      });
    } catch (error) {
      console.error('Increment usage error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to increment usage',
        error: error.message
      });
    }
  }

  // POST /api/prompts/bulk
  static async bulkOperations(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { operation, promptIds, data = {} } = req.body;
      
      if (!Array.isArray(promptIds) || promptIds.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'promptIds must be a non-empty array'
        });
      }
      
      const result = await Prompt.bulkOperations(operation, promptIds, data);
      
      res.json({
        success: true,
        message: `Bulk ${operation} completed`,
        affected: result.affected
      });
    } catch (error) {
      console.error('Bulk operations error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to perform bulk operation',
        error: error.message
      });
    }
  }

  // GET /api/prompts/recent
  static async getRecentlyUsed(req, res) {
    try {
      const limit = parseInt(req.query.limit) || 10;
      const prompts = await Prompt.getRecentlyUsed(limit);
      
      res.json({
        success: true,
        data: prompts
      });
    } catch (error) {
      console.error('Get recently used error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch recently used prompts',
        error: error.message
      });
    }
  }

  // POST /api/prompts/parse-variables
  static async parseVariables(req, res) {
    try {
      const { body } = req.body;
      
      if (!body) {
        return res.status(400).json({
          success: false,
          message: 'Body text is required'
        });
      }
      
      const variables = Prompt.parseVariables(body);
      
      res.json({
        success: true,
        data: {
          variables,
          count: variables.length
        }
      });
    } catch (error) {
      console.error('Parse variables error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to parse variables',
        error: error.message
      });
    }
  }
}

module.exports = PromptController;
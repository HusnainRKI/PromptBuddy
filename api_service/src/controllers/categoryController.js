const Category = require('../models/Category');
const { validationResult } = require('express-validator');

class CategoryController {
  // GET /api/categories
  static async getAllCategories(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 50;
      
      const result = await Category.findAll(page, limit);
      
      res.json({
        success: true,
        data: result.data,
        pagination: result.pagination
      });
    } catch (error) {
      console.error('Get categories error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch categories',
        error: error.message
      });
    }
  }

  // GET /api/categories/:id
  static async getCategoryById(req, res) {
    try {
      const { id } = req.params;
      const category = await Category.findById(id);
      
      if (!category) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }
      
      res.json({
        success: true,
        data: category
      });
    } catch (error) {
      console.error('Get category error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch category',
        error: error.message
      });
    }
  }

  // POST /api/categories
  static async createCategory(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { name, icon, color } = req.body;
      
      const category = await Category.create({
        name,
        icon,
        color: color ? parseInt(color) : undefined
      });
      
      res.status(201).json({
        success: true,
        data: category,
        message: 'Category created successfully'
      });
    } catch (error) {
      console.error('Create category error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to create category',
        error: error.message
      });
    }
  }

  // PUT /api/categories/:id
  static async updateCategory(req, res) {
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
      const { name, icon, color } = req.body;
      
      const category = await Category.update(id, {
        name,
        icon,
        color: color ? parseInt(color) : undefined
      });
      
      res.json({
        success: true,
        data: category,
        message: 'Category updated successfully'
      });
    } catch (error) {
      console.error('Update category error:', error);
      
      if (error.message === 'Category not found') {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to update category',
        error: error.message
      });
    }
  }

  // DELETE /api/categories/:id
  static async deleteCategory(req, res) {
    try {
      const { id } = req.params;
      const { moveToCategory } = req.body;
      
      const result = await Category.delete(id, moveToCategory);
      
      res.json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('Delete category error:', error);
      
      if (error.message === 'Category not found') {
        return res.status(404).json({
          success: false,
          message: error.message
        });
      }
      
      res.status(500).json({
        success: false,
        message: 'Failed to delete category',
        error: error.message
      });
    }
  }

  // PUT /api/categories/reorder
  static async reorderCategories(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { categoryOrders } = req.body;
      
      if (!Array.isArray(categoryOrders) || categoryOrders.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'categoryOrders must be a non-empty array'
        });
      }
      
      const result = await Category.reorder(categoryOrders);
      
      res.json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('Reorder categories error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to reorder categories',
        error: error.message
      });
    }
  }

  // GET /api/categories/with-counts
  static async getCategoriesWithCounts(req, res) {
    try {
      const categories = await Category.getWithPromptCounts();
      
      res.json({
        success: true,
        data: categories
      });
    } catch (error) {
      console.error('Get categories with counts error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch categories with counts',
        error: error.message
      });
    }
  }
}

module.exports = CategoryController;
const Category = require('../models/Category');
const Prompt = require('../models/Prompt');
const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');

class ImportExportController {
  // POST /api/import
  static async importData(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { data, dryRun = false } = req.body;
      const { categories = [], prompts = [] } = data;

      const result = {
        categories: {
          new: 0,
          updated: 0,
          skipped: 0,
          errors: []
        },
        prompts: {
          new: 0,
          updated: 0,
          skipped: 0,
          errors: []
        }
      };

      // Validate input data structure
      if (!Array.isArray(categories) || !Array.isArray(prompts)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid data format. Expected categories and prompts arrays.'
        });
      }

      if (!dryRun) {
        // Start transaction for actual import
        await require('../config/database').executeQuery('START TRANSACTION');
      }

      try {
        // Process categories first
        const categoryIdMap = new Map(); // Map old IDs to new IDs
        
        for (const categoryData of categories) {
          try {
            // Validate required fields
            if (!categoryData.name || typeof categoryData.name !== 'string') {
              result.categories.errors.push(`Invalid category: missing or invalid name`);
              result.categories.skipped++;
              continue;
            }

            let existingCategory = null;
            
            // Check if category exists by ID or name
            if (categoryData.id) {
              existingCategory = await Category.findById(categoryData.id);
            }
            
            if (!existingCategory) {
              // Check by name
              const categoriesByName = await require('../config/database').executeQuery(
                'SELECT * FROM categories WHERE name = ?',
                [categoryData.name]
              );
              existingCategory = categoriesByName[0] || null;
            }

            if (existingCategory) {
              // Update existing category if incoming data is newer
              const shouldUpdate = !categoryData.updatedAt || 
                !existingCategory.updated_at ||
                new Date(categoryData.updatedAt) > new Date(existingCategory.updated_at);

              if (shouldUpdate && !dryRun) {
                await Category.update(existingCategory.id, {
                  name: categoryData.name,
                  icon: categoryData.icon,
                  color: categoryData.color
                });
                result.categories.updated++;
              } else {
                result.categories.skipped++;
              }
              
              categoryIdMap.set(categoryData.id || categoryData.name, existingCategory.id);
            } else {
              // Create new category
              if (!dryRun) {
                const newCategory = await Category.create({
                  name: categoryData.name,
                  icon: categoryData.icon || 'folder',
                  color: categoryData.color || 0xFF2196F3
                });
                categoryIdMap.set(categoryData.id || categoryData.name, newCategory.id);
              } else {
                const newId = uuidv4();
                categoryIdMap.set(categoryData.id || categoryData.name, newId);
              }
              result.categories.new++;
            }
          } catch (error) {
            result.categories.errors.push(`Category '${categoryData.name}': ${error.message}`);
            result.categories.skipped++;
          }
        }

        // Process prompts
        for (const promptData of prompts) {
          try {
            // Validate required fields
            if (!promptData.title || !promptData.body) {
              result.prompts.errors.push(`Invalid prompt: missing title or body`);
              result.prompts.skipped++;
              continue;
            }

            let existingPrompt = null;
            
            // Check if prompt exists by ID
            if (promptData.id) {
              existingPrompt = await Prompt.findById(promptData.id);
            }
            
            // Map category ID if it references an imported category
            let categoryId = promptData.categoryId;
            if (categoryId && categoryIdMap.has(categoryId)) {
              categoryId = categoryIdMap.get(categoryId);
            }

            if (existingPrompt) {
              // Update existing prompt if incoming data is newer
              const shouldUpdate = !promptData.updatedAt || 
                !existingPrompt.updated_at ||
                new Date(promptData.updatedAt) > new Date(existingPrompt.updated_at);

              if (shouldUpdate && !dryRun) {
                await Prompt.update(existingPrompt.id, {
                  title: promptData.title,
                  body: promptData.body,
                  categoryId: categoryId,
                  language: promptData.language,
                  tags: promptData.tags || []
                });
                result.prompts.updated++;
              } else {
                result.prompts.skipped++;
              }
            } else {
              // Create new prompt
              if (!dryRun) {
                await Prompt.create({
                  title: promptData.title,
                  body: promptData.body,
                  categoryId: categoryId,
                  language: promptData.language || 'en',
                  tags: promptData.tags || []
                });
              }
              result.prompts.new++;
            }
          } catch (error) {
            result.prompts.errors.push(`Prompt '${promptData.title}': ${error.message}`);
            result.prompts.skipped++;
          }
        }

        if (!dryRun) {
          await require('../config/database').executeQuery('COMMIT');
        }

        res.json({
          success: true,
          data: result,
          message: dryRun ? 'Import preview completed' : 'Import completed successfully'
        });

      } catch (error) {
        if (!dryRun) {
          await require('../config/database').executeQuery('ROLLBACK');
        }
        throw error;
      }

    } catch (error) {
      console.error('Import error:', error);
      res.status(500).json({
        success: false,
        message: 'Import failed',
        error: error.message
      });
    }
  }

  // GET /api/export
  static async exportData(req, res) {
    try {
      const { 
        categories: includeCategories = true, 
        prompts: includePrompts = true,
        categoryId 
      } = req.query;

      const exportData = {
        version: '1.0',
        exportedAt: new Date().toISOString(),
        categories: [],
        prompts: []
      };

      // Export categories
      if (includeCategories === 'true' || includeCategories === true) {
        const categoriesResult = await Category.findAll(1, 1000); // Get all categories
        exportData.categories = categoriesResult.data.map(cat => ({
          id: cat.id,
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          order_index: cat.order_index,
          createdAt: cat.created_at,
          updatedAt: cat.updated_at
        }));
      }

      // Export prompts
      if (includePrompts === 'true' || includePrompts === true) {
        const promptOptions = {
          page: 1,
          limit: 10000, // Get all prompts
          categoryId: categoryId || undefined
        };
        
        const promptsResult = await Prompt.findAll(promptOptions);
        exportData.prompts = promptsResult.data.map(prompt => ({
          id: prompt.id,
          title: prompt.title,
          body: prompt.body,
          categoryId: prompt.category_id,
          language: prompt.language,
          tags: prompt.tags || [],
          variables: prompt.variables || [],
          usageCount: prompt.usage_count,
          createdAt: prompt.created_at,
          updatedAt: prompt.updated_at
        }));
      }

      res.json({
        success: true,
        data: exportData,
        message: 'Export completed successfully'
      });

    } catch (error) {
      console.error('Export error:', error);
      res.status(500).json({
        success: false,
        message: 'Export failed',
        error: error.message
      });
    }
  }

  // POST /api/export/download
  static async downloadExport(req, res) {
    try {
      const { 
        categories: includeCategories = true, 
        prompts: includePrompts = true,
        categoryId,
        filename
      } = req.body;

      const exportData = {
        version: '1.0',
        exportedAt: new Date().toISOString(),
        categories: [],
        prompts: []
      };

      // Export categories
      if (includeCategories) {
        const categoriesResult = await Category.findAll(1, 1000);
        exportData.categories = categoriesResult.data.map(cat => ({
          id: cat.id,
          name: cat.name,
          icon: cat.icon,
          color: cat.color,
          order_index: cat.order_index,
          createdAt: cat.created_at,
          updatedAt: cat.updated_at
        }));
      }

      // Export prompts
      if (includePrompts) {
        const promptOptions = {
          page: 1,
          limit: 10000,
          categoryId: categoryId || undefined
        };
        
        const promptsResult = await Prompt.findAll(promptOptions);
        exportData.prompts = promptsResult.data.map(prompt => ({
          id: prompt.id,
          title: prompt.title,
          body: prompt.body,
          categoryId: prompt.category_id,
          language: prompt.language,
          tags: prompt.tags || [],
          variables: prompt.variables || [],
          usageCount: prompt.usage_count,
          createdAt: prompt.created_at,
          updatedAt: prompt.updated_at
        }));
      }

      const downloadFilename = filename || `promptbuddy-export-${new Date().toISOString().split('T')[0]}.json`;

      res.setHeader('Content-Type', 'application/json');
      res.setHeader('Content-Disposition', `attachment; filename="${downloadFilename}"`);
      res.json(exportData);

    } catch (error) {
      console.error('Download export error:', error);
      res.status(500).json({
        success: false,
        message: 'Download failed',
        error: error.message
      });
    }
  }

  // POST /api/validate-import
  static async validateImportData(req, res) {
    try {
      const { data } = req.body;
      
      if (!data || typeof data !== 'object') {
        return res.status(400).json({
          success: false,
          message: 'Invalid data format'
        });
      }

      const validation = {
        valid: true,
        errors: [],
        warnings: [],
        summary: {
          categories: 0,
          prompts: 0,
          variables: 0
        }
      };

      const { categories = [], prompts = [] } = data;

      // Validate categories
      if (Array.isArray(categories)) {
        validation.summary.categories = categories.length;
        
        categories.forEach((cat, index) => {
          if (!cat.name || typeof cat.name !== 'string') {
            validation.errors.push(`Category ${index + 1}: Missing or invalid name`);
            validation.valid = false;
          }
          if (cat.name && cat.name.length > 255) {
            validation.errors.push(`Category ${index + 1}: Name too long (max 255 characters)`);
            validation.valid = false;
          }
        });
      }

      // Validate prompts
      if (Array.isArray(prompts)) {
        validation.summary.prompts = prompts.length;
        
        prompts.forEach((prompt, index) => {
          if (!prompt.title || typeof prompt.title !== 'string') {
            validation.errors.push(`Prompt ${index + 1}: Missing or invalid title`);
            validation.valid = false;
          }
          if (!prompt.body || typeof prompt.body !== 'string') {
            validation.errors.push(`Prompt ${index + 1}: Missing or invalid body`);
            validation.valid = false;
          }
          
          // Count variables
          if (prompt.body) {
            const variables = Prompt.parseVariables(prompt.body);
            validation.summary.variables += variables.length;
          }
          
          // Validate tags
          if (prompt.tags && !Array.isArray(prompt.tags)) {
            validation.errors.push(`Prompt ${index + 1}: Tags must be an array`);
            validation.valid = false;
          }
        });
      }

      res.json({
        success: true,
        data: validation,
        message: validation.valid ? 'Data is valid for import' : 'Data has validation errors'
      });

    } catch (error) {
      console.error('Validate import error:', error);
      res.status(500).json({
        success: false,
        message: 'Validation failed',
        error: error.message
      });
    }
  }
}

module.exports = ImportExportController;
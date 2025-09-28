const { body, param, query } = require('express-validator');

// Category validation rules
const categoryValidation = {
  create: [
    body('name')
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Name must be between 1 and 255 characters'),
    body('icon')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('Icon must be max 100 characters'),
    body('color')
      .optional()
      .isInt({ min: 0, max: 4294967295 })
      .withMessage('Color must be a valid integer')
  ],
  
  update: [
    param('id').isUUID().withMessage('Invalid category ID'),
    body('name')
      .optional()
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Name must be between 1 and 255 characters'),
    body('icon')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('Icon must be max 100 characters'),
    body('color')
      .optional()
      .isInt({ min: 0, max: 4294967295 })
      .withMessage('Color must be a valid integer')
  ],
  
  reorder: [
    body('categoryOrders')
      .isArray({ min: 1 })
      .withMessage('categoryOrders must be a non-empty array'),
    body('categoryOrders.*.id')
      .isUUID()
      .withMessage('Each category ID must be valid'),
    body('categoryOrders.*.order_index')
      .isInt({ min: 0 })
      .withMessage('Each order_index must be a non-negative integer')
  ]
};

// Prompt validation rules
const promptValidation = {
  create: [
    body('title')
      .trim()
      .isLength({ min: 1, max: 500 })
      .withMessage('Title must be between 1 and 500 characters'),
    body('body')
      .trim()
      .isLength({ min: 1 })
      .withMessage('Body is required'),
    body('categoryId')
      .optional()
      .isUUID()
      .withMessage('Category ID must be valid'),
    body('language')
      .optional()
      .trim()
      .isLength({ max: 10 })
      .withMessage('Language must be max 10 characters'),
    body('tags')
      .optional()
      .isArray()
      .withMessage('Tags must be an array'),
    body('tags.*')
      .optional()
      .trim()
      .isLength({ min: 1, max: 100 })
      .withMessage('Each tag must be between 1 and 100 characters')
  ],
  
  update: [
    param('id').isUUID().withMessage('Invalid prompt ID'),
    body('title')
      .optional()
      .trim()
      .isLength({ min: 1, max: 500 })
      .withMessage('Title must be between 1 and 500 characters'),
    body('body')
      .optional()
      .trim()
      .isLength({ min: 1 })
      .withMessage('Body cannot be empty'),
    body('categoryId')
      .optional()
      .isUUID()
      .withMessage('Category ID must be valid'),
    body('language')
      .optional()
      .trim()
      .isLength({ max: 10 })
      .withMessage('Language must be max 10 characters'),
    body('tags')
      .optional()
      .isArray()
      .withMessage('Tags must be an array'),
    body('tags.*')
      .optional()
      .trim()
      .isLength({ min: 1, max: 100 })
      .withMessage('Each tag must be between 1 and 100 characters'),
    body('updatedAt')
      .optional()
      .isISO8601()
      .withMessage('updatedAt must be a valid ISO date')
  ],
  
  bulk: [
    body('operation')
      .isIn(['delete', 'move_category'])
      .withMessage('Operation must be delete or move_category'),
    body('promptIds')
      .isArray({ min: 1 })
      .withMessage('promptIds must be a non-empty array'),
    body('promptIds.*')
      .isUUID()
      .withMessage('Each prompt ID must be valid'),
    body('data.categoryId')
      .if(body('operation').equals('move_category'))
      .isUUID()
      .withMessage('Category ID required for move operation')
  ]
};

// Auth validation rules
const authValidation = {
  login: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters')
  ],
  
  register: [
    body('email')
      .isEmail()
      .normalizeEmail()
      .withMessage('Valid email is required'),
    body('password')
      .isLength({ min: 6 })
      .withMessage('Password must be at least 6 characters'),
    body('name')
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Name must be between 1 and 255 characters'),
    body('role')
      .optional()
      .isIn(['admin', 'editor', 'viewer'])
      .withMessage('Role must be admin, editor, or viewer')
  ],
  
  updateProfile: [
    body('name')
      .optional()
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Name must be between 1 and 255 characters'),
    body('email')
      .optional()
      .isEmail()
      .normalizeEmail()
      .withMessage('Valid email is required'),
    body('currentPassword')
      .if(body('newPassword').exists())
      .isLength({ min: 6 })
      .withMessage('Current password is required when changing password'),
    body('newPassword')
      .optional()
      .isLength({ min: 6 })
      .withMessage('New password must be at least 6 characters')
  ],
  
  updateRole: [
    param('id').isUUID().withMessage('Invalid user ID'),
    body('role')
      .isIn(['admin', 'editor', 'viewer'])
      .withMessage('Role must be admin, editor, or viewer')
  ]
};

// Import/Export validation
const importExportValidation = {
  import: [
    body('data')
      .isObject()
      .withMessage('Data must be an object'),
    body('data.categories')
      .optional()
      .isArray()
      .withMessage('Categories must be an array'),
    body('data.prompts')
      .optional()
      .isArray()
      .withMessage('Prompts must be an array'),
    body('dryRun')
      .optional()
      .isBoolean()
      .withMessage('dryRun must be a boolean')
  ]
};

// Common parameter validation
const paramValidation = {
  id: param('id').isUUID().withMessage('Invalid ID format')
};

// Query parameter validation
const queryValidation = {
  pagination: [
    query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100')
  ]
};

module.exports = {
  categoryValidation,
  promptValidation,
  authValidation,
  importExportValidation,
  paramValidation,
  queryValidation
};
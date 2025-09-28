const express = require('express');
const CategoryController = require('../controllers/categoryController');
const { optionalAuth, authenticate, authorize } = require('../middleware/auth');
const { categoryValidation, paramValidation, queryValidation } = require('../middleware/validation');

const router = express.Router();

// Public routes (mobile app access)
router.get('/', optionalAuth, queryValidation.pagination, CategoryController.getAllCategories);
router.get('/with-counts', optionalAuth, CategoryController.getCategoriesWithCounts);
router.get('/:id', optionalAuth, paramValidation.id, CategoryController.getCategoryById);

// Protected routes (CMS access - require authentication and write permission)
router.post('/', authenticate, authorize('write'), categoryValidation.create, CategoryController.createCategory);
router.put('/:id', authenticate, authorize('write'), categoryValidation.update, CategoryController.updateCategory);
router.delete('/:id', authenticate, authorize('delete'), paramValidation.id, CategoryController.deleteCategory);
router.put('/reorder', authenticate, authorize('write'), categoryValidation.reorder, CategoryController.reorderCategories);

module.exports = router;
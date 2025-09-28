const express = require('express');
const PromptController = require('../controllers/promptController');
const { optionalAuth, authenticate, authorize } = require('../middleware/auth');
const { promptValidation, paramValidation, queryValidation } = require('../middleware/validation');

const router = express.Router();

// Public routes (mobile app access)
router.get('/', optionalAuth, queryValidation.pagination, PromptController.getAllPrompts);
router.get('/recent', optionalAuth, PromptController.getRecentlyUsed);
router.get('/:id', optionalAuth, paramValidation.id, PromptController.getPromptById);
router.put('/:id/usage', optionalAuth, paramValidation.id, PromptController.incrementUsage);

// Utility routes
router.post('/parse-variables', PromptController.parseVariables);

// Protected routes (CMS access - require authentication and write permission)
router.post('/', authenticate, authorize('write'), promptValidation.create, PromptController.createPrompt);
router.put('/:id', authenticate, authorize('write'), promptValidation.update, PromptController.updatePrompt);
router.delete('/:id', authenticate, authorize('delete'), paramValidation.id, PromptController.deletePrompt);
router.post('/:id/duplicate', authenticate, authorize('write'), paramValidation.id, PromptController.duplicatePrompt);
router.post('/bulk', authenticate, authorize('write'), promptValidation.bulk, PromptController.bulkOperations);

module.exports = router;
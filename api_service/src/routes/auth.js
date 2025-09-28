const express = require('express');
const AuthController = require('../controllers/authController');
const { authenticate, authorize, requireRole } = require('../middleware/auth');
const { authValidation } = require('../middleware/validation');

const router = express.Router();

// Public routes
router.post('/login', authValidation.login, AuthController.login);

// Protected routes
router.get('/me', authenticate, AuthController.getCurrentUser);
router.put('/profile', authenticate, authValidation.updateProfile, AuthController.updateProfile);

// Admin only routes
router.post('/register', authenticate, requireRole('admin'), authValidation.register, AuthController.register);
router.get('/users', authenticate, requireRole('admin'), AuthController.getAllUsers);
router.put('/users/:id/role', authenticate, requireRole('admin'), authValidation.updateRole, AuthController.updateUserRole);

module.exports = router;
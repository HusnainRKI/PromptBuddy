const { executeQuery } = require('../config/database');
const { generateToken, comparePassword, hashPassword, ROLES } = require('../config/auth');
const { validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');

class AuthController {
  // POST /api/auth/login
  static async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { email, password } = req.body;
      
      // Find user by email
      const users = await executeQuery(
        'SELECT id, email, password, name, role FROM users WHERE email = ?',
        [email]
      );
      
      if (users.length === 0) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }
      
      const user = users[0];
      
      // Verify password
      const isValidPassword = await comparePassword(password, user.password);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password'
        });
      }
      
      // Generate JWT token
      const token = generateToken({
        id: user.id,
        email: user.email,
        role: user.role
      });
      
      res.json({
        success: true,
        data: {
          user: {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role
          },
          token
        },
        message: 'Login successful'
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Login failed',
        error: error.message
      });
    }
  }

  // POST /api/auth/register (Admin only for CMS users)
  static async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const { email, password, name, role = ROLES.VIEWER } = req.body;
      
      // Check if user already exists
      const existingUsers = await executeQuery(
        'SELECT id FROM users WHERE email = ?',
        [email]
      );
      
      if (existingUsers.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }
      
      // Hash password
      const hashedPassword = await hashPassword(password);
      
      // Create user
      const userId = uuidv4();
      await executeQuery(
        'INSERT INTO users (id, email, password, name, role) VALUES (?, ?, ?, ?, ?)',
        [userId, email, hashedPassword, name, role]
      );
      
      res.status(201).json({
        success: true,
        data: {
          user: {
            id: userId,
            email,
            name,
            role
          }
        },
        message: 'User created successfully'
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({
        success: false,
        message: 'Registration failed',
        error: error.message
      });
    }
  }

  // GET /api/auth/me
  static async getCurrentUser(req, res) {
    try {
      const userId = req.user.id;
      
      const users = await executeQuery(
        'SELECT id, email, name, role, created_at FROM users WHERE id = ?',
        [userId]
      );
      
      if (users.length === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      res.json({
        success: true,
        data: {
          user: users[0]
        }
      });
    } catch (error) {
      console.error('Get current user error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to get user info',
        error: error.message
      });
    }
  }

  // PUT /api/auth/profile
  static async updateProfile(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          message: 'Validation failed',
          errors: errors.array()
        });
      }

      const userId = req.user.id;
      const { name, email, currentPassword, newPassword } = req.body;
      
      const updates = [];
      const values = [];
      
      // Update name and email
      if (name) {
        updates.push('name = ?');
        values.push(name);
      }
      
      if (email) {
        // Check if email is already taken by another user
        const existingUsers = await executeQuery(
          'SELECT id FROM users WHERE email = ? AND id != ?',
          [email, userId]
        );
        
        if (existingUsers.length > 0) {
          return res.status(409).json({
            success: false,
            message: 'Email is already taken'
          });
        }
        
        updates.push('email = ?');
        values.push(email);
      }
      
      // Update password if provided
      if (newPassword && currentPassword) {
        // Verify current password
        const users = await executeQuery(
          'SELECT password FROM users WHERE id = ?',
          [userId]
        );
        
        if (users.length === 0) {
          return res.status(404).json({
            success: false,
            message: 'User not found'
          });
        }
        
        const isValidPassword = await comparePassword(currentPassword, users[0].password);
        if (!isValidPassword) {
          return res.status(400).json({
            success: false,
            message: 'Current password is incorrect'
          });
        }
        
        const hashedNewPassword = await hashPassword(newPassword);
        updates.push('password = ?');
        values.push(hashedNewPassword);
      }
      
      if (updates.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'No valid fields to update'
        });
      }
      
      updates.push('updated_at = CURRENT_TIMESTAMP');
      values.push(userId);
      
      await executeQuery(
        `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
        values
      );
      
      // Return updated user info
      const updatedUsers = await executeQuery(
        'SELECT id, email, name, role FROM users WHERE id = ?',
        [userId]
      );
      
      res.json({
        success: true,
        data: {
          user: updatedUsers[0]
        },
        message: 'Profile updated successfully'
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update profile',
        error: error.message
      });
    }
  }

  // GET /api/auth/users (Admin only)
  static async getAllUsers(req, res) {
    try {
      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;
      
      const users = await executeQuery(
        'SELECT id, email, name, role, created_at, updated_at FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?',
        [limit, offset]
      );
      
      const [countResult] = await executeQuery('SELECT COUNT(*) as total FROM users');
      const total = countResult.total;
      
      res.json({
        success: true,
        data: users,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      });
    } catch (error) {
      console.error('Get all users error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch users',
        error: error.message
      });
    }
  }

  // PUT /api/auth/users/:id/role (Admin only)
  static async updateUserRole(req, res) {
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
      const { role } = req.body;
      
      if (!Object.values(ROLES).includes(role)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid role'
        });
      }
      
      const result = await executeQuery(
        'UPDATE users SET role = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [role, id]
      );
      
      if (result.affectedRows === 0) {
        return res.status(404).json({
          success: false,
          message: 'User not found'
        });
      }
      
      res.json({
        success: true,
        message: 'User role updated successfully'
      });
    } catch (error) {
      console.error('Update user role error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update user role',
        error: error.message
      });
    }
  }
}

module.exports = AuthController;
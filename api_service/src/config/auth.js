const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

// Generate JWT token
function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

// Verify JWT token
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
}

// Hash password
async function hashPassword(password) {
  const saltRounds = 12;
  return await bcrypt.hash(password, saltRounds);
}

// Compare password
async function comparePassword(password, hashedPassword) {
  return await bcrypt.compare(password, hashedPassword);
}

// User roles
const ROLES = {
  ADMIN: 'admin',
  EDITOR: 'editor',
  VIEWER: 'viewer'
};

// Role permissions
const PERMISSIONS = {
  [ROLES.ADMIN]: ['read', 'write', 'delete', 'manage_users'],
  [ROLES.EDITOR]: ['read', 'write', 'delete'],
  [ROLES.VIEWER]: ['read']
};

// Check if user has permission
function hasPermission(userRole, requiredPermission) {
  const userPermissions = PERMISSIONS[userRole] || [];
  return userPermissions.includes(requiredPermission);
}

module.exports = {
  generateToken,
  verifyToken,
  hashPassword,
  comparePassword,
  ROLES,
  PERMISSIONS,
  hasPermission
};
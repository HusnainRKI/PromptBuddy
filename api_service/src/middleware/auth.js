const { verifyToken, hasPermission } = require('../config/auth');

// Middleware to authenticate JWT token
function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access token required'
      });
    }
    
    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const decoded = verifyToken(token);
    
    req.user = decoded;
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token'
    });
  }
}

// Middleware to check if user has required permission
function authorize(requiredPermission) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }
    
    if (!hasPermission(req.user.role, requiredPermission)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions'
      });
    }
    
    next();
  };
}

// Middleware to check if user has specific role
function requireRole(requiredRole) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }
    
    if (req.user.role !== requiredRole) {
      return res.status(403).json({
        success: false,
        message: `${requiredRole} role required`
      });
    }
    
    next();
  };
}

// Optional authentication - sets req.user if token is provided
function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = verifyToken(token);
      req.user = decoded;
    }
    
    next();
  } catch (error) {
    // Don't fail if token is invalid in optional auth
    next();
  }
}

module.exports = {
  authenticate,
  authorize,
  requireRole,
  optionalAuth
};
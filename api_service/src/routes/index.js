const express = require('express');
const authRoutes = require('./auth');
const categoryRoutes = require('./categories');
const promptRoutes = require('./prompts');
const importExportRoutes = require('./importExport');

const router = express.Router();

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'PromptBuddy API is running',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// Version endpoint for sync compatibility
router.get('/version', (req, res) => {
  res.json({
    success: true,
    data: {
      version: '1.0.0',
      apiVersion: 'v1',
      compatibility: {
        minMobileVersion: '1.0.0',
        minCmsVersion: '1.0.0'
      }
    }
  });
});

// Mount route modules
router.use('/auth', authRoutes);
router.use('/categories', categoryRoutes);
router.use('/prompts', promptRoutes);
router.use('/', importExportRoutes); // Mount import/export at root level

// 404 handler for API routes
router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint not found',
    path: req.originalUrl
  });
});

module.exports = router;
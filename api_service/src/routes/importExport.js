const express = require('express');
const ImportExportController = require('../controllers/importExportController');
const { optionalAuth, authenticate, authorize } = require('../middleware/auth');
const { importExportValidation } = require('../middleware/validation');

const router = express.Router();

// Public export (for mobile app)
router.get('/export', optionalAuth, ImportExportController.exportData);

// Protected routes (CMS access)
router.post('/import', authenticate, authorize('write'), importExportValidation.import, ImportExportController.importData);
router.post('/export/download', authenticate, authorize('read'), ImportExportController.downloadExport);
router.post('/validate-import', authenticate, authorize('write'), ImportExportController.validateImportData);

module.exports = router;
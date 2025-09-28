# PromptBuddy - Complete Full-Stack Solution

A production-ready Flutter app, web CMS, and REST API for managing and sharing text prompts.

## Architecture

This project consists of three main components:

1. **Flutter Mobile App** (`mobile_app/`) - User-facing app for browsing, searching, creating, and sharing prompts
2. **REST API Service** (`api_service/`) - Secure backend service using Node.js, Express, and MySQL
3. **Web CMS** (`web_cms/`) - Admin panel built with React for managing categories and prompts

## Quick Start

### Prerequisites
- Flutter SDK (3.x+)
- Node.js (18+)
- MySQL (8.0+)
- Chrome/Edge for web development

### 1. Database Setup
```bash
# Create MySQL database
mysql -u root -p -e "CREATE DATABASE promptbuddy;"
```

### 2. API Service
```bash
cd api_service
npm install
cp .env.example .env
# Edit .env with your database credentials
npm run migrate
npm run seed
npm start
```

### 3. Flutter Mobile App
```bash
cd mobile_app
flutter pub get
flutter run
```

### 4. Web CMS
```bash
cd web_cms
npm install
npm start
```

## Features

### Mobile App
- ✅ Offline-first architecture with sync
- ✅ Global search with debouncing
- ✅ Category-based organization
- ✅ Variable parsing and preview
- ✅ Native sharing capabilities
- ✅ Light/dark themes
- ✅ Import/export JSON
- ✅ Accessibility support

### Web CMS
- ✅ Role-based access control
- ✅ Drag-and-drop category reordering
- ✅ Live variable detection
- ✅ Bulk operations
- ✅ Import/export with validation
- ✅ Audit trail

### API Service
- ✅ JWT authentication
- ✅ Rate limiting and security
- ✅ Full-text search
- ✅ Conflict resolution
- ✅ Comprehensive validation
- ✅ API documentation

## Project Structure
```
PromptBuddy/
├── mobile_app/           # Flutter application
├── api_service/          # Node.js REST API
├── web_cms/             # React admin panel
├── docs/                # Documentation
└── sample_data/         # Sample prompts and categories
```

## Sample Data

The system comes with three default categories:
- **Photo Editing** - Prompts for image editing and enhancement
- **Code** - Programming and development prompts
- **Social Media** - Content creation for social platforms

## Documentation

- [API Documentation](./docs/api.md)
- [Mobile App Guide](./docs/mobile_app.md)
- [CMS User Guide](./docs/web_cms.md)
- [Deployment Guide](./docs/deployment.md)

## License

MIT License - see [LICENSE](./LICENSE) for details.
# PromptBuddy API Service

A secure REST API service built with Node.js, Express, and MySQL for managing categories and prompts.

## Features

- 🔐 JWT-based authentication with role-based access control
- 📝 Full CRUD operations for categories and prompts
- 🔍 Full-text search with filtering and sorting
- 📦 Import/export functionality with JSON validation
- 🛡️ Security measures: CORS, rate limiting, input validation
- 📊 Conflict resolution with timestamp-based updates
- 🔄 Optimized for mobile app synchronization

## Quick Start

### Prerequisites
- Node.js (18+)
- MySQL (8.0+)

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Setup database:**
   ```bash
   # Create database
   mysql -u root -p -e "CREATE DATABASE promptbuddy;"
   
   # Run migrations
   npm run migrate
   
   # Seed with sample data
   npm run seed
   ```

4. **Start the server:**
   ```bash
   # Development mode
   npm run dev
   
   # Production mode
   npm start
   ```

The API will be available at `http://localhost:3001`

## API Endpoints

### Health & Info
- `GET /` - API welcome message
- `GET /api/health` - Health check
- `GET /api/version` - Version info

### Authentication
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user info
- `PUT /api/auth/profile` - Update user profile
- `POST /api/auth/register` - Register new user (admin only)
- `GET /api/auth/users` - List users (admin only)
- `PUT /api/auth/users/:id/role` - Update user role (admin only)

### Categories
- `GET /api/categories` - List categories
- `GET /api/categories/with-counts` - Categories with prompt counts
- `GET /api/categories/:id` - Get category by ID
- `POST /api/categories` - Create category (auth required)
- `PUT /api/categories/:id` - Update category (auth required)
- `DELETE /api/categories/:id` - Delete category (auth required)
- `PUT /api/categories/reorder` - Reorder categories (auth required)

### Prompts
- `GET /api/prompts` - List prompts with filtering/search
- `GET /api/prompts/recent` - Recently used prompts
- `GET /api/prompts/:id` - Get prompt by ID
- `POST /api/prompts` - Create prompt (auth required)
- `PUT /api/prompts/:id` - Update prompt (auth required)
- `DELETE /api/prompts/:id` - Delete prompt (auth required)
- `POST /api/prompts/:id/duplicate` - Duplicate prompt (auth required)
- `PUT /api/prompts/:id/usage` - Increment usage count
- `POST /api/prompts/bulk` - Bulk operations (auth required)
- `POST /api/prompts/parse-variables` - Parse variables from text

### Import/Export
- `GET /api/export` - Export data as JSON
- `POST /api/import` - Import data from JSON (auth required)
- `POST /api/export/download` - Download export file (auth required)
- `POST /api/validate-import` - Validate import data (auth required)

## Query Parameters

### Prompts Filtering
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)
- `categoryId` - Filter by category
- `search` - Full-text search
- `tags` - Include tags (comma-separated)
- `excludeTags` - Exclude tags (comma-separated)
- `updatedAfter` - ISO date for sync (get items updated after this date)
- `sortBy` - Sort field (default: updated_at)
- `sortOrder` - ASC or DESC (default: DESC)

### Example Requests

**Search prompts:**
```bash
GET /api/prompts?search=photo&tags=editing,professional&sortBy=usage_count&sortOrder=DESC
```

**Sync updates:**
```bash
GET /api/prompts?updatedAfter=2023-12-01T10:00:00Z&limit=50
```

**Export category:**
```bash
GET /api/export?prompts=true&categories=false&categoryId=category-uuid
```

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```bash
Authorization: Bearer <your-jwt-token>
```

### Default Admin Account
- **Email:** admin@promptbuddy.com
- **Password:** admin123

⚠️ **Important:** Change the default admin password in production!

## User Roles

- **Admin:** Full access including user management
- **Editor:** Create, read, update, delete categories and prompts
- **Viewer:** Read-only access

## Error Responses

All errors follow this format:
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (development only)"
}
```

## Security Features

- 🔒 JWT authentication with configurable expiration
- 🛡️ Helmet.js for security headers
- 🚦 Rate limiting (100 requests per 15 minutes by default)
- 🔍 Input validation with Joi
- 🌐 CORS protection with allowed origins
- 🔐 Password hashing with bcrypt
- 🛡️ SQL injection protection with parameterized queries

## Development

### Scripts
- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm run migrate` - Run database migrations
- `npm run seed` - Seed database with sample data
- `npm test` - Run tests
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues

### Database Schema

#### Categories
- `id` (UUID) - Primary key
- `name` (VARCHAR) - Category name
- `icon` (VARCHAR) - Icon identifier
- `color` (INT) - Color value
- `order_index` (INT) - Display order
- `created_at`, `updated_at` (TIMESTAMP)

#### Prompts
- `id` (UUID) - Primary key
- `title` (VARCHAR) - Prompt title
- `body` (TEXT) - Prompt content
- `category_id` (UUID) - Foreign key to categories
- `language` (VARCHAR) - Language code
- `usage_count` (INT) - Usage counter
- `created_at`, `updated_at` (TIMESTAMP)

#### Tags & Variables
- Normalized tables for tags and extracted variables
- Junction tables for many-to-many relationships

## Production Deployment

1. **Environment variables:**
   - Set strong `JWT_SECRET`
   - Configure database credentials
   - Update `ALLOWED_ORIGINS` for your domains
   - Set `NODE_ENV=production`

2. **Database:**
   - Run migrations: `npm run migrate`
   - Optional: Seed sample data: `npm run seed`

3. **Security:**
   - Change default admin password
   - Configure firewall rules
   - Use HTTPS in production
   - Regular security updates

## License

MIT License - see LICENSE file for details.
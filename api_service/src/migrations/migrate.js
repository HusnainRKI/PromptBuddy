const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { hashPassword, ROLES } = require('../config/auth');

async function runMigrations() {
  console.log('🚀 Starting database migrations...');
  
  try {
    // Create users table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(36) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        role ENUM('admin', 'editor', 'viewer') DEFAULT 'viewer',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_email (email),
        INDEX idx_role (role)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Users table created');

    // Create categories table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS categories (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        icon VARCHAR(100) DEFAULT 'folder',
        color INT DEFAULT 0xFF2196F3,
        order_index INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_name (name),
        INDEX idx_order (order_index)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Categories table created');

    // Create prompts table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS prompts (
        id VARCHAR(36) PRIMARY KEY,
        title VARCHAR(500) NOT NULL,
        body TEXT NOT NULL,
        category_id VARCHAR(36),
        language VARCHAR(10) DEFAULT 'en',
        usage_count INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        INDEX idx_title (title),
        INDEX idx_category (category_id),
        INDEX idx_updated (updated_at DESC),
        FULLTEXT idx_search (title, body)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Prompts table created');

    // Create tags table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS tags (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_name (name)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Tags table created');

    // Create prompt_tags junction table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS prompt_tags (
        prompt_id VARCHAR(36),
        tag_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (prompt_id, tag_id),
        FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Prompt tags junction table created');

    // Create variables table for parsed prompt variables
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS prompt_variables (
        id INT AUTO_INCREMENT PRIMARY KEY,
        prompt_id VARCHAR(36),
        variable_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE,
        INDEX idx_prompt_variable (prompt_id, variable_name)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `);
    console.log('✅ Prompt variables table created');

    // Create default admin user if not exists
    const adminId = uuidv4();
    const adminPassword = await hashPassword('admin123');
    
    try {
      await pool.execute(`
        INSERT IGNORE INTO users (id, email, password, name, role)
        VALUES (?, 'admin@promptbuddy.com', ?, 'System Administrator', ?)
      `, [adminId, adminPassword, ROLES.ADMIN]);
      console.log('✅ Default admin user created (admin@promptbuddy.com / admin123)');
    } catch (error) {
      if (!error.message.includes('Duplicate entry')) {
        console.log('ℹ️ Admin user already exists');
      }
    }

    console.log('🎉 All migrations completed successfully!');
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migrations if called directly
if (require.main === module) {
  runMigrations()
    .then(() => {
      console.log('Migration completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { runMigrations };
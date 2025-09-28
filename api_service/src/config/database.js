const mysql = require('mysql2/promise');
require('dotenv').config();

const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'promptbuddy',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  acquireTimeout: 60000,
  timeout: 60000,
  charset: 'utf8mb4'
};

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Test database connection
async function testConnection() {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
}

// Execute query with error handling
async function executeQuery(query, params = []) {
  try {
    const [results] = await pool.execute(query, params);
    return results;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
}

// Get paginated results
async function getPaginatedResults(baseQuery, countQuery, params = [], page = 1, limit = 10) {
  const offset = (page - 1) * limit;
  
  // Get total count
  const [countResult] = await pool.execute(countQuery, params);
  const total = countResult[0].total;
  
  // Get paginated data
  const paginatedQuery = `${baseQuery} LIMIT ? OFFSET ?`;
  const [results] = await pool.execute(paginatedQuery, [...params, limit, offset]);
  
  return {
    data: results,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(total),
      pages: Math.ceil(total / limit)
    }
  };
}

module.exports = {
  pool,
  testConnection,
  executeQuery,
  getPaginatedResults
};
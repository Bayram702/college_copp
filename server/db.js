const { Pool } = require('pg');
require('dotenv').config(); // Для загрузки переменных из .env
const { isProduction } = require('./config/security');

const requiredEnv = ['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
if (isProduction) {
  const missing = requiredEnv.filter((key) => !process.env[key]);
  if (missing.length) {
    throw new Error(`Missing required database environment variables: ${missing.join(', ')}`);
  }
}

// Настройка подключения
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'colleges_db',
  password: process.env.DB_PASSWORD || 'postgres',
  port: Number(process.env.DB_PORT) || 5432,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : false,
});

// Проверка подключения
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Ошибка подключения к базе данных:', err);
  } else {
    console.log('✅ Подключение к PostgreSQL успешно установлено!');
  }
});

module.exports = pool;

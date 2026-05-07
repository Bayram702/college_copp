// server/routes/settings.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { publicError } = require('../middleware/security');

const requireAdmin = [requireAuth, requireRole('admin')];

// Получить все настройки сайта (публичный endpoint)
router.get('/', async (req, res) => {
  try {
    const query = `
      SELECT id, setting_key, setting_value, setting_type, description, updated_at
      FROM site_settings
      ORDER BY setting_key
    `;

    const result = await db.query(query);

    const settings = {};
    result.rows.forEach(row => {
      settings[row.setting_key] = {
        id: row.id,
        value: row.setting_value,
        type: row.setting_type,
        description: row.description,
        updated_at: row.updated_at
      };
    });

    res.json({ success: true, data: settings });
  } catch (error) {
    console.error('Error fetching site settings:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

// Получить конкретную настройку по ключу
router.get('/:key', async (req, res) => {
  try {
    const { key } = req.params;

    const query = `
      SELECT id, setting_key, setting_value, setting_type, description, updated_at
      FROM site_settings
      WHERE setting_key = $1
    `;

    const result = await db.query(query, [key]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Настройка не найдена' });
    }

    const setting = result.rows[0];
    res.json({
      success: true,
      data: {
        key: setting.setting_key,
        value: setting.setting_value,
        type: setting.setting_type,
        description: setting.description,
        updated_at: setting.updated_at
      }
    });
  } catch (error) {
    console.error('Error fetching site setting:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

// Обновить настройку (admin)
router.put('/:key', requireAdmin, async (req, res) => {
  try {
    const { key } = req.params;
    const { value, description } = req.body;

    if (value === undefined || value === null) {
      return res.status(400).json({ success: false, error: 'Значение обязательно' });
    }

    // Проверяем, существует ли настройка
    const checkQuery = `SELECT id, setting_type FROM site_settings WHERE setting_key = $1`;
    const checkResult = await db.query(checkQuery, [key]);

    const settingValue = JSON.stringify(value);
    const settingType = typeof value === 'object' ? 'json' : 'string';

    if (checkResult.rows.length > 0) {
      // Обновляем
      const query = `
        UPDATE site_settings
        SET setting_value = $1, setting_type = $2, description = COALESCE($3, description), updated_at = CURRENT_TIMESTAMP
        WHERE setting_key = $4
        RETURNING *
      `;
      const result = await db.query(query, [settingValue, settingType, description || null, key]);
      res.json({ success: true, data: result.rows[0] });
    } else {
      // Создаём
      const query = `
        INSERT INTO site_settings (setting_key, setting_value, setting_type, description)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `;
      const result = await db.query(query, [key, settingValue, settingType, description || null]);
      res.status(201).json({ success: true, data: result.rows[0] });
    }
  } catch (error) {
    console.error('Error updating site setting:', error);
    res.status(500).json({ success: false, error: publicError });
  }
});

module.exports = router;

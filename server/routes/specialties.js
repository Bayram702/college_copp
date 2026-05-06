const express = require('express');
const router = express.Router();
const db = require('../db');

const normalizeSectors = (sectors) => {
  if (!Array.isArray(sectors)) return [];
  return sectors
    .filter(Boolean)
    .map(sec => ({ id: sec.id, name: sec.name, code: sec.code }));
};

router.get('/', async (req, res) => {
  try {
    const { sector, sector_id, search, limit, page } = req.query;
    const limitNum = Math.max(parseInt(limit, 10) || 9, 1);
    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const offset = (pageNum - 1) * limitNum;

    let query = `
      SELECT
        MIN(s.id) as id,
        s.code,
        s.name,
        MAX(s.description) as description,
        MAX(s.qualification) as qualification,
        MAX(s.duration) as duration,
        MAX(s.base_education) as base_education,
        MAX(s.form) as form,
        SUM(COALESCE(cs.budget_places, s.budget_places, 0)) as budget_places,
        SUM(COALESCE(cs.commercial_places, s.commercial_places, 0)) as commercial_places,
        MIN(NULLIF(COALESCE(cs.price_per_year, s.price_per_year, 0), 0)) as price_per_year,
        MAX(s.exams) as exams,
        ROUND(AVG(NULLIF(COALESCE(cs.avg_score, s.avg_score_last_year), 0))::numeric, 2) as avg_score_last_year,
        COUNT(DISTINCT cs.college_id) FILTER (WHERE cs.is_active = true) as colleges_count,
        COALESCE(
          json_agg(DISTINCT jsonb_build_object('id', sec.id, 'name', sec.name, 'code', sec.code))
            FILTER (WHERE sec.id IS NOT NULL),
          '[]'
        ) as sectors
      FROM specialties s
      LEFT JOIN college_specialties cs ON s.id = cs.specialty_id AND cs.is_active = true
      LEFT JOIN specialty_sectors ss ON s.id = ss.specialty_id
      LEFT JOIN sectors sec ON ss.sector_id = sec.id
      WHERE s.status = 'active'
    `;

    const params = [];
    let paramIndex = 1;

    if (sector_id) {
      query += ` AND ss.sector_id = $${paramIndex++}`;
      params.push(sector_id);
    } else if (sector && sector !== 'all') {
      query += ` AND sec.code = $${paramIndex++}`;
      params.push(sector);
    }

    if (search) {
      query += ` AND (s.name ILIKE $${paramIndex++} OR s.code ILIKE $${paramIndex++})`;
      const searchParam = `%${search}%`;
      params.push(searchParam, searchParam);
    }

    const countQuery = `
      SELECT COUNT(*) FROM (
        ${query.replace(/SELECT[\s\S]*?FROM specialties s/, 'SELECT s.code, s.name FROM specialties s')}
        GROUP BY s.code, s.name
      ) grouped_specialties
    `;
    const countResult = await db.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count, 10);

    query += ` GROUP BY s.code, s.name ORDER BY s.name LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limitNum, offset);

    const result = await db.query(query, params);

    const specialties = result.rows.map(row => ({
      id: row.id,
      code: row.code,
      name: row.name,
      description: row.description,
      qualification: row.qualification,
      duration: row.duration,
      base_education: row.base_education,
      form: row.form,
      budget_places: row.budget_places,
      commercial_places: row.commercial_places,
      price_per_year: row.price_per_year,
      exams: row.exams,
      avg_score: row.avg_score_last_year,
      colleges_count: parseInt(row.colleges_count || 0, 10),
      sectors: normalizeSectors(row.sectors)
    }));

    res.json({
      success: true,
      data: specialties,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum)
      }
    });
  } catch (error) {
    console.error('Error fetching specialties:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

router.get('/stats', async (req, res) => {
  try {
    const stats = await db.query(`
      SELECT
        COUNT(*) as total_specialties,
        COALESCE(ROUND(AVG(avg_score), 2), 0) as avg_score_last_year,
        COALESCE(SUM(budget_places), 0) as total_budget_places,
        COALESCE(SUM(commercial_places), 0) as total_commercial_places
      FROM (
        SELECT
          s.code,
          s.name,
          SUM(COALESCE(cs.budget_places, s.budget_places, 0)) as budget_places,
          SUM(COALESCE(cs.commercial_places, s.commercial_places, 0)) as commercial_places,
          AVG(NULLIF(COALESCE(cs.avg_score, s.avg_score_last_year), 0)) as avg_score
        FROM specialties s
        LEFT JOIN college_specialties cs ON s.id = cs.specialty_id AND cs.is_active = true
        WHERE s.status = 'active'
        GROUP BY s.code, s.name
      ) grouped_specialties
    `);

    res.json({ success: true, data: stats.rows[0] });
  } catch (error) {
    console.error('Error fetching specialty stats:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      WITH target AS (
        SELECT code, name
        FROM specialties
        WHERE id = $1 AND status = 'active'
      ),
      grouped AS (
        SELECT s.*
        FROM specialties s
        JOIN target t ON s.status = 'active' AND (
          (s.code IS NOT NULL AND s.code = t.code) OR
          (s.code IS NULL AND s.name = t.name)
        )
      )
      SELECT
        MIN(s.id) as id,
        MAX(s.code) as code,
        MAX(s.name) as name,
        MAX(s.description) as description,
        MAX(s.qualification) as qualification,
        MAX(s.duration) as duration,
        MAX(s.base_education) as base_education,
        MAX(s.form) as form,
        MAX(s.exams) as exams,
        ROUND(AVG(NULLIF(COALESCE(cs.avg_score, s.avg_score_last_year), 0))::numeric, 2) as avg_score_last_year,
        COALESCE(
          json_agg(DISTINCT jsonb_build_object('id', sec.id, 'name', sec.name, 'code', sec.code))
            FILTER (WHERE sec.id IS NOT NULL),
          '[]'
        ) as sectors,
        (
          SELECT json_agg(
            json_build_object(
              'id', c.id,
              'name', c.name,
              'short_name', c.short_name,
              'city_name', ci.name,
              'city_id', c.city_id,
              'budget_places', cs2.budget_places,
              'commercial_places', cs2.commercial_places,
              'price_per_year', cs2.price_per_year,
              'avg_score', cs2.avg_score,
              'is_professionalitet', c.is_professionalitet,
              'logo_image_url', c.logo_image_url,
              'phone', c.phone,
              'email', c.email,
              'website', c.website
            )
            ORDER BY c.name
          )
          FROM college_specialties cs2
          JOIN colleges c ON cs2.college_id = c.id
          LEFT JOIN cities ci ON c.city_id = ci.id
          WHERE cs2.specialty_id IN (SELECT id FROM grouped)
            AND cs2.is_active = true
            AND c.status = 'active'
        ) as colleges
      FROM grouped s
      LEFT JOIN college_specialties cs ON s.id = cs.specialty_id AND cs.is_active = true
      LEFT JOIN specialty_sectors ss ON s.id = ss.specialty_id
      LEFT JOIN sectors sec ON ss.sector_id = sec.id
    `;

    const result = await db.query(query, [id]);

    if (result.rows.length === 0 || !result.rows[0].id) {
      return res.status(404).json({ success: false, error: 'Специальность не найдена' });
    }

    const specialty = result.rows[0];
    specialty.sectors = normalizeSectors(specialty.sectors);
    specialty.colleges = specialty.colleges || [];

    res.json({ success: true, data: specialty });
  } catch (error) {
    console.error('Error fetching specialty:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

module.exports = router;

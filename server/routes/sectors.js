const express = require('express');
const router = express.Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { publicError } = require('../middleware/security');

const requireAdmin = [requireAuth, requireRole('admin')];

const normalizeSpecialtyPrefixes = (value) => {
  const raw = Array.isArray(value) ? value.join(',') : String(value || '');
  return raw
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => item.replace(/\D/g, '').slice(0, 2))
    .filter((item, index, list) => item.length === 2 && list.indexOf(item) === index);
};

const linkSpecialtiesByPrefixes = async (client, sectorId, prefixes) => {
  if (!prefixes.length) return 0;

  const result = await client.query(
    `
      INSERT INTO specialty_sectors (specialty_id, sector_id)
      SELECT sp.id, $1
      FROM specialties sp
      WHERE EXISTS (
        SELECT 1
        FROM unnest($2::text[]) AS prefix
        WHERE sp.code LIKE prefix || '.%'
      )
      ON CONFLICT (specialty_id, sector_id) DO NOTHING
      RETURNING specialty_id
    `,
    [sectorId, prefixes]
  );

  return result.rowCount;
};

router.get('/', async (req, res) => {
  try {
    const { include_inactive } = req.query;

    const params = [];
    let whereClause = '';

    if (!include_inactive) {
      params.push(true);
      whereClause = `WHERE s.is_active = $1`;
    }

    const query = `
      SELECT
        s.id,
        s.name,
        s.code,
        s.description,
        s.image_url,
        s.sort_order,
        s.is_active,
        s.created_at,
        s.updated_at,
        COUNT(DISTINCT sp.id) AS programs_count,
        COUNT(DISTINCT CASE
          WHEN cs.is_active = true AND c.status = 'active' THEN cs.college_id
          ELSE NULL
        END) AS colleges_count
      FROM sectors s
      LEFT JOIN specialty_sectors ss ON ss.sector_id = s.id
      LEFT JOIN specialties sp ON sp.id = ss.specialty_id AND sp.status = 'active'
      LEFT JOIN college_specialties cs ON cs.specialty_id = sp.id
      LEFT JOIN colleges c ON c.id = cs.college_id
      ${whereClause}
      GROUP BY s.id, s.name, s.code, s.description, s.image_url, s.sort_order, s.is_active, s.created_at, s.updated_at
      ORDER BY s.sort_order, s.name
    `;

    const result = await db.query(query, params);

    const sectors = result.rows.map((row) => ({
      id: row.id,
      name: row.name,
      code: row.code,
      description: row.description,
      image_url: row.image_url,
      colleges_count: Number(row.colleges_count) || 0,
      programs_count: Number(row.programs_count) || 0,
      sort_order: row.sort_order,
      is_active: row.is_active
    }));

    res.json({ success: true, data: sectors });
  } catch (error) {
    console.error('Error fetching sectors:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const query = `
      SELECT
        s.id,
        s.name,
        s.code,
        s.description,
        s.image_url,
        s.sort_order,
        s.is_active,
        COUNT(DISTINCT sp.id) AS programs_count,
        COUNT(DISTINCT CASE
          WHEN cs.is_active = true AND c.status = 'active' THEN cs.college_id
          ELSE NULL
        END) AS colleges_count,
        (
          SELECT COALESCE(
            json_agg(
              json_build_object(
                'id', c2.id,
                'name', c2.name,
                'short_name', c2.short_name,
                'city_name', ci.name,
                'logo_image_url', c2.logo_image_url,
                'avg_score', c2.avg_score,
                'budget_places', c2.budget_places,
                'is_professionalitet', c2.is_professionalitet
              )
              ORDER BY c2.name
            ),
            '[]'::json
          )
          FROM college_specialties cs2
          JOIN colleges c2 ON cs2.college_id = c2.id
          LEFT JOIN cities ci ON c2.city_id = ci.id
          LEFT JOIN specialty_sectors ss2 ON ss2.specialty_id = cs2.specialty_id
          WHERE ss2.sector_id = s.id
            AND c2.status = 'active'
            AND cs2.is_active = true
        ) AS colleges
      FROM sectors s
      LEFT JOIN specialty_sectors ss ON ss.sector_id = s.id
      LEFT JOIN specialties sp ON sp.id = ss.specialty_id AND sp.status = 'active'
      LEFT JOIN college_specialties cs ON cs.specialty_id = sp.id
      LEFT JOIN colleges c ON c.id = cs.college_id
      WHERE s.id = $1
      GROUP BY s.id, s.name, s.code, s.description, s.image_url, s.sort_order, s.is_active
    `;

    const result = await db.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Сектор не найден' });
    }

    const sector = result.rows[0];
    sector.colleges_count = Number(sector.colleges_count) || 0;
    sector.programs_count = Number(sector.programs_count) || 0;
    sector.colleges = sector.colleges || [];

    res.json({ success: true, data: sector });
  } catch (error) {
    console.error('Error fetching sector:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

router.post('/', requireAdmin, async (req, res) => {
  const client = await db.connect();
  try {
    const { name, description, image_url } = req.body;
    const specialtyPrefixes = normalizeSpecialtyPrefixes(req.body.specialtyCodes ?? req.body.code);
    const code = specialtyPrefixes.join(',');

    if (!name || specialtyPrefixes.length === 0) {
      return res.status(400).json({ success: false, error: 'Название и коды специальностей обязательны' });
    }

    await client.query('BEGIN');
    const sortResult = await client.query(`SELECT COALESCE(MAX(sort_order), 0) + 1 AS next_order FROM sectors`);
    const sortOrder = Number(sortResult.rows[0]?.next_order) || 1;

    const result = await client.query(
      `
        INSERT INTO sectors (name, code, description, image_url, sort_order)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
      `,
      [name, code, description || '', image_url || null, sortOrder]
    );

    const linkedCount = await linkSpecialtiesByPrefixes(client, result.rows[0].id, specialtyPrefixes);
    await client.query('COMMIT');

    res.status(201).json({ success: true, data: { ...result.rows[0], linked_specialties_count: linkedCount } });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating sector:', error);
    res.status(500).json({ success: false, error: publicError });
  } finally {
    client.release();
  }
});

router.put('/:id', requireAdmin, async (req, res) => {
  const client = await db.connect();
  try {
    const { id } = req.params;
    const { name, description, image_url, sort_order, is_active } = req.body;
    const specialtyPrefixes = req.body.specialtyCodes !== undefined || req.body.code !== undefined
      ? normalizeSpecialtyPrefixes(req.body.specialtyCodes ?? req.body.code)
      : null;
    const code = specialtyPrefixes ? specialtyPrefixes.join(',') : null;

    const updates = [];
    const params = [];
    let paramIndex = 1;

    if (name) { updates.push(`name = $${paramIndex++}`); params.push(name); }
    if (code) { updates.push(`code = $${paramIndex++}`); params.push(code); }
    if (description !== undefined) { updates.push(`description = $${paramIndex++}`); params.push(description); }
    if (image_url !== undefined) { updates.push(`image_url = $${paramIndex++}`); params.push(image_url); }
    if (sort_order !== undefined) { updates.push(`sort_order = $${paramIndex++}`); params.push(sort_order); }
    if (is_active !== undefined) { updates.push(`is_active = $${paramIndex++}`); params.push(is_active); }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    params.push(id);

    if (updates.length === 1) {
      return res.status(400).json({ success: false, error: 'Нет данных для обновления' });
    }

    await client.query('BEGIN');

    const query = `UPDATE sectors SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`;
    const result = await client.query(query, params);

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Сектор не найден' });
    }

    let linkedCount = 0;
    if (specialtyPrefixes) {
      await client.query('DELETE FROM specialty_sectors WHERE sector_id = $1', [id]);
      linkedCount = await linkSpecialtiesByPrefixes(client, id, specialtyPrefixes);
    }

    await client.query('COMMIT');

    res.json({ success: true, data: { ...result.rows[0], linked_specialties_count: linkedCount } });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating sector:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  } finally {
    client.release();
  }
});

router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      `DELETE FROM sectors WHERE id = $1 RETURNING id, name`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Сектор не найден' });
    }

    res.json({ success: true, message: 'Сектор удалён', data: result.rows[0] });
  } catch (error) {
    console.error('Error deleting sector:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

module.exports = router;

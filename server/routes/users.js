// server/routes/users.js
const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { sendPasswordChangedEmail } = require('../mail');
const { validateRepresentativePayload, validationResponse } = require('../validation');
const { requireAuth, requireRole } = require('../middleware/auth');
const { publicError } = require('../middleware/security');
const ALLOWED_ROLES = ['admin', 'college_rep'];
const ALLOWED_STATUSES = ['active', 'inactive'];

const requireAdmin = [requireAuth, requireRole('admin')];

// Получить всех пользователей (кроме админов, если нужно)
router.get('/', requireAdmin, async (req, res) => {
  try {
    const { excludeAdmin, search, role, status, page = 1, limit = 10 } = req.query;

    const conditions = [];
    const params = [];
    let paramIndex = 1;

    // Исключить админов по запросу
    if (excludeAdmin === 'true') {
      conditions.push(`r.name != 'admin'`);
    }

    // Поиск
    if (search) {
      conditions.push(`(u.name ILIKE $${paramIndex} OR u.login ILIKE $${paramIndex} OR u.email ILIKE $${paramIndex})`);
      params.push(`%${search}%`);
      paramIndex++;
    }

    // Фильтр по роли
    if (role && role !== 'all') {
      if (!ALLOWED_ROLES.includes(role)) {
        return res.status(400).json({ success: false, error: 'Недоступная роль' });
      }
      conditions.push(`r.name = $${paramIndex}`);
      params.push(role);
      paramIndex++;
    } else {
      conditions.push(`r.name = ANY($${paramIndex})`);
      params.push(ALLOWED_ROLES);
      paramIndex++;
    }

    // Фильтр по статусу
    if (status && status !== 'all') {
      if (!ALLOWED_STATUSES.includes(status)) {
        return res.status(400).json({ success: false, error: 'Недоступный статус' });
      }
      conditions.push(`u.status = $${paramIndex}`);
      params.push(status);
      paramIndex++;
    }

    const whereClause = conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : '';

    // Получение общего количества
    const countQuery = `
      SELECT COUNT(*)
      FROM users u
      JOIN roles r ON u.role_id = r.id
      ${whereClause}
    `;

    const countResult = await db.query(countQuery, params);
    const total = parseInt(countResult.rows[0].count);

    // Пагинация
    const requestedLimit = parseInt(limit, 10) || 10;
    const limitNum = Math.min(Math.max(requestedLimit, 1), 50);
    const pageNum = Math.max(parseInt(page, 10) || 1, 1);
    const offset = (pageNum - 1) * limitNum;

    // Основной запрос
    const dataQuery = `
      SELECT
        u.id, u.login, u.email, u.name, u.phone, u.status, u.created_at, u.last_login_at,
        r.name as role_name, r.description as role_description,
        c.name as college_name, c.id as college_id
      FROM users u
      JOIN roles r ON u.role_id = r.id
      LEFT JOIN colleges c ON u.college_id = c.id
      ${whereClause}
      ORDER BY u.created_at DESC
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;

    const queryParams = [...params, limitNum, offset];

    const result = await db.query(dataQuery, queryParams);

    const users = result.rows.map(row => ({
      id: row.id,
      login: row.login,
      email: row.email,
      name: row.name,
      phone: row.phone,
      status: row.status,
      role: {
        name: row.role_name,
        description: row.role_description
      },
      college: row.college_id ? {
        id: row.college_id,
        name: row.college_name
      } : null,
      createdAt: row.created_at,
      lastLoginAt: row.last_login_at
    }));

    res.json({
      success: true,
      data: users,
      pagination: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum)
      }
    });

  } catch (error) {
    console.error('❌ Error fetching users:', error);
    res.status(500).json({ success: false, error: publicError });
  }
});

// Создать пользователя
router.post('/', requireAdmin, async (req, res) => {
  try {
    const { data, errors } = validateRepresentativePayload(req.body, { create: true })
    if (Object.keys(errors).length) return validationResponse(res, errors)
    const { name, login, email, phone, password, role, status, college_id } = data
    if (role && !ALLOWED_ROLES.includes(role)) {
      return res.status(400).json({ success: false, error: 'Можно создавать только администратора или представителя колледжа' })
    }

    if (!name || !login || !email || !password || !role) {
      return res.status(400).json({ success: false, error: 'Заполните все обязательные поля' })
    }

    // Проверка уникальности
    const checkRes = await db.query('SELECT id FROM users WHERE login = $1 OR email = $2', [login, email])
    if (checkRes.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Пользователь с таким логином или email уже существует' })
    }

    // Получаем роль
    const roleRes = await db.query('SELECT id FROM roles WHERE name = $1', [role])
    if (roleRes.rows.length === 0) return res.status(400).json({ success: false, error: 'Неверная роль' })

    if (college_id) {
      const existingRep = await db.query(
        'SELECT id FROM users WHERE college_id = $1 AND role_id = $2',
        [college_id, roleRes.rows[0].id]
      )
      if (existingRep.rows.length > 0) {
        return res.status(400).json({ success: false, error: 'У этого колледжа уже есть представитель' })
      }
    }

    const passwordHash = await bcrypt.hash(password, 10)
    const result = await db.query(
      `INSERT INTO users (login, email, password_hash, name, phone, role_id, college_id, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id, login, email, name, phone, status`,
      [login, email, passwordHash, name, phone || null, roleRes.rows[0].id, college_id, status]
    )

    const newUser = result.rows[0]

    let emailResult = { success: false, reason: 'Email не отправлен' }
    try {
      const { sendCredentialsEmail } = require('../mail')
      emailResult = await sendCredentialsEmail(email, name, login, password)
    } catch (mailError) {
      console.error('Error sending credentials email:', mailError)
      emailResult = { success: false, error: mailError.message }
    }

    res.status(201).json({
      success: true,
      message: 'Пользователь создан',
      data: newUser,
      email_sent: emailResult.success,
      email_error: emailResult.success ? null : (emailResult.error || emailResult.reason || 'Email не отправлен'),
      credentials: emailResult.success ? null : { login, password }
    })
  } catch (e) {
    console.error('Error creating user:', e)
    res.status(500).json({ success: false, error: publicError })
  }
})

// Создать пользователя (представителя колледжа)
router.post('/college-rep', requireAdmin, async (req, res) => {
  try {
    const { 
      collegeName, 
      collegeCity, 
      collegeDescription,
      repLogin, 
      repEmail, 
      repPassword, 
      repName 
    } = req.body;
    
    // Валидация
    if (!collegeName || !repLogin || !repEmail || !repPassword || !repName) {
      return res.status(400).json({ success: false, error: 'Все обязательные поля должны быть заполнены' });
    }
    
    // Проверка уникальности логина и email
    const checkQuery = `SELECT id FROM users WHERE login = $1 OR email = $2`;
    const checkResult = await db.query(checkQuery, [repLogin, repEmail]);
    
    if (checkResult.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Пользователь с таким логином или email уже существует' });
    }
    
    // Хеширование пароля
    const passwordHash = await bcrypt.hash(repPassword, 10);
    
    // Получаем ID роли представителя колледжа
    const roleQuery = `SELECT id FROM roles WHERE name = 'college_rep'`;
    const roleResult = await db.query(roleQuery);
    const collegeRepRoleId = roleResult.rows[0].id;
    
    // Начинаем транзакцию
    const client = await db.connect();
    
    try {
      await client.query('BEGIN');
      
      // 1. Создаём колледж
      const collegeInsert = `
        INSERT INTO colleges (
          name, city_id, description, status, 
          created_by, updated_by
        ) VALUES ($1, $2, $3, 'active', $4, $4)
        RETURNING id
      `;
      
      // Получаем city_id по названию города или создаём новый
      let cityId = null;
      if (collegeCity) {
        const cityQuery = `SELECT id FROM cities WHERE name ILIKE $1 LIMIT 1`;
        const cityResult = await client.query(cityQuery, [collegeCity]);
        
        if (cityResult.rows.length > 0) {
          cityId = cityResult.rows[0].id;
        } else {
          const cityInsert = `INSERT INTO cities (name, region) VALUES ($1, 'Республика Башкортостан') RETURNING id`;
          const newCity = await client.query(cityInsert, [collegeCity]);
          cityId = newCity.rows[0].id;
        }
      }
      
      const collegeResult = await client.query(collegeInsert, [
        collegeName, cityId, collegeDescription || '', 1 // 1 = ID админа по умолчанию
      ]);
      const collegeId = collegeResult.rows[0].id;
      
      // 2. Создаём пользователя-представителя
      const userInsert = `
        INSERT INTO users (
          login, email, password_hash, name, 
          role_id, college_id, status, created_by
        ) VALUES ($1, $2, $3, $4, $5, $6, 'active', $7)
        RETURNING id, login, email, name
      `;
      
      const userResult = await client.query(userInsert, [
        repLogin, repEmail, passwordHash, repName, 
        collegeRepRoleId, collegeId, 1
      ]);
      
      await client.query('COMMIT');
      
      const newUser = userResult.rows[0];
      
      // Логируем действие в аудит
      await client.query(`
        INSERT INTO audit_logs (entity_type, entity_id, entity_name, user_id, action, changes, ip_address)
        VALUES ('college', $1, $2, $3, 'create', $4, $5)
      `, [collegeId, collegeName, 1, JSON.stringify({ collegeName, collegeCity }), req.ip]);
      
      res.status(201).json({
        success: true,
        message: 'Колледж и представитель успешно созданы',
        data: {
          college: { id: collegeId, name: collegeName },
          user: { id: newUser.id, login: newUser.login, email: newUser.email, name: newUser.name }
        }
      });
      
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
    
  } catch (error) {
    console.error('Error creating college rep:', error);
    res.status(500).json({ success: false, error: publicError });
  }
});

// Обновить пользователя (статус, роль, привязка к колледжу)
router.put('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { data, errors } = validateRepresentativePayload(req.body, { create: false })
    if (Object.keys(errors).length) return validationResponse(res, errors)
    const { name, login, email, phone, password, status, role, college_id } = data;
    
    const updates = [];
    const params = [];
    let paramIndex = 1;

    const duplicate = await db.query('SELECT id FROM users WHERE (login = $1 OR email = $2) AND id != $3', [login, email, id])
    if (duplicate.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Пользователь с таким логином или email уже существует' })
    }
    
    updates.push(`name = $${paramIndex++}`); params.push(name);
    updates.push(`login = $${paramIndex++}`); params.push(login);
    updates.push(`email = $${paramIndex++}`); params.push(email);
    updates.push(`phone = $${paramIndex++}`); params.push(phone || null);
    updates.push(`status = $${paramIndex++}`); params.push(status);
    
    if (role) {
      if (!ALLOWED_ROLES.includes(role)) {
        return res.status(400).json({ success: false, error: 'Можно назначать только администратора или представителя колледжа' });
      }
      const roleQuery = `SELECT id FROM roles WHERE name = $1`;
      const roleResult = await db.query(roleQuery, [role]);
      if (roleResult.rows.length > 0) {
        updates.push(`role_id = $${paramIndex++}`);
        params.push(roleResult.rows[0].id);
      }
    }
    
    if (password) {
      const passwordHash = await bcrypt.hash(password, 10);
      updates.push(`password_hash = $${paramIndex++}`);
      params.push(passwordHash);
    }

    const collegeRepRole = await db.query(`SELECT id FROM roles WHERE name = 'college_rep'`)
    if (college_id && collegeRepRole.rows.length > 0) {
      const existingRep = await db.query(
        'SELECT id FROM users WHERE college_id = $1 AND role_id = $2 AND id != $3',
        [college_id, collegeRepRole.rows[0].id, id]
      )
      if (existingRep.rows.length > 0) {
        return res.status(400).json({ success: false, error: 'У этого колледжа уже есть представитель' })
      }
    }

    updates.push(`college_id = $${paramIndex++}`);
    params.push(college_id);
    
    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    
    if (updates.length === 1) {
      return res.status(400).json({ success: false, error: 'Нет данных для обновления' });
    }
    
    params.push(id);
    
    const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, login, email, name, phone, status`;
    const result = await db.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Пользователь не найден' });
    }
    
    try {
      await db.query(`
        INSERT INTO audit_logs (entity_type, entity_id, entity_name, user_id, action, changes, ip_address)
        VALUES ('user', $1, $2, $3, 'update', $4, $5)
      `, [id, result.rows[0].name, req.user?.id || 1, JSON.stringify({ status, role, college_id }), req.ip]);
    } catch (auditError) {
      console.error('Error writing user audit log:', auditError)
    }
    
    let passwordEmailResult = null;
    if (password) {
      try {
        passwordEmailResult = await sendPasswordChangedEmail(email, name, login, password);
      } catch (mailError) {
        console.error('Error sending changed password email:', mailError);
        passwordEmailResult = { success: false, error: mailError.message };
      }
    }

    res.json({
      success: true,
      data: result.rows[0],
      password_email_sent: password ? !!passwordEmailResult?.success : undefined,
      password_email_error: password && !passwordEmailResult?.success
        ? (passwordEmailResult?.error || passwordEmailResult?.reason || 'Email не отправлен')
        : null
    });
    
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

// Удалить пользователя (мягкое удаление через статус)
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверка, не удаляет ли админ сам себя
    if (req.user?.userId === parseInt(id)) {
      return res.status(400).json({ success: false, error: 'Нельзя удалить самого себя' });
    }
    
    // Меняем статус на 'inactive' вместо физического удаления
    const result = await db.query(
      `UPDATE users SET status = 'inactive', updated_at = CURRENT_TIMESTAMP WHERE id = $1 AND status != 'deleted' RETURNING id, login, name`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Пользователь не найден' });
    }
    
    // Аудит
    await db.query(`
      INSERT INTO audit_logs (entity_type, entity_id, entity_name, user_id, action, ip_address)
      VALUES ('user', $1, $2, $3, 'delete', $4)
    `, [id, result.rows[0].name, req.user?.id || 1, req.ip]);
    
    res.json({ success: true, message: 'Пользователь деактивирован', data: result.rows[0] });
    
  } catch (error) {
    console.error('Error deactivating user:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

// Получить статистику пользователей
router.get('/stats', requireAdmin, async (req, res) => {
  try {
    const stats = await db.query(`
      SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'active' THEN 1 END) as active,
        COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive,
        COUNT(CASE WHEN r.name = 'college_rep' THEN 1 END) as college_reps
      FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE r.name != 'admin'
    `);
    
    res.json({ success: true, data: stats.rows[0] });
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ success: false, error: 'Ошибка сервера' });
  }
});

module.exports = router;

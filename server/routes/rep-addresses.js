// server/routes/rep-addresses.js — CRUD адресов для представителя
const express = require('express')
const router = express.Router()
const db = require('../db')
const { requireAuth, requireRole } = require('../middleware/auth')
const { publicError } = require('../middleware/security')

const requireCollegeRep = [requireAuth, requireRole('college_rep', 'admin')]

// Получить адреса колледжа представителя
router.get('/', requireCollegeRep, async (req, res) => {
  try {
    const result = await db.query(
      `SELECT * FROM college_addresses WHERE college_id = $1 ORDER BY is_main DESC, sort_order`,
      [req.user.collegeId]
    )
    res.json({ success: true, data: result.rows })
  } catch (e) {
    console.error('Error:', e)
    res.status(500).json({ success: false, error: publicError })
  }
})

// Создать адрес
router.post('/', requireCollegeRep, async (req, res) => {
  try {
    const { name, address, phone, email, coordinates, is_main, address_type, working_hours, contact_person } = req.body
    const result = await db.query(
      `INSERT INTO college_addresses (college_id, name, address, phone, email, coordinates, is_main, address_type, working_hours, contact_person)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [req.user.collegeId, name, address, phone, email, coordinates, is_main || false, address_type || 'educational', working_hours, contact_person]
    )
    res.json({ success: true, message: 'Адрес создан', data: result.rows[0] })
  } catch (e) {
    console.error('Error:', e)
    res.status(500).json({ success: false, error: publicError })
  }
})

// Обновить адрес
router.put('/:id', requireCollegeRep, async (req, res) => {
  try {
    const { id } = req.params
    const { name, address, phone, email, coordinates, is_main, address_type, working_hours, contact_person } = req.body
    const result = await db.query(
      `UPDATE college_addresses SET name=$1, address=$2, phone=$3, email=$4, coordinates=$5, is_main=$6,
       address_type=$7, working_hours=$8, contact_person=$9
       WHERE id=$10 AND college_id=$11 RETURNING *`,
      [name, address, phone, email, coordinates, is_main, address_type, working_hours, contact_person, id, req.user.collegeId]
    )
    if (result.rows.length === 0) return res.status(404).json({ success: false, error: 'Адрес не найден' })
    res.json({ success: true, message: 'Адрес обновлён', data: result.rows[0] })
  } catch (e) {
    console.error('Error:', e)
    res.status(500).json({ success: false, error: publicError })
  }
})

// Удалить адрес
router.delete('/:id', requireCollegeRep, async (req, res) => {
  try {
    const { id } = req.params
    await db.query(`DELETE FROM college_addresses WHERE id=$1 AND college_id=$2`, [id, req.user.collegeId])
    res.json({ success: true, message: 'Адрес удалён' })
  } catch (e) {
    console.error('Error:', e)
    res.status(500).json({ success: false, error: publicError })
  }
})

module.exports = router

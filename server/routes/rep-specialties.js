const express = require('express')
const router = express.Router()
const db = require('../db')
const { validateSpecialtyPayload, validationResponse } = require('../validation')
const { requireAuth, requireRole, requireCollegeBinding } = require('../middleware/auth')
const { publicError } = require('../middleware/security')

const requireCollegeRep = [requireAuth, requireRole('college_rep'), requireCollegeBinding]

const specialtySelect = `
  SELECT
    s.id,
    s.code,
    s.name,
    s.description,
    s.qualification,
    s.duration,
    s.base_education,
    s.form,
    s.exams,
    s.status,
    cs.budget_places,
    cs.commercial_places,
    cs.price_per_year,
    cs.avg_score,
    cs.teaching_address,
    cs.admission_method,
    cs.admission_link,
    cs.admission_instructions,
    (
      SELECT json_agg(
        json_build_object('id', sec.id, 'name', sec.name, 'code', sec.code)
        ORDER BY sec.sort_order, sec.name
      ) FILTER (WHERE sec.id IS NOT NULL)
      FROM specialty_sectors ss
      JOIN sectors sec ON sec.id = ss.sector_id
      WHERE ss.specialty_id = s.id
    ) AS sectors
`

router.get('/', requireCollegeRep, async (req, res) => {
  try {
    const query = `
      ${specialtySelect}
      FROM college_specialties cs
      JOIN specialties s ON cs.specialty_id = s.id
      WHERE cs.college_id = $1 AND cs.is_active = true
      ORDER BY s.sort_order, s.name
    `
    const result = await db.query(query, [req.user.collegeId])
    res.json({ success: true, data: result.rows })
  } catch (error) {
    console.error('Error fetching representative specialties:', error)
    res.status(500).json({ success: false, error: publicError })
  }
})

router.post('/', requireCollegeRep, async (req, res) => {
  try {
    const { data, errors } = validateSpecialtyPayload(req.body)
    if (Object.keys(errors).length) return validationResponse(res, errors)
    if (!data.specialty_id || !data.sector_id) {
      return validationResponse(res, {
        specialty_id: 'Выберите специальность из справочника',
        sector_id: 'Выберите отрасль'
      })
    }

    const directoryEntry = await db.query(
      `
        SELECT
          s.id,
          s.code,
          s.name,
          s.description,
          s.qualification,
          s.duration,
          s.base_education,
          s.form,
          s.exams,
          s.status
        FROM specialties s
        JOIN specialty_sectors ss ON ss.specialty_id = s.id
        WHERE s.id = $1 AND ss.sector_id = $2 AND s.status = 'active'
        LIMIT 1
      `,
      [data.specialty_id, data.sector_id]
    )

    if (directoryEntry.rows.length === 0) {
      return res.status(400).json({ success: false, error: 'Специальность не найдена в выбранной отрасли' })
    }

    const duplicate = await db.query(
      `SELECT 1 FROM college_specialties WHERE college_id = $1 AND specialty_id = $2 AND is_active = true`,
      [req.user.collegeId, data.specialty_id]
    )
    if (duplicate.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Такая специальность уже добавлена в колледж' })
    }

    await db.query(
      `
        INSERT INTO college_specialties (
          college_id,
          specialty_id,
          budget_places,
          commercial_places,
          price_per_year,
          avg_score,
          teaching_address,
          admission_method,
          admission_link,
          admission_instructions,
          is_active
        )
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,true)
      `,
      [
        req.user.collegeId,
        data.specialty_id,
        data.budget_places || 0,
        data.commercial_places || 0,
        data.price_per_year || 0,
        data.avg_score || null,
        data.teaching_address,
        data.admission_method || null,
        data.admission_link || null,
        data.admission_instructions || null
      ]
    )

    res.json({ success: true, message: 'Специальность добавлена', data: { id: data.specialty_id } })
  } catch (error) {
    console.error('Error creating representative specialty:', error)
    res.status(500).json({ success: false, error: publicError })
  }
})

router.put('/:id', requireCollegeRep, async (req, res) => {
  try {
    const { id } = req.params
    const { data, errors } = validateSpecialtyPayload(req.body)
    if (Object.keys(errors).length) return validationResponse(res, errors)

    const ownership = await db.query(
      `SELECT specialty_id FROM college_specialties WHERE specialty_id = $1 AND college_id = $2 AND is_active = true`,
      [id, req.user.collegeId]
    )
    if (ownership.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Специальность не найдена у этого колледжа' })
    }

    await db.query(
      `
        UPDATE college_specialties
        SET
          budget_places = $1,
          commercial_places = $2,
          price_per_year = $3,
          avg_score = $4,
          teaching_address = $5,
          admission_method = $6,
          admission_link = $7,
          admission_instructions = $8
        WHERE specialty_id = $9 AND college_id = $10
      `,
      [
        data.budget_places || 0,
        data.commercial_places || 0,
        data.price_per_year || 0,
        data.avg_score || null,
        data.teaching_address,
        data.admission_method || null,
        data.admission_link || null,
        data.admission_instructions || null,
        id,
        req.user.collegeId
      ]
    )

    res.json({ success: true, message: 'Специальность обновлена' })
  } catch (error) {
    console.error('Error updating representative specialty:', error)
    res.status(500).json({ success: false, error: publicError })
  }
})

router.delete('/:id', requireCollegeRep, async (req, res) => {
  try {
    const { id } = req.params
    await db.query(
      `UPDATE college_specialties SET is_active = false WHERE specialty_id = $1 AND college_id = $2`,
      [id, req.user.collegeId]
    )
    res.json({ success: true, message: 'Специальность удалена' })
  } catch (error) {
    console.error('Error deleting representative specialty:', error)
    res.status(500).json({ success: false, error: publicError })
  }
})

module.exports = router

const bcrypt = require('bcryptjs')
const db = require('./db')
const { sectorDirectory, specialtyDirectory } = require('./catalog/specialtyDirectory')
const { isProduction } = require('./config/security')

let directoryReadyPromise = null

async function ensureAdminUser(client) {
  if (isProduction) return

  const existingRole = await client.query(`SELECT id FROM roles WHERE name = 'admin' LIMIT 1`)
  let roleId = existingRole.rows[0]?.id
  if (!roleId) {
    const roleResult = await client.query(
      `INSERT INTO roles (name, description) VALUES ('admin', 'Администратор портала') RETURNING id`
    )
    roleId = roleResult.rows[0].id
  }
  const passwordHash = await bcrypt.hash(process.env.ADMIN_PASSWORD || 'admin123', 10)
  const existingAdmin = await client.query(`SELECT id FROM users WHERE login = 'admin' LIMIT 1`)
  if (existingAdmin.rows.length) {
    await client.query(
      `UPDATE users SET password_hash = $1, role_id = $2, status = 'active' WHERE id = $3`,
      [passwordHash, roleId, existingAdmin.rows[0].id]
    )
  } else {
    await client.query(
      `INSERT INTO users (login, email, password_hash, name, role_id, status)
       VALUES ('admin', 'admin@college-rb.local', $1, 'Администратор', $2, 'active')`,
      [passwordHash, roleId]
    )
  }
}

async function ensureDirectoryData() {
  if (!directoryReadyPromise) {
    directoryReadyPromise = (async () => {
      const client = await db.connect()
      try {
        await client.query('BEGIN')
        await ensureAdminUser(client)

        const sectorIds = new Map()
        const sectorCodes = sectorDirectory.map((sector) => sector.code)
        const specialtyCodes = specialtyDirectory.map((specialty) => specialty.code)

        await client.query('DELETE FROM specialty_sectors')
        await client.query('DELETE FROM sectors WHERE NOT (code = ANY($1::text[]))', [sectorCodes])
        await client.query(
          `UPDATE specialties SET status = 'inactive' WHERE NOT (code = ANY($1::text[]))`,
          [specialtyCodes]
        )

        for (const sector of sectorDirectory) {
          const existingSector = await client.query(`SELECT id FROM sectors WHERE code = $1 ORDER BY id LIMIT 1`, [sector.code])
          let sectorResult
          if (existingSector.rows.length) {
            sectorResult = await client.query(
              `UPDATE sectors SET name = $1, description = $2, sort_order = $3, is_active = true, image_url = NULL WHERE id = $4 RETURNING id`,
              [sector.name, sector.description, sector.sort_order, existingSector.rows[0].id]
            )
          } else {
            sectorResult = await client.query(
              `INSERT INTO sectors (name, code, description, sort_order, is_active) VALUES ($1, $2, $3, $4, true) RETURNING id`,
              [sector.name, sector.code, sector.description, sector.sort_order]
            )
          }
          sectorIds.set(sector.code, sectorResult.rows[0].id)
        }

        const specialtyIds = new Map()
        for (const specialty of specialtyDirectory) {
          const existingSpecialty = await client.query(`SELECT id FROM specialties WHERE code = $1 ORDER BY id LIMIT 1`, [specialty.code])
          let specialtyResult
          if (existingSpecialty.rows.length) {
            specialtyResult = await client.query(
              `UPDATE specialties SET name = $1, qualification = $2, status = 'active' WHERE id = $3 RETURNING id`,
              [specialty.name, specialty.qualification, existingSpecialty.rows[0].id]
            )
          } else {
            specialtyResult = await client.query(
              `
                INSERT INTO specialties (
                  code, name, description, qualification, duration, base_education, form,
                  budget_places, commercial_places, price_per_year, avg_score_last_year,
                  is_professionalitet, sort_order, status
                )
                VALUES ($1,$2,'',$3,'','9','full-time',0,0,0,0,false,0,'active')
                RETURNING id
              `,
              [specialty.code, specialty.name, specialty.qualification]
            )
          }
          specialtyIds.set(specialty.code, specialtyResult.rows[0].id)
        }

        for (const specialty of specialtyDirectory) {
          const specialtyId = specialtyIds.get(specialty.code)
          const sectorId = sectorIds.get(specialty.sector_code)
          if (!specialtyId || !sectorId) continue

          await client.query(
            `
              INSERT INTO specialty_sectors (specialty_id, sector_id)
              VALUES ($1, $2)
              ON CONFLICT DO NOTHING
            `,
            [specialtyId, sectorId]
          )
        }

        await client.query('COMMIT')
      } catch (error) {
        await client.query('ROLLBACK')
        throw error
      } finally {
        client.release()
      }
    })()
  }

  return directoryReadyPromise
}

module.exports = {
  ensureDirectoryData
}

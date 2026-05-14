const db = require('./db')

let schemaReadyPromise = null

const statements = [
  `ALTER TABLE colleges
    ADD COLUMN IF NOT EXISTS admission_method VARCHAR(50),
    ADD COLUMN IF NOT EXISTS admission_link VARCHAR(500),
    ADD COLUMN IF NOT EXISTS admission_instructions TEXT`,
  `ALTER TABLE college_specialties
    ADD COLUMN IF NOT EXISTS teaching_address VARCHAR(500),
    ADD COLUMN IF NOT EXISTS admission_method VARCHAR(50),
    ADD COLUMN IF NOT EXISTS admission_link VARCHAR(500),
    ADD COLUMN IF NOT EXISTS admission_instructions TEXT`,
  `DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'specialty_sectors_specialty_sector_key'
      ) THEN
        ALTER TABLE specialty_sectors
          ADD CONSTRAINT specialty_sectors_specialty_sector_key UNIQUE (specialty_id, sector_id);
      END IF;
    END
  $$`,
  `CREATE INDEX IF NOT EXISTS idx_specialties_status_code ON specialties (status, code)`,
  `CREATE INDEX IF NOT EXISTS idx_specialty_sectors_sector_id ON specialty_sectors (sector_id)`,
  `CREATE INDEX IF NOT EXISTS idx_college_specialties_college_id_active ON college_specialties (college_id, is_active)`,
  `CREATE INDEX IF NOT EXISTS idx_college_specialties_specialty_id_active ON college_specialties (specialty_id, is_active)`
]

async function ensureSchema() {
  if (!schemaReadyPromise) {
    schemaReadyPromise = (async () => {
      for (const statement of statements) {
        try {
          await db.query(statement)
        } catch (error) {
          throw error
        }
      }
    })()
  }

  return schemaReadyPromise
}

module.exports = {
  ensureSchema
}

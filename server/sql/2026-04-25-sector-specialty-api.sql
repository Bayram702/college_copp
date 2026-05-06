BEGIN;

CREATE TABLE IF NOT EXISTS specialty_sectors (
  specialty_id integer NOT NULL REFERENCES specialties(id) ON DELETE CASCADE,
  sector_id integer NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
  PRIMARY KEY (specialty_id, sector_id)
);

CREATE INDEX IF NOT EXISTS idx_specialty_sectors_specialty_id
  ON specialty_sectors (specialty_id);

CREATE INDEX IF NOT EXISTS idx_specialty_sectors_sector_id
  ON specialty_sectors (sector_id);

CREATE INDEX IF NOT EXISTS idx_college_specialties_specialty_id
  ON college_specialties (specialty_id);

CREATE INDEX IF NOT EXISTS idx_college_specialties_college_id
  ON college_specialties (college_id);

COMMIT;

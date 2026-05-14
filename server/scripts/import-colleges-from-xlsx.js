const fs = require('node:fs')
const path = require('node:path')
const zlib = require('node:zlib')

const DEFAULT_XLSX_PATH = 'C:/Users/pl/Desktop/колледжи.xlsx'
const EXPECTED_COLLEGE_COUNT = 99
let db

function getDb() {
  if (!db) db = require('../db')
  return db
}

function decodeXml(value) {
  return String(value || '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, '&')
}

function readZipEntries(buffer) {
  let eocdOffset = -1
  for (let offset = buffer.length - 22; offset >= 0; offset -= 1) {
    if (buffer.readUInt32LE(offset) === 0x06054b50) {
      eocdOffset = offset
      break
    }
  }

  if (eocdOffset === -1) {
    throw new Error('Invalid XLSX file: ZIP directory not found')
  }

  const entryCount = buffer.readUInt16LE(eocdOffset + 10)
  const centralDirectoryOffset = buffer.readUInt32LE(eocdOffset + 16)
  const entries = new Map()
  let offset = centralDirectoryOffset

  for (let index = 0; index < entryCount; index += 1) {
    if (buffer.readUInt32LE(offset) !== 0x02014b50) {
      throw new Error('Invalid XLSX file: ZIP entry header not found')
    }

    const compressionMethod = buffer.readUInt16LE(offset + 10)
    const compressedSize = buffer.readUInt32LE(offset + 20)
    const fileNameLength = buffer.readUInt16LE(offset + 28)
    const extraLength = buffer.readUInt16LE(offset + 30)
    const commentLength = buffer.readUInt16LE(offset + 32)
    const localHeaderOffset = buffer.readUInt32LE(offset + 42)
    const name = buffer.subarray(offset + 46, offset + 46 + fileNameLength).toString('utf8')

    const localFileNameLength = buffer.readUInt16LE(localHeaderOffset + 26)
    const localExtraLength = buffer.readUInt16LE(localHeaderOffset + 28)
    const dataStart = localHeaderOffset + 30 + localFileNameLength + localExtraLength
    const compressed = buffer.subarray(dataStart, dataStart + compressedSize)
    const data = compressionMethod === 0
      ? compressed
      : zlib.inflateRawSync(compressed)

    entries.set(name.replace(/\\/g, '/'), data.toString('utf8'))
    offset += 46 + fileNameLength + extraLength + commentLength
  }

  return entries
}

function readSharedStrings(xml) {
  if (!xml) return []

  return Array.from(xml.matchAll(/<si[^>]*>([\s\S]*?)<\/si>/g), (match) => {
    const parts = Array.from(match[1].matchAll(/<t[^>]*>([\s\S]*?)<\/t>/g), (textMatch) => decodeXml(textMatch[1]))
    return parts.join('')
  })
}

function columnFromCellReference(reference) {
  return String(reference || '').replace(/\d+/g, '')
}

function readWorksheetRows(xml, sharedStrings) {
  const rows = []

  for (const rowMatch of xml.matchAll(/<row[^>]*>([\s\S]*?)<\/row>/g)) {
    const row = {}
    for (const cellMatch of rowMatch[1].matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)) {
      const attributes = cellMatch[1]
      const body = cellMatch[2] || ''
      const reference = attributes.match(/\br="([^"]+)"/)?.[1]
      const column = columnFromCellReference(reference)
      const type = attributes.match(/\bt="([^"]+)"/)?.[1]
      const rawValue = body.match(/<v>([\s\S]*?)<\/v>/)?.[1] || ''
      const inlineValue = body.match(/<t[^>]*>([\s\S]*?)<\/t>/)?.[1] || ''

      let value = rawValue
      if (type === 's') value = sharedStrings[Number(rawValue)] || ''
      if (type === 'inlineStr') value = decodeXml(inlineValue)
      row[column] = decodeXml(value).trim()
    }
    rows.push(row)
  }

  return rows
}

function loadCollegesFromXlsx(filePath = DEFAULT_XLSX_PATH) {
  const entries = readZipEntries(fs.readFileSync(filePath))
  const sharedStrings = readSharedStrings(entries.get('xl/sharedStrings.xml'))
  const worksheet = entries.get('xl/worksheets/sheet1.xml')

  if (!worksheet) {
    throw new Error('Invalid XLSX file: xl/worksheets/sheet1.xml not found')
  }

  const rows = readWorksheetRows(worksheet, sharedStrings).slice(1)
  return rows
    .filter((row) => row.B)
    .map((row) => ({
      name: row.B,
      shortName: row.C || null,
      email: row.D || null,
      phone: row.E || null,
      website: row.F || null,
      socialVk: row.G || null,
      isProfessionalitet: row.H === 'Профессионалитет',
      admissionLink: row.I || null
    }))
}

async function importColleges(filePath = DEFAULT_XLSX_PATH) {
  const db = getDb()
  const colleges = loadCollegesFromXlsx(filePath)

  if (colleges.length !== EXPECTED_COLLEGE_COUNT) {
    throw new Error(`Expected ${EXPECTED_COLLEGE_COUNT} colleges, found ${colleges.length}`)
  }

  const client = await db.connect()
  try {
    await client.query('BEGIN')

    const repRole = await client.query(`SELECT id FROM roles WHERE name = 'college_rep' LIMIT 1`)
    const repRoleId = repRole.rows[0]?.id

    if (repRoleId) {
      await client.query(
        `UPDATE audit_logs SET user_id = NULL WHERE user_id IN (SELECT id FROM users WHERE role_id = $1)`,
        [repRoleId]
      )
      await client.query(`DELETE FROM users WHERE role_id = $1`, [repRoleId])
    }

    await client.query('DELETE FROM college_specialties')
    await client.query('DELETE FROM college_addresses')
    await client.query('DELETE FROM colleges')

    for (const college of colleges) {
      await client.query(
        `
          INSERT INTO colleges (
            name, short_name, description, status, city_id,
            budget_places, commercial_places, avg_score, min_score,
            phone, email, website, social_vk, is_professionalitet,
            admission_link, admission_method, admission_instructions
          )
          VALUES ($1, $2, '', 'active', NULL, 0, 0, 0, 0, $3, $4, $5, $6, $7, $8, NULL, NULL)
        `,
        [
          college.name,
          college.shortName,
          college.phone,
          college.email,
          college.website,
          college.socialVk,
          college.isProfessionalitet,
          college.admissionLink
        ]
      )
    }

    await client.query('COMMIT')
    return { imported: colleges.length }
  } catch (error) {
    await client.query('ROLLBACK')
    throw error
  } finally {
    client.release()
  }
}

async function main() {
  const filePath = path.resolve(process.argv[2] || DEFAULT_XLSX_PATH)
  const result = await importColleges(filePath)
  console.log(`Imported colleges: ${result.imported}`)
}

if (require.main === module) {
  main()
    .catch((error) => {
      console.error(error.message)
      process.exitCode = 1
    })
    .finally(() => {
      if (db) db.end()
    })
}

module.exports = {
  loadCollegesFromXlsx,
  importColleges
}

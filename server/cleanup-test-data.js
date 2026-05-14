const db = require('./db');

const execute = process.argv.includes('--execute');

const testUserWhere = `
  login ILIKE 'e2e_%'
  OR login ILIKE 'test-%'
  OR email ILIKE '%example.com%'
  OR name ILIKE '%E2E%'
  OR name ILIKE '%Test%'
`;

const testCollegeWhere = `
  name ILIKE 'E2E %'
  OR description ILIKE '%Playwright e2e tests%'
  OR email ILIKE '%example.com%'
  OR website ILIKE '%example.%'
`;

const testSpecialtyWhere = `
  name ILIKE 'E2E %'
  OR description ILIKE '%Playwright e2e tests%'
`;

const testAddressWhere = `
  address ILIKE '%Test street%'
  OR email ILIKE '%example.com%'
  OR contact_person ILIKE 'E2E%'
`;

async function count(client, label, query) {
  const result = await client.query(query);
  const value = Number(result.rows[0].count);
  console.log(`${label}: ${value}`);
  return value;
}

async function remove(client, label, query) {
  const result = await client.query(query);
  console.log(`${label}: ${result.rowCount}`);
}

async function main() {
  const client = await db.connect();

  try {
    const testCollegeIdsSql = `SELECT id FROM colleges WHERE ${testCollegeWhere}`;
    const testSpecialtyIdsSql = `SELECT id FROM specialties WHERE ${testSpecialtyWhere}`;
    const testUserIdsSql = `
      SELECT u.id
      FROM users u
      WHERE ${testUserWhere}
      OR u.college_id IN (${testCollegeIdsSql})
    `;

    console.log(execute ? 'Deleting test data...' : 'Dry run: test data that would be deleted');

    await count(client, 'users', `SELECT COUNT(*) FROM users WHERE id IN (${testUserIdsSql})`);
    await count(client, 'colleges', `SELECT COUNT(*) FROM colleges WHERE id IN (${testCollegeIdsSql})`);
    await count(client, 'specialties', `SELECT COUNT(*) FROM specialties WHERE id IN (${testSpecialtyIdsSql})`);
    await count(client, 'college_addresses', `
      SELECT COUNT(*)
      FROM college_addresses
      WHERE ${testAddressWhere}
      OR college_id IN (${testCollegeIdsSql})
    `);
    await count(client, 'college_specialties', `
      SELECT COUNT(*)
      FROM college_specialties
      WHERE college_id IN (${testCollegeIdsSql})
      OR specialty_id IN (${testSpecialtyIdsSql})
    `);
    await count(client, 'specialty_sectors', `
      SELECT COUNT(*)
      FROM specialty_sectors
      WHERE specialty_id IN (${testSpecialtyIdsSql})
    `);
    await count(client, 'audit_logs', `
      SELECT COUNT(*)
      FROM audit_logs
      WHERE entity_name ILIKE 'E2E %'
      OR changes::text ILIKE '%Playwright e2e tests%'
      OR changes::text ILIKE '%example.com%'
      OR user_id IN (${testUserIdsSql})
    `);

    if (!execute) return;

    await client.query('BEGIN');

    await remove(client, 'deleted audit_logs', `
      DELETE FROM audit_logs
      WHERE entity_name ILIKE 'E2E %'
      OR changes::text ILIKE '%Playwright e2e tests%'
      OR changes::text ILIKE '%example.com%'
      OR user_id IN (${testUserIdsSql})
    `);
    await remove(client, 'deleted login_logs', `
      DELETE FROM login_logs
      WHERE user_id IN (${testUserIdsSql})
    `);
    await remove(client, 'deleted user_sessions', `
      DELETE FROM user_sessions
      WHERE user_id IN (${testUserIdsSql})
    `);
    await remove(client, 'deleted college_specialties', `
      DELETE FROM college_specialties
      WHERE college_id IN (${testCollegeIdsSql})
      OR specialty_id IN (${testSpecialtyIdsSql})
    `);
    await remove(client, 'deleted specialty_sectors', `
      DELETE FROM specialty_sectors
      WHERE specialty_id IN (${testSpecialtyIdsSql})
    `);
    await remove(client, 'deleted college_addresses', `
      DELETE FROM college_addresses
      WHERE ${testAddressWhere}
      OR college_id IN (${testCollegeIdsSql})
    `);
    await remove(client, 'deleted users', `
      DELETE FROM users
      WHERE id IN (${testUserIdsSql})
    `);
    await remove(client, 'deleted specialties', `
      DELETE FROM specialties
      WHERE id IN (${testSpecialtyIdsSql})
    `);
    await remove(client, 'deleted colleges', `
      DELETE FROM colleges
      WHERE id IN (${testCollegeIdsSql})
    `);

    await client.query('COMMIT');
  } catch (error) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {}
    throw error;
  } finally {
    client.release();
    await db.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

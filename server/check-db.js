// server/check-db.js
const db = require('./db');

const check = async () => {
  try {
    console.log('🔍 Проверка состояния базы данных...\n');

    const tables = [
      'users', 'roles', 'cities', 'colleges', 'specialties',
      'sectors', 'college_specialties', 'specialty_sectors',
      'college_addresses', 'login_logs', 'user_sessions',
      'audit_logs', 'site_settings'
    ];

    for (const table of tables) {
      try {
        const result = await db.query(`SELECT COUNT(*) as count FROM ${table}`);
        const count = parseInt(result.rows[0].count);
        const icon = count > 0 ? '✅' : '⚠️';
        console.log(`${icon} ${table}: ${count} записей`);
      } catch (e) {
        console.log(`❌ ${table}: ОШИБКА — ${e.message}`);
      }
    }

    console.log('\n📊 Детали:');

    // Проверим роли
    const roles = await db.query('SELECT * FROM roles');
    console.log('\n👥 Роли:');
    roles.rows.forEach(r => console.log(`  — ${r.name}: ${r.description}`));

    // Проверим города
    const cities = await db.query('SELECT id, name, region FROM cities');
    console.log('\n🏙️ Города:');
    cities.rows.forEach(c => console.log(`  — ${c.name} (${c.region})`));

    // Проверим колледжи
    const colleges = await db.query('SELECT id, name, status FROM colleges');
    console.log('\n🏫 Колледжи:');
    if (colleges.rows.length === 0) {
      console.log('  (пусто — нужно запустить seed.js)');
    } else {
      colleges.rows.forEach(c => console.log(`  — ${c.name} [${c.status}]`));
    }

    // Проверим отрасли
    const sectors = await db.query('SELECT id, name, code, is_active FROM sectors');
    console.log('\n📂 Отрасли:');
    if (sectors.rows.length === 0) {
      console.log('  (пусто — нужно запустить seed.js)');
    } else {
      sectors.rows.forEach(s => console.log(`  — ${s.name} (${s.code}) [active: ${s.is_active}]`));
    }

    // Проверим специальности
    const specs = await db.query('SELECT id, code, name, status FROM specialties');
    console.log('\n🎓 Специальности:');
    if (specs.rows.length === 0) {
      console.log('  (пусто — нужно запустить seed.js)');
    } else {
      specs.rows.forEach(s => console.log(`  — ${s.code} ${s.name} [${s.status}]`));
    }

    // Проверим настройки сайта
    const settings = await db.query('SELECT setting_key, setting_value FROM site_settings');
    console.log('\n⚙️ Настройки сайта:');
    settings.rows.forEach(s => console.log(`  — ${s.setting_key}: ${s.setting_value}`));

    console.log('\n✅ Проверка завершена.');

  } catch (error) {
    console.error('❌ Ошибка:', error.message);
  }

  process.exit(0);
};

check();

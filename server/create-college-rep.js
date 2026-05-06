// server/create-college-rep.js
const db = require('./db');
const bcrypt = require('bcryptjs');

async function createCollegeRep() {
  try {
    // Получаем роль college_rep
    const roleResult = await db.query(`SELECT id FROM roles WHERE name = 'college_rep'`);
    const collegeRepRoleId = roleResult.rows[0].id;
    console.log('✅ Роль college_rep ID:', collegeRepRoleId);

    // Получаем колледж (Уфимский машиностроительный колледж, id=2)
    const collegeResult = await db.query(`SELECT id, name FROM colleges WHERE id = 2`);
    if (collegeResult.rows.length === 0) {
      console.error('❌ Колледж с id=2 не найден');
      return;
    }
    const college = collegeResult.rows[0];
    console.log('✅ Колледж:', college.name, '(id=' + college.id + ')');

    // Проверяем, существует ли уже представитель
    const existingResult = await db.query(`SELECT id, login FROM users WHERE login = 'umk_rep'`);
    if (existingResult.rows.length > 0) {
      console.log('⏭️ Представитель уже существует:', existingResult.rows[0]);
      console.log('🔑 Логин: umk_rep');
      console.log('🔑 Пароль: rep123');
      return;
    }

    // Хешируем пароль
    const passwordHash = await bcrypt.hash('rep123', 10);
    console.log('🔐 Пароль захеширован');

    // Создаём пользователя-представителя
    const userResult = await db.query(
      `INSERT INTO users (login, email, password_hash, name, role_id, college_id, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'active')
       RETURNING id, login, name, role_id, college_id`,
      ['umk_rep', 'umk@college-rb.ru', passwordHash, 'Представитель УМК', collegeRepRoleId, college.id]
    );

    const user = userResult.rows[0];
    console.log('✅ Представитель колледжа создан!');
    console.log('👤 ID:', user.id);
    console.log('🔑 Логин:', user.login);
    console.log('🔑 Пароль: rep123');
    console.log('👤 Имя:', user.name);
    console.log('🏫 Колледж:', college.name);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Ошибка:', error);
    process.exit(1);
  }
}

createCollegeRep();

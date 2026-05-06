// server/seed.js
// Скрипт для начального заполнения базы данных реальными данными колледжей Башкортостана
const db = require('./db');

const seed = async () => {
  console.log('🌱 Начинаем заполнение базы данных колледжей Башкортостана...\n');

  const client = await db.connect();

  try {
    await client.query('BEGIN');

    // ==========================================
    // 0. Очистка дубликатов от предыдущих запусков
    // ==========================================
    console.log('🧹 Очищаем дубликаты...');
    await client.query(`DELETE FROM specialty_sectors WHERE specialty_id NOT IN (SELECT id FROM specialties)`);
    await client.query(`DELETE FROM college_specialties WHERE specialty_id NOT IN (SELECT id FROM specialties) OR college_id NOT IN (SELECT id FROM colleges)`);
    await client.query(`DELETE FROM college_addresses WHERE college_id NOT IN (SELECT id FROM colleges)`);
    await client.query(`DELETE FROM sectors WHERE code IN (SELECT code FROM sectors GROUP BY code HAVING COUNT(*) > 1) AND id NOT IN (SELECT MIN(id) FROM sectors GROUP BY code HAVING COUNT(*) > 1)`);
    await client.query(`DELETE FROM specialties WHERE code IN (SELECT code FROM specialties GROUP BY code HAVING COUNT(*) > 1) AND id NOT IN (SELECT MIN(id) FROM specialties GROUP BY code HAVING COUNT(*) > 1)`);
    console.log('  ✅ Дубликаты очищены\n');

    // ==========================================
    // 1. Секторы/отрасли
    // ==========================================
    console.log('📂 Заполняем секторы...');
    const sectorsData = [
      { name: 'Технические и технологические', code: '08', description: 'Подготовка специалистов для промышленности, IT-сферы, строительства и машиностроения.', image_url: '/1.jpg', sort_order: 1 },
      { name: 'Экономика и управление', code: '38', description: 'Бухгалтеры, менеджеры, экономисты для бизнеса и государственного управления.', image_url: '/2.jpg', sort_order: 2 },
      { name: 'Информационные технологии', code: '09', description: 'Программирование, системное администрирование, информационная безопасность.', image_url: '/it.jpg', sort_order: 3 },
      { name: 'Строительство и архитектура', code: '07', description: 'Строительство, архитектура, дизайн среды, инженерные системы.', image_url: '/build.jpg', sort_order: 4 },
      { name: 'Медицина и здравоохранение', code: '31', description: 'Сестринское дело, лабораторная диагностика, фармацевтика.', image_url: '/med.jpg', sort_order: 5 },
      { name: 'Образование и педагогика', code: '44', description: 'Преподавание, воспитание, дополнительная работа с детьми.', image_url: '/edu.jpg', sort_order: 6 },
      { name: 'Сфера услуг и сервис', code: '43', description: 'Гостиничное дело, туризм, общественное питание, бытовые услуги.', image_url: '/service.jpg', sort_order: 7 },
      { name: 'Сельское хозяйство', code: '35', description: 'Агрономия, ветеринария, механизация сельского хозяйства.', image_url: '/agro.jpg', sort_order: 8 },
    ];

    const sectorIds = {};
    for (const s of sectorsData) {
      // Удаляем дубликаты (оставляем только один с минимальным ID)
      await client.query(
        `DELETE FROM sectors WHERE code = $1 AND id NOT IN (SELECT MIN(id) FROM sectors WHERE code = $1 GROUP BY code)`,
        [s.code]
      );

      // Проверяем, существует ли сектор
      const existing = await client.query(`SELECT id FROM sectors WHERE code = $1`, [s.code]);
      if (existing.rows.length > 0) {
        sectorIds[s.code] = existing.rows[0].id;
        // Обновляем данные
        await client.query(
          `UPDATE sectors SET name = $2, description = $3, image_url = $4, sort_order = $5, is_active = true WHERE id = $1`,
          [sectorIds[s.code], s.name, s.description, s.image_url, s.sort_order]
        );
        console.log(`  🔄 ${s.name} (обновлено)`);
      } else {
        const result = await client.query(
          `INSERT INTO sectors (name, code, description, image_url, sort_order, is_active)
           VALUES ($1, $2, $3, $4, $5, true)
           RETURNING id`,
          [s.name, s.code, s.description, s.image_url, s.sort_order]
        );
        sectorIds[s.code] = result.rows[0].id;
        console.log(`  ✅ ${s.name}`);
      }
    }

    // ==========================================
    // 2. Настройки сайта
    // ==========================================
    console.log('\n⚙️ Заполняем настройки сайта...');
    const siteSettings = [
      { key: 'site_title', value: 'Колледжи Республики Башкортостан', description: 'Заголовок главной страницы' },
      { key: 'site_description', value: 'Портал среднего профессионального образования Республики Башкортостан', description: 'Описание портала' },
      { key: 'footer_address', value: 'г. Уфа, ул. Ленина, 1', description: 'Адрес в футере' },
      { key: 'footer_phone', value: '+7 (347) 123-45-67', description: 'Телефон в футере' },
      { key: 'footer_email', value: 'info@college-rb.ru', description: 'Email в футере' },
      { key: 'hero_title', value: 'Колледжи Башкортостана', description: 'Заголовок hero-секции' },
      { key: 'hero_subtitle', value: 'Найди свой путь в профессии', description: 'Подзаголовок hero-секции' },
      { key: 'stats_title', value: 'Портал в цифрах', description: 'Заголовок секции статистики' },
    ];

    for (const setting of siteSettings) {
      const existing = await client.query(`SELECT id FROM site_settings WHERE setting_key = $1`, [setting.key]);
      if (existing.rows.length > 0) {
        await client.query(
          `UPDATE site_settings SET setting_value = to_jsonb($1::text), description = $2 WHERE setting_key = $3`,
          [setting.value, setting.description, setting.key]
        );
        console.log(`  🔄 ${setting.key} (обновлено)`);
      } else {
        await client.query(
          `INSERT INTO site_settings (setting_key, setting_value, setting_type, description)
           VALUES ($1, to_jsonb($2::text), 'string', $3)`,
          [setting.key, setting.value, setting.description]
        );
        console.log(`  ✅ ${setting.key}`);
      }
    }

    // ==========================================
    // 3. Роли и админ-пользователь
    // ==========================================
    console.log('\n👤 Проверяем роли...');
    const rolesData = [
      { name: 'admin', description: 'Администратор портала' },
      { name: 'college_rep', description: 'Представитель колледжа' },
    ];

    const roleIds = {};
    for (const role of rolesData) {
      const existing = await client.query(`SELECT id FROM roles WHERE name = $1`, [role.name]);
      if (existing.rows.length > 0) {
        roleIds[role.name] = existing.rows[0].id;
        console.log(`  ⏭️ ${role.name} (уже существует)`);
      } else {
        const result = await client.query(
          `INSERT INTO roles (name, description) VALUES ($1, $2) RETURNING id`,
          [role.name, role.description]
        );
        roleIds[role.name] = result.rows[0].id;
        console.log(`  ✅ ${role.name}`);
      }
    }

    // Создаём admin-пользователя (если нет)
    console.log('\n👤 Создаём admin-пользователя...');
    const bcrypt = require('bcryptjs');
    const adminExisting = await client.query(`SELECT id FROM users WHERE login = 'admin'`);
    let adminId = 1;

    if (adminExisting.rows.length > 0) {
      adminId = adminExisting.rows[0].id;
      console.log(`  ⏭️ admin (уже существует, id=${adminId})`);
    } else {
      const passwordHash = await bcrypt.hash('admin123', 10);
      const adminResult = await client.query(
        `INSERT INTO users (login, email, password_hash, name, role_id, status)
         VALUES ($1, $2, $3, $4, $5, 'active')
         RETURNING id`,
        ['admin', 'admin@college-rb.ru', passwordHash, 'Администратор', roleIds['admin']]
      );
      adminId = adminResult.rows[0].id;
      console.log(`  ✅ admin (id=${adminId}, пароль: admin123)`);
    }

    // ==========================================
    // 4. Колледжи Башкортостана
    // ==========================================
    console.log('\n🏫 Заполняем колледжи...');
    const collegesData = [
      {
        name: 'Уфимский машиностроительный колледж',
        short_name: 'УМК',
        description: 'Одно из старейших и наиболее престижных учебных заведений СПО в Республике Башкортостан. Готовит высококвалифицированных специалистов для машиностроительной и металлургической отрасли. Колледж активно участвует в федеральном проекте «Профессионалитет».',
        status: 'active',
        city_id: 1, // Уфа
        budget_places: 320,
        commercial_places: 80,
        avg_score: 4.2,
        min_score: 3.5,
        phone: '+7 (347) 246-29-30',
        email: 'pu-2@mail.ru',
        website: 'https://umkufa.ru/',
        social_vk: 'https://vk.com/umkcollege',
        social_max: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Машиностроение',
        logo_image_url: '/ymk.jpg',
        opportunities: JSON.stringify([
          'Современные лаборатории и мастерские',
          'Доступ к электронной библиотеке',
          'Курсы дополнительного образования',
          'Участие в чемпионате «ПРОФЕССИОНАЛЫ»',
          'Спортивные секции',
          'Творческие студии',
          'Студенческий совет'
        ]),
        employers: JSON.stringify([
          'ПАО «УМПО»',
          'АО «УАПО»',
          'АО «Уфимское агрегатное производственное объединение»',
          'АО «Уфимский приборостроительный завод»',
          'ПАО «ОДК-УМПО»'
        ]),
        workshops: JSON.stringify([
          'Слесарная мастерская с современным инструментом',
          'Механическая мастерская с токарными и фрезерными станками',
          'Лаборатория станков с ЧПУ',
          'Лаборатория контроля качества'
        ]),
        professions: JSON.stringify([
          'Техник-технолог',
          'Техник-механик',
          'Техник-конструктор',
          'Оператор станков с ЧПУ',
          'Слесарь-ремонтник'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда: пандусы, лифты',
          'Адаптированные образовательные программы',
          'Психолого-педагогическое сопровождение'
        ])
      },
      {
        name: 'Уфимский политехнический колледж',
        short_name: 'УПК',
        description: 'Крупный многопрофильный колледж, готовящий специалистов в области информационных технологий, экономики и сервиса. Один из ведущих колледжей республики по направлению IT.',
        status: 'active',
        city_id: 1,
        budget_places: 250,
        commercial_places: 100,
        avg_score: 4.1,
        min_score: 3.4,
        phone: '+7 (347) 266-33-20',
        email: 'upk@upkufa.ru',
        website: 'https://upkufa.ru/',
        social_vk: 'https://vk.com/upkufa',
        social_max: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Информационные технологии',
        logo_image_url: '/ypk.png',
        opportunities: JSON.stringify([
          'Компьютерные классы с современным ПО',
          'Сетевая академия Cisco',
          'Участие в WorldSkills Russia',
          'Спортивный зал и секции'
        ]),
        employers: JSON.stringify([
          'ПАО «Ростелеком»',
          'ООО «Башинформсвязь»',
          'IT-компании Уфы'
        ]),
        workshops: JSON.stringify([
          'Компьютерные лаборатории',
          'Сетевая лаборатория',
          'Лаборатория программирования'
        ]),
        professions: JSON.stringify([
          'Программист',
          'Системный администратор',
          'Веб-разработчик',
          'Техник по защите информации'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда',
          'Адаптированные программы'
        ])
      },
      {
        name: 'Уфимский торгово-экономический колледж',
        short_name: 'УТЭК',
        description: 'Ведущий колледж республики в сфере торговли, экономики и сервиса. Готовит бухгалтеров, менеджеров, товароведов и специалистов в сфере услуг.',
        status: 'active',
        city_id: 1,
        budget_places: 180,
        commercial_places: 120,
        avg_score: 4.0,
        min_score: 3.3,
        phone: '+7 (347) 277-18-86',
        email: 'utek@mail.ru',
        website: '',
        social_vk: '',
        is_professionalitet: false,
        professionalitet_cluster: null,
        logo_image_url: '',
        opportunities: JSON.stringify([
          'Учебные аудитории с современным оборудованием',
          'Практика в торговых организациях',
          'Спортивные мероприятия'
        ]),
        employers: JSON.stringify([
          'Торговые сети «Магнит», «Пятёрочка»',
          'Банки Уфы',
          'Гостиницы и рестораны'
        ]),
        workshops: JSON.stringify([]),
        professions: JSON.stringify([
          'Бухгалтер',
          'Менеджер по продажам',
          'Товаровед',
          'Администратор гостиницы'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Уфимский медицинский колледж',
        short_name: 'УФМК',
        description: 'Старейшее медицинское учебное заведение среднего звена в Башкортостане. Готовит медсестёр, фельдшеров, фармацевтов и лаборантов для лечебных учреждений республики.',
        status: 'active',
        city_id: 1,
        budget_places: 200,
        commercial_places: 50,
        avg_score: 4.5,
        min_score: 4.0,
        phone: '+7 (347) 272-26-15',
        email: 'umk@minzdrav.rb.ru',
        website: '',
        social_vk: '',
        is_professionalitet: false,
        professionalitet_cluster: null,
        logo_image_url: '',
        opportunities: JSON.stringify([
          'Учебные медицинские кабинеты',
          'Практика в больницах и поликлиниках',
          'Симуляционный центр'
        ]),
        employers: JSON.stringify([
          'Республиканские больницы Уфы',
          'Поликлиники',
          'Аптечные сети',
          'Лаборатории'
        ]),
        workshops: JSON.stringify([
          'Учебный медицинский кабинет',
          'Симуляционный центр'
        ]),
        professions: JSON.stringify([
          'Медицинская сестра/брат',
          'Фельдшер',
          'Фармацевт',
          'Лаборант'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда',
          'Адаптированные программы для лиц с ОВЗ'
        ])
      },
      {
        name: 'Уфимский колледж предпринимательства, экономики и сервиса',
        short_name: 'УКПЭС',
        description: 'Многопрофильный колледж, специализирующийся на подготовке специалистов для сферы услуг, дизайна, парикмахерского искусства и кулинарного дела.',
        status: 'active',
        city_id: 1,
        budget_places: 150,
        commercial_places: 80,
        avg_score: 3.8,
        min_score: 3.2,
        phone: '+7 (347) 241-36-06',
        email: 'ukpes@mail.ru',
        website: '',
        social_vk: '',
        is_professionalitet: false,
        professionalitet_cluster: null,
        logo_image_url: '',
        opportunities: JSON.stringify([
          'Учебные салоны красоты',
          'Учебная кухня и кулинарные мастерские',
          'Дизайн-студии'
        ]),
        employers: JSON.stringify([
          'Салоны красоты Уфы',
          'Рестораны и кафе',
          'Дизайн-студии'
        ]),
        workshops: JSON.stringify([
          'Учебный салон красоты',
          'Учебная кухня'
        ]),
        professions: JSON.stringify([
          'Парикмахер',
          'Повар-кондитер',
          'Дизайнер',
          'Мастер маникюра'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Стерлитамакский политехнический колледж',
        short_name: 'СПК',
        description: 'Крупный колледж в городе Стерлитамак, готовящий специалистов для химической промышленности, строительства и сферы услуг.',
        status: 'active',
        city_id: 2, // Стерлитамак
        budget_places: 200,
        commercial_places: 60,
        avg_score: 3.9,
        min_score: 3.3,
        phone: '+7 (3473) 33-32-55',
        email: 'spk@sterlitamak.ru',
        website: '',
        social_vk: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Строительство',
        logo_image_url: '/cpk.jpg',
        opportunities: JSON.stringify([
          'Современные мастерские',
          'Строительные лаборатории',
          'Спортивные секции'
        ]),
        employers: JSON.stringify([
          'Строительные компании Стерлитамака',
          'АО «Сода»',
          'Предприятия химической отрасли'
        ]),
        workshops: JSON.stringify([
          'Строительная мастерская',
          'Лаборатория материаловедения'
        ]),
        professions: JSON.stringify([
          'Строитель',
          'Маляр штукатур',
          'Техник-строитель',
          'Сварщик'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Салаватский индустриальный колледж',
        short_name: 'СИК',
        description: 'Колледж в городе Салават, готовящий специалистов для нефтехимической и химической промышленности. Участник проекта «Профессионалитет».',
        status: 'active',
        city_id: 3, // Салават
        budget_places: 180,
        commercial_places: 40,
        avg_score: 4.0,
        min_score: 3.4,
        phone: '+7 (3476) 35-34-41',
        email: 'sik@salavat.ru',
        website: '',
        social_vk: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Химическая промышленность',
        logo_image_url: '/sik.jpg',
        opportunities: JSON.stringify([
          'Лаборатории химического анализа',
          'Практика на предприятиях',
          'Спортивный комплекс'
        ]),
        employers: JSON.stringify([
          'ПАО «Салаватнефтеоргсинтез»',
          'АО «Газпром нефтехим Салават»',
          'Химические предприятия города'
        ]),
        workshops: JSON.stringify([
          'Химическая лаборатория',
          'Учебный полигон'
        ]),
        professions: JSON.stringify([
          'Аппаратчик химической технологии',
          'Лаборант-аналитик',
          'Техник-технолог',
          'Оператор нефтепереработки'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Нефтекамский машиностроительный колледж',
        short_name: 'НМК',
        description: 'Колледж в городе Нефтекамск, специализирующийся на подготовке кадров для машиностроения и автомобильной промышленности.',
        status: 'active',
        city_id: 4, // Нефтекамск
        budget_places: 160,
        commercial_places: 50,
        avg_score: 3.8,
        min_score: 3.2,
        phone: '+7 (34783) 7-25-60',
        email: 'nmk@neftkam.ru',
        website: '',
        social_vk: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Машиностроение',
        logo_image_url: '/nmk.png',
        opportunities: JSON.stringify([
          'Механические мастерские',
          'Лаборатория ЧПУ',
          'Спортивный зал'
        ]),
        employers: JSON.stringify([
          'АО «Нефтекамский автозавод» (НефАЗ)',
          'Машиностроительные предприятия',
          'Предприятия Камского промышленного узла'
        ]),
        workshops: JSON.stringify([
          'Механическая мастерская',
          'Лаборатория станков с ЧПУ'
        ]),
        professions: JSON.stringify([
          'Техник-механик',
          'Слесарь',
          'Оператор станков с ЧПУ',
          'Сварщик'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Октябрьский нефтяной колледж им. С.И. Кувыкина',
        short_name: 'ОНК',
        description: 'Колледж в городе Октябрьский, один из ведущих в подготовке кадров для нефтегазовой отрасли Башкортостана. Участник проекта «Профессионалитет».',
        status: 'active',
        city_id: 5, // Октябрьский
        budget_places: 170,
        commercial_places: 40,
        avg_score: 4.1,
        min_score: 3.5,
        phone: '+7 (34767) 3-05-87',
        email: 'onk@oktyabrsk.ru',
        website: '',
        social_vk: '',
        is_professionalitet: true,
        professionalitet_cluster: 'Нефтегазовая отрасль',
        logo_image_url: '/onk.png',
        opportunities: JSON.stringify([
          'Лаборатории бурения и добычи',
          'Учебный полигон',
          'Спортивные сооружения'
        ]),
        employers: JSON.stringify([
          'АО «Башнефть»',
          'ООО «Газпром добыча Октябрьское»',
          'Предприятия нефтегазового комплекса'
        ]),
        workshops: JSON.stringify([
          'Лаборатория бурения',
          'Учебный полигон'
        ]),
        professions: JSON.stringify([
          'Техник по добыче нефти',
          'Техник-механик',
          'Оператор по добыче нефти',
          'Электромонтёр'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      },
      {
        name: 'Уфимский строительный колледж',
        short_name: 'УСК',
        description: 'Колледж, специализирующийся на подготовке строительных кадров: мастеров отделочных работ, каменщиков, монтажников и техников-строителей.',
        status: 'active',
        city_id: 1,
        budget_places: 140,
        commercial_places: 60,
        avg_score: 3.6,
        min_score: 3.1,
        phone: '+7 (347) 266-55-42',
        email: 'usk@mail.ru',
        website: '',
        social_vk: '',
        is_professionalitet: false,
        professionalitet_cluster: null,
        logo_image_url: '',
        opportunities: JSON.stringify([
          'Строительные мастерские',
          'Лаборатория строительных материалов',
          'Участие в конкурсах профмастерства'
        ]),
        employers: JSON.stringify([
          'Строительные компании Уфы',
          'АО «Башкиргражданстрой»',
          'Управляющие компании'
        ]),
        workshops: JSON.stringify([
          'Строительная мастерская',
          'Лаборатория стройматериалов'
        ]),
        professions: JSON.stringify([
          'Каменщик',
          'Маляр-штукатур',
          'Монтажник',
          'Техник-строитель'
        ]),
        ovz_programs: JSON.stringify([
          'Доступная среда'
        ])
      }
    ];

    const collegeIds = {};
    for (const college of collegesData) {
      const existing = await client.query(`SELECT id FROM colleges WHERE name = $1`, [college.name]);
      if (existing.rows.length > 0) {
        collegeIds[college.name] = existing.rows[0].id;
        console.log(`  ⏭️ ${college.name} (уже существует)`);
      } else {
        const result = await client.query(
          `INSERT INTO colleges (
            name, short_name, description, status, city_id,
            budget_places, commercial_places, avg_score, min_score,
            phone, email, website,
            social_vk, social_max,
            is_professionalitet, professionalitet_cluster,
            logo_image_url,
            opportunities, employers, workshops, professions, ovz_programs,
            created_by
          ) VALUES (
            $1,$2,$3,$4,$5, $6,$7,$8,$9,
            $10,$11,$12, $13,$14,
            $15,$16, $17,
            $18::jsonb, $19::jsonb, $20::jsonb, $21::jsonb, $22::jsonb,
            $23
          ) RETURNING id, name`,
          [
            college.name, college.short_name, college.description, college.status, college.city_id,
            college.budget_places, college.commercial_places, college.avg_score, college.min_score,
            college.phone, college.email, college.website,
            college.social_vk, college.social_max,
            college.is_professionalitet, college.professionalitet_cluster,
            college.logo_image_url,
            college.opportunities, college.employers, college.workshops, college.professions, college.ovz_programs,
            adminId
          ]
        );
        collegeIds[college.name] = result.rows[0].id;
        console.log(`  ✅ ${college.name}`);
      }
    }

    // ==========================================
    // 5. Адреса колледжей
    // ==========================================
    console.log('\n📍 Заполняем адреса колледжей...');
    const addressesData = [
      { college: 'Уфимский машиностроительный колледж', name: 'Главный корпус', address: 'г. Уфа, ул. Борисоглебская, 32', phone: '+7 (347) 246-29-30', coordinates: '54.813002, 56.118924', is_main: true },
      { college: 'Уфимский машиностроительный колледж', name: 'Второй корпус', address: 'г. Уфа, ул. Маяковского, 3', phone: '+7 (347) 246-29-31', coordinates: '54.812826, 56.076029', is_main: false },
      { college: 'Уфимский политехнический колледж', name: 'Главный корпус', address: 'г. Уфа, ул. Менделеева, 130', coordinates: '54.7423, 56.0156', is_main: true },
      { college: 'Уфимский медицинский колледж', name: 'Главный корпус', address: 'г. Уфа, ул. Пушкина, 85', coordinates: '54.7373, 55.9602', is_main: true },
      { college: 'Уфимский торгово-экономический колледж', name: 'Главный корпус', address: 'г. Уфа, ул. Октябрьской Революции, 27', coordinates: '54.7365, 55.9575', is_main: true },
      { college: 'Стерлитамакский политехнический колледж', name: 'Главный корпус', address: 'г. Стерлитамак, ул. Профсоюзная, 42', coordinates: '53.6241, 55.9489', is_main: true },
      { college: 'Салаватский индустриальный колледж', name: 'Главный корпус', address: 'г. Салават, ул. Первомайская, 15', coordinates: '53.3539, 55.9186', is_main: true },
      { college: 'Нефтекамский машиностроительный колледж', name: 'Главный корпус', address: 'г. Нефтекамск, ул. Социалистическая, 45', coordinates: '56.0915, 54.2553', is_main: true },
      { college: 'Октябрьский нефтяной колледж им. С.И. Кувыкина', name: 'Главный корпус', address: 'г. Октябрьский, ул. Стахановская, 23', coordinates: '54.4819, 53.4839', is_main: true },
    ];

    for (const addr of addressesData) {
      const collegeId = collegeIds[addr.college];
      if (!collegeId) { console.log(`  ⚠️  Колледж не найден: ${addr.college}`); continue; }

      const existing = await client.query(
        `SELECT id FROM college_addresses WHERE college_id = $1 AND name = $2`,
        [collegeId, addr.name]
      );
      if (existing.rows.length > 0) {
        console.log(`  ⏭️ ${addr.college} — ${addr.name} (уже существует)`);
      } else {
        const result = await client.query(
          `INSERT INTO college_addresses (college_id, name, address, phone, coordinates, is_main, sort_order)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           RETURNING id`,
          [collegeId, addr.name, addr.address, addr.phone || '', addr.coordinates, addr.is_main, addr.is_main ? 1 : 2]
        );
        console.log(`  ✅ ${addr.college} — ${addr.name}`);
      }
    }

    // ==========================================
    // 6. Специальности
    // ==========================================
    console.log('\n🎓 Заполняем специальности...');
    const specialtiesData = [
      { code: '15.02.08', name: 'Технология машиностроения', description: 'Подготовка техников-технологов для машиностроительных предприятий. Освоение современных технологий обработки металлов, работы на станках с ЧПУ.', qualification: 'Техник-технолог', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 50, commercial_places: 15, price_per_year: 85000, avg_score_last_year: 4.3, is_professionalitet: true, sort_order: 1 },
      { code: '09.02.07', name: 'Информационные системы и программирование', description: 'Подготовка специалистов в области разработки, тестирования и сопровождения информационных систем.', qualification: 'Программист / Специалист по информационным системам', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 50, commercial_places: 25, price_per_year: 75000, avg_score_last_year: 4.4, is_professionalitet: false, sort_order: 2 },
      { code: '38.02.01', name: 'Экономика и бухгалтерский учёт', description: 'Подготовка бухгалтеров, экономистов и специалистов по финансовому учёту для предприятий различных отраслей.', qualification: 'Бухгалтер', duration: '2 года 10 мес', base_education: '11', form: 'full-time', budget_places: 30, commercial_places: 20, price_per_year: 60000, avg_score_last_year: 4.0, is_professionalitet: false, sort_order: 3 },
      { code: '31.02.01', name: 'Лечебное дело', description: 'Подготовка фельдшеров для оказания первичной медико-санитарной помощи, работы в лечебно-профилактических учреждениях.', qualification: 'Фельдшер', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 50, commercial_places: 10, avg_score_last_year: 4.5, is_professionalitet: false, sort_order: 4 },
      { code: '31.02.03', name: 'Лабораторная диагностика', description: 'Подготовка лаборантов для проведения клинических и биохимических исследований в медицинских учреждениях.', qualification: 'Лаборант', duration: '2 года 10 мес', base_education: '11', form: 'full-time', budget_places: 25, commercial_places: 10, avg_score_last_year: 4.3, is_professionalitet: false, sort_order: 5 },
      { code: '43.02.15', name: 'Поварское и кондитерское дело', description: 'Подготовка поваров и кондитеров для предприятий общественного питания, ресторанов и пищевого производства.', qualification: 'Повар-кондитер', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 20, price_per_year: 55000, avg_score_last_year: 3.7, is_professionalitet: false, sort_order: 6 },
      { code: '43.01.02', name: 'Парикмахер', description: 'Подготовка парикмахеров широкого профиля для салонов красоты и индивидуальных предпринимателей.', qualification: 'Парикмахер', duration: '1 год 10 мес', base_education: '9', form: 'full-time', budget_places: 25, commercial_places: 15, price_per_year: 45000, avg_score_last_year: 3.5, is_professionalitet: false, sort_order: 7 },
      { code: '08.02.01', name: 'Строительство и эксплуатация зданий и сооружений', description: 'Подготовка техников-строителей для строительных организаций, управляющих компаний и проектных бюро.', qualification: 'Техник-строитель', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 15, price_per_year: 65000, avg_score_last_year: 3.6, is_professionalitet: false, sort_order: 8 },
      { code: '15.02.17', name: 'Монтаж, наладка и эксплуатация электрооборудования', description: 'Подготовка техников по монтажу и обслуживанию электрооборудования промышленных и гражданских объектов.', qualification: 'Техник-электрик', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 10, avg_score_last_year: 3.8, is_professionalitet: false, sort_order: 9 },
      { code: '21.02.01', name: 'Разработка и эксплуатация нефтяных и газовых месторождений', description: 'Подготовка специалистов для нефтегазовой отрасли: операторов по добыче нефти и газа, техников по бурению.', qualification: 'Техник по эксплуатации нефтяных месторождений', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 50, commercial_places: 10, avg_score_last_year: 4.0, is_professionalitet: true, sort_order: 10 },
      { code: '18.02.08', name: 'Химическая технология органических веществ', description: 'Подготовка техников-технологов для нефтехимической и химической промышленности.', qualification: 'Техник-технолог', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 40, commercial_places: 10, avg_score_last_year: 3.9, is_professionalitet: true, sort_order: 11 },
      { code: '23.02.07', name: 'Техническое обслуживание и ремонт двигателей и систем', description: 'Подготовка специалистов по техническому обслуживанию автомобилей, в том числе на предприятиях автопрома.', qualification: 'Техник по обслуживанию и ремонту', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 10, avg_score_last_year: 3.6, is_professionalitet: false, sort_order: 12 },
      { code: '40.02.01', name: 'Право и организация социального обеспечения', description: 'Подготовка специалистов по правовому обеспечению и социальному страхованию.', qualification: 'Специалист по правоведению', duration: '2 года 10 мес', base_education: '11', form: 'full-time', budget_places: 25, commercial_places: 15, price_per_year: 55000, avg_score_last_year: 4.0, is_professionalitet: false, sort_order: 13 },
      { code: '38.02.04', name: 'Коммерция по отраслям', description: 'Подготовка менеджеров по продажам, специалистов по коммерческой деятельности и маркетингу.', qualification: 'Менеджер по продажам', duration: '2 года 10 мес', base_education: '11', form: 'full-time', budget_places: 25, commercial_places: 15, price_per_year: 55000, avg_score_last_year: 3.8, is_professionalitet: false, sort_order: 14 },
      { code: '43.02.14', name: 'Гостиничное дело', description: 'Подготовка специалистов для гостиничного бизнеса: администраторов, менеджеров, организаторов гостиничного сервиса.', qualification: 'Специалист по гостиничному делу', duration: '2 года 10 мес', base_education: '11', form: 'full-time', budget_places: 20, commercial_places: 15, price_per_year: 58000, avg_score_last_year: 3.7, is_professionalitet: false, sort_order: 15 },
      { code: '35.02.01', name: 'Лесное и лесопарковое хозяйство', description: 'Подготовка техников лесного хозяйства для лесничеств, лесопарковых хозяйств и природоохранных организаций.', qualification: 'Техник лесного хозяйства', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 20, commercial_places: 5, avg_score_last_year: 3.4, is_professionalitet: false, sort_order: 16 },
      { code: '44.02.01', name: 'Дошкольное образование', description: 'Подготовка воспитателей для дошкольных образовательных учреждений: детских садов, центров развития ребёнка.', qualification: 'Воспитатель', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 10, price_per_year: 50000, avg_score_last_year: 4.1, is_professionalitet: false, sort_order: 17 },
      { code: '13.02.11', name: 'Техническая эксплуатация электрического оборудования', description: 'Подготовка техников-электриков для промышленных предприятий, энергетических компаний и организаций ЖКХ.', qualification: 'Техник-электрик', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 10, avg_score_last_year: 3.8, is_professionalitet: false, sort_order: 18 },
      { code: '09.02.06', name: 'Сетевое и системное администрирование', description: 'Подготовка системных и сетевых администраторов для IT-инфраструктуры организаций.', qualification: 'Системный администратор', duration: '3 года 10 мес', base_education: '9', form: 'full-time', budget_places: 50, commercial_places: 20, price_per_year: 70000, avg_score_last_year: 4.2, is_professionalitet: false, sort_order: 19 },
      { code: '43.01.09', name: 'Повар, кондитер', description: 'Подготовка квалифицированных рабочих в области приготовления блюд и кондитерских изделий.', qualification: 'Повар, кондитер', duration: '1 год 10 мес', base_education: '9', form: 'full-time', budget_places: 30, commercial_places: 15, avg_score_last_year: 3.5, is_professionalitet: false, sort_order: 20 },
    ];

    const specialtyIds = {};
    for (const spec of specialtiesData) {
      const existing = await client.query(`SELECT id FROM specialties WHERE code = $1`, [spec.code]);
      if (existing.rows.length > 0) {
        specialtyIds[spec.code] = existing.rows[0].id;
        console.log(`  ⏭️ ${spec.code} — ${spec.name} (уже существует)`);
      } else {
        const result = await client.query(
          `INSERT INTO specialties (
            code, name, description, qualification, duration,
            base_education, form, budget_places, commercial_places,
            price_per_year, avg_score_last_year, is_professionalitet, sort_order, status
          ) VALUES ($1,$2,$3,$4,$5, $6,$7,$8,$9, $10,$11,$12,$13, 'active')
          RETURNING id, code, name`,
          [
            spec.code, spec.name, spec.description, spec.qualification, spec.duration,
            spec.base_education, spec.form, spec.budget_places, spec.commercial_places,
            spec.price_per_year || 0, spec.avg_score_last_year, spec.is_professionalitet, spec.sort_order
          ]
        );
        specialtyIds[spec.code] = result.rows[0].id;
        console.log(`  ✅ ${spec.code} — ${spec.name}`);
      }
    }

    // ==========================================
    // 7. Связи специальностей с секторами
    // ==========================================
    console.log('\n🔗 Связываем специальности с секторами...');
    const specialtySectorMap = [
      { code: '15.02.08', sectorCodes: ['08'] },
      { code: '09.02.07', sectorCodes: ['09'] },
      { code: '38.02.01', sectorCodes: ['38'] },
      { code: '31.02.01', sectorCodes: ['31'] },
      { code: '31.02.03', sectorCodes: ['31'] },
      { code: '43.02.15', sectorCodes: ['43'] },
      { code: '43.01.02', sectorCodes: ['43'] },
      { code: '08.02.01', sectorCodes: ['07'] },
      { code: '15.02.17', sectorCodes: ['08'] },
      { code: '21.02.01', sectorCodes: ['08'] },
      { code: '18.02.08', sectorCodes: ['08'] },
      { code: '23.02.07', sectorCodes: ['08'] },
      { code: '40.02.01', sectorCodes: ['38'] },
      { code: '38.02.04', sectorCodes: ['38'] },
      { code: '43.02.14', sectorCodes: ['43'] },
      { code: '35.02.01', sectorCodes: ['35'] },
      { code: '44.02.01', sectorCodes: ['44'] },
      { code: '13.02.11', sectorCodes: ['08'] },
      { code: '09.02.06', sectorCodes: ['09'] },
      { code: '43.01.09', sectorCodes: ['43'] },
    ];

    let linkedCount = 0;
    for (const mapping of specialtySectorMap) {
      const specId = specialtyIds[mapping.code];
      if (!specId) continue;

      for (const sectorCode of mapping.sectorCodes) {
        const sectorResult = await client.query(`SELECT id FROM sectors WHERE code = $1`, [sectorCode]);
        if (sectorResult.rows.length === 0) continue;
        const sectorId = sectorResult.rows[0].id;

        // Проверяем, существует ли связь
        const existing = await client.query(
          `SELECT 1 FROM specialty_sectors WHERE specialty_id = $1 AND sector_id = $2`,
          [specId, sectorId]
        );
        if (existing.rows.length > 0) continue;

        await client.query(
          `INSERT INTO specialty_sectors (specialty_id, sector_id) VALUES ($1, $2)`,
          [specId, sectorId]
        );
        linkedCount++;
      }
    }
    console.log(`  ✅ Новых связей создано: ${linkedCount}`);

    // ==========================================
    // 8. Связи колледжей со специальностями
    // ==========================================
    console.log('\n🔗 Связываем колледжи со специальностями...');
    const collegeSpecialtiesMap = {
      'Уфимский машиностроительный колледж': ['15.02.08', '15.02.17', '13.02.11', '09.02.06'],
      'Уфимский политехнический колледж': ['09.02.07', '09.02.06', '38.02.01', '38.02.04'],
      'Уфимский торгово-экономический колледж': ['38.02.01', '38.02.04', '43.02.14', '40.02.01'],
      'Уфимский медицинский колледж': ['31.02.01', '31.02.03'],
      'Уфимский колледж предпринимательства, экономики и сервиса': ['43.02.15', '43.01.02', '43.01.09'],
      'Стерлитамакский политехнический колледж': ['08.02.01', '15.02.08', '15.02.17', '23.02.07'],
      'Салаватский индустриальный колледж': ['18.02.08', '15.02.08', '13.02.11'],
      'Нефтекамский машиностроительный колледж': ['15.02.08', '23.02.07', '15.02.17'],
      'Октябрьский нефтяной колледж им. С.И. Кувыкина': ['21.02.01', '13.02.11', '15.02.17'],
      'Уфимский строительный колледж': ['08.02.01'],
    };

    let collegeSpecCount = 0;
    for (const [collegeName, specCodes] of Object.entries(collegeSpecialtiesMap)) {
      const collegeId = collegeIds[collegeName];
      if (!collegeId) { console.log(`  ⚠️ Колледж не найден: ${collegeName}`); continue; }

      for (const code of specCodes) {
        const specId = specialtyIds[code];
        if (!specId) continue;

        const specData = specialtiesData.find(s => s.code === code);
        if (!specData) continue;

        // Проверяем, существует ли связь
        const existing = await client.query(
          `SELECT 1 FROM college_specialties WHERE college_id = $1 AND specialty_id = $2`,
          [collegeId, specId]
        );
        if (existing.rows.length > 0) continue;

        try {
          await client.query(
            `INSERT INTO college_specialties (college_id, specialty_id, budget_places, commercial_places, price_per_year, avg_score, is_active)
             VALUES ($1, $2, $3, $4, $5, $6, true)`,
            [collegeId, specId, specData.budget_places || 0, specData.commercial_places || 0, specData.price_per_year || 0, specData.avg_score_last_year]
          );
          collegeSpecCount++;
        } catch (e) {
          if (e.code !== '23505') throw e;
        }
      }
    }
    console.log(`  ✅ Новых связей колледж-специальность создано: ${collegeSpecCount}`);

    await client.query('COMMIT');
    console.log('\n✅ Заполнение базы данных колледжей Башкортостана завершено!\n');
    console.log('📊 Итоги:');
    console.log(`   - Секторов: ${Object.keys(sectorIds).length}`);
    console.log(`   - Колледжей: ${Object.keys(collegeIds).length}`);
    console.log(`   - Специальностей: ${Object.keys(specialtyIds).length}`);
    console.log(`   - Адресов: ${addressesData.length}`);
    console.log(`   - Связей специальность-сектор: ${linkedCount}`);
    console.log(`   - Связей колледж-специальность: ${collegeSpecCount}`);

    process.exit(0);

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Ошибка при заполнении БД:', error.message);
    if (error.code) console.error('   Код ошибки:', error.code);
    if (error.detail) console.error('   Детали:', error.detail);
    process.exit(1);
  } finally {
    client.release();
  }
};

seed();

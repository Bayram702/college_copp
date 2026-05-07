// server/mail.js — отправка email
const nodemailer = require('nodemailer')

// Создаём транспортёр один раз
const getSmtpConfig = () => ({
  host: (process.env.SMTP_HOST || '').trim(),
  port: parseInt(process.env.SMTP_PORT, 10) || 587,
  secure: process.env.SMTP_SECURE === 'true' || String(process.env.SMTP_PORT || '').trim() === '465',
  user: (process.env.SMTP_USER || '').trim(),
  pass: (process.env.SMTP_PASS || '').trim(),
  from: (process.env.SMTP_FROM || process.env.SMTP_USER || '').trim()
})

const createTransporter = () => {
  const config = getSmtpConfig()

  return nodemailer.createTransport({
    host: config.host,
    port: config.port,
    secure: config.secure,
    auth: config.user && config.pass ? {
      user: config.user,
      pass: config.pass
    } : undefined
  })
}

// Проверка, настроен ли SMTP
const isConfigured = () => {
  const config = getSmtpConfig()
  return !!(config.host && config.from && config.user && config.pass)
}

const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;'
}[char]))

// Отправка email с данными для входа
const sendCredentialsEmail = async (toEmail, name, login, password) => {
  if (!isConfigured()) {
    console.log('⚠️ SMTP не настроен. Данные для входа:')
    console.log(`  👤 Имя: ${name}`)
    console.log(`  🔑 Логин: ${login}`)
    console.log(`  🔒 Пароль: ${password}`)
    return { success: false, reason: 'SMTP not configured' }
  }

  try {
    const portalUrl = process.env.PORTAL_URL || 'http://localhost:5173'
    const config = getSmtpConfig()
    const transporter = createTransporter()

    const info = await transporter.sendMail({
      from: `"Портал колледжей Башкортостана" <${config.from}>`,
      to: toEmail,
      subject: 'Доступ к панели представителя колледжа',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #0054A6;">Здравствуйте, ${name}!</h2>
          <p>Вам предоставлен доступ к панели представителя колледжа на портале колледжей Республики Башкортостан.</p>
          
          <div style="background: #f5f7fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0; color: #1e293b;">Ваши данные для входа:</h3>
            <p><strong>Логин:</strong> <code style="background: #e2e8f0; padding: 4px 8px; border-radius: 4px;">${login}</code></p>
            <p><strong>Пароль:</strong> <code style="background: #e2e8f0; padding: 4px 8px; border-radius: 4px;">${password}</code></p>
          </div>
          
         
          
          
          
          <hr style="border: none; border-top: 1px solid #e1e8ed; margin: 20px 0;">
          <p style="color: #94a3b8; font-size: 0.85rem;">
            Это письмо отправлено автоматически. Пожалуйста, не отвечайте на него.
          </p>
        </div>
      `
    })

    console.log(`✅ Email отправлен на ${toEmail}, messageId: ${info.messageId}`)
    return { success: true, messageId: info.messageId }
  } catch (error) {
    console.error('❌ Ошибка отправки email:', error)
    return {
      success: false,
      error: error.response || error.message,
      code: error.code || null
    }
  }
}

const sendPasswordChangedEmail = async (toEmail, name, login, password) => {
  if (!isConfigured()) {
    console.log('SMTP не настроен. Новый пароль пользователя:')
    console.log(`  Имя: ${name}`)
    console.log(`  Email: ${toEmail}`)
    console.log(`  Логин: ${login}`)
    console.log('  Пароль: не выводится в логах')
    return { success: false, reason: 'SMTP not configured' }
  }

  try {
    const config = getSmtpConfig()
    const transporter = createTransporter()
    const safeName = escapeHtml(name)
    const safeLogin = escapeHtml(login)
    const safePassword = escapeHtml(password)

    const info = await transporter.sendMail({
      from: `"Портал колледжей Башкортостана" <${config.from}>`,
      to: toEmail,
      subject: 'Пароль учетной записи изменен',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #0054A6;">Здравствуйте, ${safeName}!</h2>
          <p>Администратор изменил пароль вашей учетной записи на портале колледжей Республики Башкортостан.</p>
          <div style="background: #f5f7fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
            <h3 style="margin-top: 0; color: #1e293b;">Данные для входа:</h3>
            <p><strong>Логин:</strong> <code style="background: #e2e8f0; padding: 4px 8px; border-radius: 4px;">${safeLogin}</code></p>
            <p><strong>Новый пароль:</strong> <code style="background: #e2e8f0; padding: 4px 8px; border-radius: 4px;">${safePassword}</code></p>
          </div>
          <p>Если вы не ожидали смену пароля, свяжитесь с администратором портала.</p>
          <hr style="border: none; border-top: 1px solid #e1e8ed; margin: 20px 0;">
          <p style="color: #94a3b8; font-size: 0.85rem;">Это письмо отправлено автоматически. Пожалуйста, не отвечайте на него.</p>
        </div>
      `
    })

    console.log(`Email о смене пароля отправлен на ${toEmail}, messageId: ${info.messageId}`)
    return { success: true, messageId: info.messageId }
  } catch (error) {
    console.error('Ошибка отправки email о смене пароля:', error)
    return {
      success: false,
      error: error.response || error.message,
      code: error.code || null
    }
  }
}

const sendPasswordResetCodeEmail = async (toEmail, name, code) => {
  if (!isConfigured()) {
    console.log('⚠️ SMTP не настроен. Код смены пароля:')
    console.log(`  👤 Имя: ${name}`)
    console.log(`  📧 Email: ${toEmail}`)
    console.log(`  🔢 Код: ${code}`)
    return { success: false, reason: 'SMTP not configured' }
  }

  try {
    const config = getSmtpConfig()
    const transporter = createTransporter()

    const info = await transporter.sendMail({
      from: `"Портал колледжей Башкортостана" <${config.from}>`,
      to: toEmail,
      subject: 'Код для смены пароля',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 560px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #0054A6;">Здравствуйте, ${name}!</h2>
          <p>Вы запросили смену пароля в личном кабинете абитуриента.</p>
          <div style="background: #f5f7fa; padding: 18px; border-radius: 8px; margin: 20px 0; text-align: center;">
            <div style="color: #64748b; font-size: 14px; margin-bottom: 8px;">Ваш код подтверждения</div>
            <div style="font-size: 32px; letter-spacing: 8px; font-weight: 700; color: #1e293b;">${code}</div>
          </div>
          <p>Код действует 10 минут. Если вы не запрашивали смену пароля, просто проигнорируйте это письмо.</p>
        </div>
      `
    })

    console.log(`✅ Код смены пароля отправлен на ${toEmail}, messageId: ${info.messageId}`)
    return { success: true, messageId: info.messageId }
  } catch (error) {
    console.error('❌ Ошибка отправки кода смены пароля:', error)
    return {
      success: false,
      error: error.response || error.message,
      code: error.code || null
    }
  }
}

module.exports = { sendCredentialsEmail, sendPasswordChangedEmail, sendPasswordResetCodeEmail, isConfigured }

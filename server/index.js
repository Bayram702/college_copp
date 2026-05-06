// server/index.js
const express = require('express');
const path = require('path');
require('dotenv').config();
const {
  corsMiddleware,
  applySecurityHeaders,
  enforceHttps,
  notFoundHandler,
  errorHandler
} = require('./middleware/security');

const app = express();
const PORT = process.env.PORT || 3000;


app.set('trust proxy', 1);
app.use(enforceHttps);
app.use(applySecurityHeaders);
app.use(corsMiddleware);
app.use(express.json({ limit: '1mb' }));

// Раздаём статические файлы из папки uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Подключаем роуты
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/specialties', require('./routes/specialties'));
app.use('/api/sectors', require('./routes/sectors'));
app.use('/api/settings', require('./routes/settings'));

// API для представителя колледжа (ДО общего /api/colleges!)
app.use('/api/colleges/specialties', require('./routes/rep-specialties'));
app.use('/api/colleges/addresses', require('./routes/rep-addresses'));

// Общий роут колледжей (должен быть ПОСЛЕ специфичных!)
app.use('/api/colleges', require('./routes/colleges'));

// Загрузка изображений для колледжа
app.use('/api/upload', require('./routes/upload'));

app.use('/api', notFoundHandler);
app.use(errorHandler);

app.listen(PORT, () => {
  console.log(`🚀 Сервер запущен на порту ${PORT}`);
});

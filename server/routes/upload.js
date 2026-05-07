const express = require('express');
const router = express.Router();
const upload = require('../middleware/upload');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { publicError } = require('../middleware/security');

const requireCollegeAccess = [requireAuth, requireRole('college_rep', 'admin')];
const requireAdmin = [requireAuth, requireRole('admin')];

// Загрузка изображения для колледжа
router.post('/college-image', requireCollegeAccess, upload.single('image'), async (req, res) => {
  try {
    console.log('📸 POST /api/upload/college-image');
    
    const { imageType } = req.body; // 'logo' или 'main'
    
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'Файл не загружен' });
    }

    if (imageType !== 'logo') {
      return res.status(400).json({ success: false, error: 'Доступна только загрузка логотипа колледжа' });
    }

    // Определяем колледж пользователя
    const collegeId = req.user.collegeId;
    if (!collegeId) {
      return res.status(404).json({ success: false, error: 'Колледж не привязан к пользователю' });
    }

    // Формируем URL для доступа к изображению
    const imageUrl = `/uploads/colleges/${req.uploadedFileName}`;

    // Обновляем соответствующее поле в базе данных
    const fieldName = 'logo_image_url';
    const query = `UPDATE colleges SET ${fieldName} = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id, name`;
    
    const result = await db.query(query, [imageUrl, collegeId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Колледж не найден' });
    }

    console.log(`✅ Изображение загружено: ${fieldName} = ${imageUrl}`);

    res.json({
      success: true,
      message: 'Изображение успешно загружено',
      data: {
        imageUrl: imageUrl,
        imageType: imageType,
        collegeId: collegeId
      }
    });

  } catch (error) {
    console.error('❌ Error uploading college image:', error);
    
    // Если ошибка multer
    if (error instanceof Error) {
      if (error.message.includes('Неподдерживаемый формат')) {
        return res.status(400).json({ success: false, error: error.message });
      }
    }
    
    res.status(500).json({ success: false, error: publicError });
  }
});

router.post('/sector-image', requireAdmin, upload.single('image'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: 'Файл не загружен' });
    }

    const imageUrl = `/uploads/sectors/${req.uploadedFileName}`;

    res.json({
      success: true,
      message: 'Изображение успешно загружено',
      data: {
        imageUrl
      }
    });
  } catch (error) {
    console.error('❌ Error uploading sector image:', error);
    res.status(500).json({ success: false, error: publicError });
  }
});

module.exports = router;

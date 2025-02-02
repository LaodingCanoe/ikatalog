const multer = require('multer'); // Добавьте эту строку
const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const session = require('express-session');
const GOOGLE_CLIENT_ID = "1073151608255-c9kp6sihda6044t47ikoi9mijuv8peps.apps.googleusercontent.com";
const GOOGLE_CLIENT_SECRET = "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";
const app = express();

// Настройка IP-адреса и порта
const serverIp = '172.20.10.14'; // Измените на нужный IP
const port = 3000; // Установите порт для сервера

// Конфигурация сессий
app.use(session({ secret: 'bC7*9Kp@4n^&7zQ%', resave: true, saveUninitialized: true }));

// Инициализация passport
app.use(passport.initialize());
app.use(passport.session());

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.json());

// Настройка хранилища для multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'C:/Users/kakadusha/Downloads/logo'); // Папка для сохранения изображений
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

// Регистрация с загрузкой фотографии
app.post('/register', upload.single('photo'), async (req, res) => {
  const { name, email, password } = req.body;
  const photoPath = req.file ? req.file.filename : null;  // Сохраняем только имя файла


  if (!email || !password) {
    return res.status(400).send('Почта и пароль обязательны');
  }

  try {
    // Сохранение данных в базе
    const pool = await sql.connect(dbConfig);

    await pool.request()
      .input('Name', sql.NVarChar, name)
      .input('Email', sql.NVarChar, email)
      .input('Password', sql.NVarChar, password) // Предположим, пароль уже хэширован
      .input('PhotoPath', sql.NVarChar, photoPath)
      .query(`
        INSERT INTO Пользователи (Имя, Почта, Пароль, Путь_аватара)
        VALUES (@Name, @Email, @Password, @PhotoPath)
      `);

    res.status(201).send({ message: 'Регистрация успешна', photo: photoPath });
  } catch (error) {
    console.error(error);
    res.status(500).send('Ошибка регистрации');
  }
});

// Путь для доступа к загруженным фотографиям
app.use('/images', express.static('C:/Users/kakadusha/Downloads/logo/'));

// Путь к директории с изображениями
const imageDirectory = 'W:/Python/Ramilevich/images';
const UserimageDirectory = 'C:/Users/kakadusha/Downloads/logo';

// Конфигурация базы данных
const dbConfig = {
  user: 'parsuser',
  password: 'Qwerty123',
  server: serverIp, // Использование переменной для IP
  port: 49172,
  database: 'pars',
  options: {
    encrypt: false,
    enableArithAbort: true,
  },
};

// Раздача статичных файлов (изображений) по URL
app.use('/images', express.static(imageDirectory));

// // Настройки Google OAuth
passport.use(new GoogleStrategy({
  clientID: GOOGLE_CLIENT_ID,
  clientSecret: GOOGLE_CLIENT_SECRET,
  callbackURL: `http://${serverIp}:${port}/auth/google/callback`, // Использование переменной для IP
}, async (accessToken, refreshToken, profile, done) => {
  try {
    let pool = await sql.connect(dbConfig);

    const result = await pool.request()
      .input('GoogleId', sql.NVarChar, profile.id)
      .query('SELECT * FROM Пользователи WHERE GoogleId = @GoogleId');

    if (result.recordset.length === 0) {
      await pool.request()
        .input('GoogleId', sql.NVarChar, profile.id)
        .input('Email', sql.NVarChar, profile.emails[0]?.value || null)
        .input('Name', sql.NVarChar, profile.displayName)
        .query(`
          INSERT INTO Пользователи (GoogleId, Почта, Имя)
          VALUES (@GoogleId, @Email, @Name)
        `);
    }

    return done(null, profile);
  } catch (error) {
    console.error(error);
    return done(error);
  }
}));

// Маршрут для начала авторизации с Google
app.get('/auth/google', passport.authenticate('google', {
  scope: ['profile', 'email'],
}));

// Обработчик коллбека Google
app.get('/auth/google/callback', passport.authenticate('google', {
  failureRedirect: '/login', // Страница ошибки при неудачной авторизации
}), (req, res) => {
  res.redirect('/dashboard'); // Редирект после успешного входа
});

// Маршрут для выхода
app.get('/logout', (req, res) => {
  req.logout((err) => {
    if (err) { return next(err); }
    res.redirect('/');
  });
});

// Проверка авторизации пользователя
app.get('/dashboard', (req, res) => {
  if (!req.isAuthenticated()) {
    return res.redirect('/');
  }
  res.send(`Hello, ${req.user.displayName}!`);
});

// Получение списка изображений продукта
app.get('/productImages', async (req, res) => {
  const productId = req.query.productId;

  try {
    let pool = await sql.connect(dbConfig);
    const result = await pool.request()
      .input('ProductId', sql.Int, productId)
      .query(`
        SELECT Путь FROM Изображения WHERE id_Продукта = @ProductId
      `);

    console.log('Product images:', result.recordset);

    const images = result.recordset.map(item => {
      return {
        Путь: `http://${serverIp}:${port}/images/${path.basename(item.Путь)}`
      };
    });

    res.json(images);
  } catch (error) {
    console.error('Error fetching product images:', error);
    res.status(500).send(error.message);
  }
});

app.get('/userImage', async (req, res) => {
  const userId = req.query.userId; // Получаем ID пользователя из запроса

  if (!userId) {
    return res.status(400).json({ error: 'User ID обязателен' });
  }
  app.use('/user_avatars', express.static('C:/Users/kakadusha/Downloads/logo'));

  try {
    // Подключаемся к базе данных
    let pool = await sql.connect(dbConfig);

    const result = await pool.request()
      .input('UserID', sql.Int, userId) // Передаем параметр ID пользователя
      .query(`
        SELECT Путь_аватара 
        FROM Пользователи 
        WHERE id_Пользователя = @UserID
      `);

    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    const avatarPath = result.recordset[0].Путь_аватара;

    if (!avatarPath) {
      return res.status(404).json({ error: 'Аватар не найден' });
    }

    // Формируем ссылку на аватар
    const avatarUrl = `http://${serverIp}:${port}/user_avatars/${path.basename(avatarPath)}`;
    
    res.json({ avatar: avatarUrl });
  } catch (error) {
    console.error('Ошибка получения аватара пользователя:', error);
    res.status(500).json({ error: 'Ошибка сервера при получении аватара' });
  }
});


// Получение списка продуктов с пагинацией
app.get('/products', async (req, res) => {
    const offset = parseInt(req.query.offset) || 0; // Сдвиг
    const limit = parseInt(req.query.limit) || 50; // Количество записей на странице

    try {
        let pool = await sql.connect(dbConfig);
        const result = await pool.request()
            .input('Offset', sql.Int, offset)
            .input('Limit', sql.Int, limit)
            .query(`
                SELECT 
                    p.id_Продукта,
                    p.Название,
                    m.Название AS Модель,
                    s.Название AS Магазин,
                    p.Цена,
                    p.ПЗУ,
                    c.Стандартизированный AS Цвет,
                    p.Оценки,
                    p.[Кол-во_Оценок],
                    p.Ссылка,
                    p.Уценка
                FROM Продукт p
                LEFT JOIN Модель m ON p.Модель = m.id_Модель
                LEFT JOIN Магазин s ON p.Магазин = s.id_Магазин
                LEFT JOIN Цвета c ON p.Цвет = c.id_Цвета
                ORDER BY p.id_Продукта
                OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY
            `);
        res.json(result.recordset);
    } catch (error) {
        res.status(500).send(error.message);
    }
});

// Добавление нового продукта
app.post('/products', async (req, res) => {
  const { name, description, price, colorID, modelID } = req.body;

  try {
    let pool = await sql.connect(dbConfig);
    await pool.request()
      .input('Name', sql.NVarChar, name)
      .input('Description', sql.NVarChar, description)
      .input('Price', sql.Decimal(18, 2), price)
      .input('ColorID', sql.Int, colorID)
      .input('ModelID', sql.Int, modelID)
      .query(`
        INSERT INTO Продукт (Название, Описание, Цена, Цвет, Модель)
        VALUES (@Name, @Description, @Price, @ColorID, @ModelID)
      `);
    res.status(201).send('Product added successfully');
  } catch (error) {
    res.status(500).send(error.message);
  }
});

// Функция для регистрации через почту
const bcrypt = require('bcrypt');
const saltRounds = 10;
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Введите email и пароль' });
  }

  try {
    let pool = await sql.connect(dbConfig);

    const query = `
      SELECT * FROM Пользователи 
      WHERE Почта = @Email
    `;
    const result = await pool.request()
      .input('Email', sql.NVarChar, email)
      .query(query);

    const user = result.recordset[0];

    if (!user) {
      return res.status(404).json({ error: 'Пользователь не найден' });
    }

    if (password !== user.Пароль) {
      return res.status(401).json({ error: 'Неправильный пароль' });
    }

    // Успешный вход
    req.session.user = { 
      id: user.id, 
      name: user.Имя, 
      email: user.Почта,  // Добавляем email
      avatarUrl: user.Путь_аватара || null  // Добавляем avatarUrl, если он есть
    };
    
    // Возвращаем все данные
    res.status(200).json({user: req.session.user });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Ошибка входа на сервер' });
  }
});



app.post('/checkUser', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).send('Email обязателен');
  }

  try {
    let pool = await sql.connect(dbConfig);

    const result = await pool.request()
      .input('Email', sql.NVarChar, email)
      .query('SELECT COUNT(*) AS UserExists FROM Пользователи WHERE Почта = @Email');

    const userExists = result.recordset[0].UserExists > 0;

    res.json({ exists: userExists });
  } catch (error) {
    console.error('Ошибка проверки пользователя:', error);
    res.status(500).send('Ошибка проверки пользователя');
  }
});


// Запуск сервера
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

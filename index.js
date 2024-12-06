const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();

app.use(cors());
app.use(bodyParser.json());

// Путь к директории с изображениями
const imageDirectory = 'W:/Python/Ramilevich/images';

// Конфигурация базы данных
const dbConfig = {
  user: 'parsuser',
  password: 'Qwerty123',
  server: '192.168.0.109',
  port: 49172,
  database: 'pars',
  options: {
    encrypt: false,
    enableArithAbort: true,
  },
};

// Раздача статичных файлов (изображений) по URL
app.use('/images', express.static(imageDirectory));

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
        Путь: `http://192.168.0.109:3000/images/${path.basename(item.Путь)}`
      };
    });

    res.json(images);
  } catch (error) {
    console.error('Error fetching product images:', error);
    res.status(500).send(error.message);
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
      .query(
        `INSERT INTO Продукт (Name, Description, Price, ColorID, ModelID)
         VALUES (@Name, @Description, @Price, @ColorID, @ModelID)`
      );
    res.status(201).send('Product added successfully');
  } catch (error) {
    res.status(500).send(error.message);
  }
});

// Запуск сервера
const port = 3000;
app.listen(port, () => {
  console.log(`API-сервер запущен на порту ${port}`);
});

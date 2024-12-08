import 'package:flutter/material.dart';
import 'image_carousel.dart'; // Подключение библиотеки для карусели
import 'package:http/http.dart' as http;
import 'dart:convert';

class MobileProductList extends StatefulWidget {
  @override
  _MobileProductListState createState() => _MobileProductListState();
}

class _MobileProductListState extends State<MobileProductList> {
  List<dynamic> _products = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.109:3000/products?offset=$_offset&limit=$_limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedProducts = json.decode(response.body);

        setState(() {
          _products.addAll(fetchedProducts);
          _offset += fetchedProducts.length;
          if (fetchedProducts.length < _limit) {
            _hasMore = false;
          }
        });
      } else {
        throw Exception('Не удалось загрузить продукты: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке продуктов: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchProductImages(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.109:3000/productImages?productId=$productId'),
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data.map((item) => item['Путь']));
      } else {
        throw Exception('Failed to fetch images');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Строка поиска
            Container(
              height: 40,
              width: MediaQuery.of(context).size.width * 0.8 , // Уменьшаем ширину
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Image.asset('assets/images/search/standart/android/search.png', width: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Поиск...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Кнопка аккаунта
            IconButton(
              icon: Icon(Icons.account_circle),
              onPressed: () {
                // Логика для кнопки аккаунта
              },
            ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
            _fetchProducts();
          }
          return true;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.43, // Увеличиваем высоту карточки
          ),
          itemCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final product = _products[index];
            final id = product['id_Продукта'] ?? '';
            final name = product['Название'] ?? 'Без названия';
            final store = product['Магазин'] ?? 'Без магазина';
            final rating = (product['Оценки'] is double)
                ? product['Оценки'].toStringAsFixed(1)
                : '0.0';
            final reviews = product['Кол-во_Оценок'] ?? 0;
            final isDiscounted = product['Уценка'] == true;
            final price = product['Цена'] ?? 'Нет данных';

            return Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Карусель изображений
                  Stack(
                    children: [
                      FutureBuilder<List<String>>(
                        future: _fetchProductImages(id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Image.asset(
                              'assets/placeholder.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 150,
                            );
                          } else {
                            return ProductImageCarousel(
                              imageUrls: snapshot.data!, // Увеличиваем высоту карусели
                            );
                          }
                        },
                      ),
                      if (isDiscounted)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF4D7B4A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Уценка',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Цена продукта
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Align(
                      alignment: Alignment.centerLeft, // Цена по левому краю
                      child: Text(
                        '$price ₽',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4D7B4A),
                        ),
                      ),
                    ),
                  ),
                  // Информация о продукте
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          store,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                Text(
                                  rating,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '$reviews отзывов',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Кнопка "В корзину"
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Логика добавления в корзину
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4D7B4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'В корзину',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

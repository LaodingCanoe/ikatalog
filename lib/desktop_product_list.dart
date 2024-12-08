import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
class DesktopProductList extends StatefulWidget {
  @override
  _DesktopProductListState createState() => _DesktopProductListState();
}

class _DesktopProductListState extends State<DesktopProductList> {
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
        title: Text('Список продуктов'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
            _fetchProducts();
          }
          return true;
        },
        child: ListView.builder(
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
            final price = product['Цена'] ?? 0;
            final model = product['Модель'] ?? 'Без модели';
            final store = product['Магазин'] ?? 'Без магазина';
            final discount = product['Уценка'] == true ? 'да' : 'нет';
            final pzu = product['ПЗУ'] ?? 'нет данных';
            final color = product['Цвет'] ?? 'Без цвета';
            final url = product['Ссылка'] ?? '';

            return Card(
              margin: EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  if (url.isNotEmpty && await canLaunch(url)) {
                    await launch(url);
                  }
                },
                child: SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      // Изображение
                      Stack(
                        children: [
                          FutureBuilder<List<String>>(
                            future: _fetchProductImages(id),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return SizedBox(
                                  width: 150,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  width: 150,
                                  child: Image.asset(
                                    'assets/placeholder.png',
                                    fit: BoxFit.contain,
                                  ),
                                );
                              } else {
                                return Container(
                                  width: 150,
                                  height: 200,
                                  child: CarouselSlider(
                                    items: snapshot.data!.map((imagePath) {
                                      return Image.network(imagePath, fit: BoxFit.contain);
                                    }).toList(),
                                    options: CarouselOptions(
                                      height: 200,
                                      autoPlay: true,
                                      enlargeCenterPage: true,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          if (product['Уценка'] == true)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: Color(0xFF4D7B4A),
                                child: Text(
                                  'Уценка',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Описание товара
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 5),
                              Text('Модель: $model', style: TextStyle(color: Colors.black)),
                              Text('Магазин: $store', style: TextStyle(color: Colors.black)),
                              Text('Уценка: $discount', style: TextStyle(color: Colors.black)),
                              Text('Память: $pzu', style: TextStyle(color: Colors.black)),
                              Text('Цвет: $color', style: TextStyle(color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                      // Цена и кнопка
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$price ₽',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4D7B4A),
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Логика добавления в корзину
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4D7B4A), // Цвет кнопки
                              ),
                              child: Text('В корзину', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
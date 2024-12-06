import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MobileLayout extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Future<List<String>> Function(String) fetchProductImages;

  const MobileLayout({
    required this.products,
    required this.fetchProductImages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final id = product['id_Продукта'].toString();
        final name = product['Название'] ?? 'Без названия';
        final price = product['Цена'] ?? 0;
        final model = product['Модель'] ?? 'Без модели';
        final store = product['Магазин'] ?? 'Без магазина';
        final discount = product['Уценка'] == true ? 'да' : 'нет';
        final pzu = product['ПЗУ'] ?? 'нет данных';
        final color = product['Цвет'] ?? 'Без цвета';
        final url = product['Ссылка'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Stack(
                children: [
                  FutureBuilder<List<String>>(
                    future: fetchProductImages(id),
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
                      left: 8,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text('Магазин: $store', style: TextStyle(color: Colors.black)),
                    SizedBox(height: 5),
                    Text('Цвет: $color', style: TextStyle(color: Colors.black)),
                    SizedBox(height: 5),
                    Text('ПЗУ: $pzu', style: TextStyle(color: Colors.black)),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Средняя оценка: 4.5', style: TextStyle(color: Colors.black)),
                        Text('Кол-во оценок: 120', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('Цена: $price ₽', style: TextStyle(fontSize: 18, color: Colors.green)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Логика добавления в корзину
                      },
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                        backgroundColor: Colors.green,
                      ),
                      child: Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

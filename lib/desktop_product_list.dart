import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class DesktopLayout extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Future<List<String>> Function(String) fetchProductImages;

  const DesktopLayout({
    required this.products,
    required this.fetchProductImages,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Отображение двух элементов в строке
        childAspectRatio: 4, // Соотношение сторон для каждого элемента
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: products.length,
      padding: const EdgeInsets.all(16),
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

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Изображение продукта
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
                            height: 200,
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
                          color: Colors.red,
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
                SizedBox(width: 20),
                // Информация о продукте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Магазин: $store'),
                      Text('Цвет: $color'),
                      Text('ПЗУ: $pzu'),
                      SizedBox(height: 8),
                      Text(
                        'Цена: $price ₽',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Логика добавления в корзину
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Добавить в корзину'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

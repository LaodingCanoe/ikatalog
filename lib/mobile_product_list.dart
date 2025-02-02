import 'package:flutter/material.dart';
import 'image_carousel.dart'; // Ensure this is implemented correctly
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'authorization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_list.dart';
import 'configuration.dart';


class MobileProductList extends StatefulWidget {
  MobileProductList({Key? key}) : super(key: key);

  @override
  _MobileProductListState createState() => _MobileProductListState();
}

class _MobileProductListState extends State<MobileProductList> {
  List<dynamic> _products = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 50;
  Map<String, dynamic>? _user; // No longer final, now we manage user state here

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Method to fetch products from the server
  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/products?offset=$_offset&limit=$_limit'),
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
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to fetch product images
  Future<List<String>> _fetchProductImages(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/productImages?productId=$productId'),
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

  // Update user data after successful login
void _updateUser(Map<String, dynamic> newUser) async {
  setState(() {
    _user = newUser; // Update the user data state
  });

  // Save avatar URL to SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('avatarUrl', newUser['avatarUrl'] ?? '');
}
void _loadUserAvatar() async {
  final prefs = await SharedPreferences.getInstance();
  final avatarUrl = prefs.getString('avatarUrl');
  setState(() {
    _user = avatarUrl != null ? {'avatarUrl': avatarUrl} : null;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Search bar
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.7,
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
                          hintText: 'Найти iPhone',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // User avatar or icon
IconButton(
  icon: _user != null && _user!['avatarUrl'] != null
      ? CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(_user!['avatarUrl']),
        )
      : CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/defolt_logo.jpg'),
        ),
  onPressed: () {
    if (_user != null) {
      // Если пользователь авторизован, переходим на экран UserListScreen
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserListScreen(
      onLogout: () {
        setState(() {
          _user = null; // Удаляем данные пользователя из состояния
        });
      },
    ),
  ),
);

    } else {
      // Если пользователь не авторизован, переходим на экран авторизации
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            onLoginSuccess: _updateUser, // Callback для обновления состояния
          ),
        ),
      );
    }
  },
)



          ],
        ),
      ),

      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
            _fetchProducts(); // Fetch more products when scrolled to the bottom
          }
          return true;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.43, // Adjust card height
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
                  // Image carousel
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
                              imageUrls: snapshot.data!, // Use image URLs in carousel
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
                  // Product price
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
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
                  // Product info
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
                  // Add to cart button
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to cart logic
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

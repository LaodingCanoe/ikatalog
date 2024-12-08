import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;

  ApiClient({required this.baseUrl});

  Future<List<dynamic>> fetchProducts(int offset, int limit) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products?offset=$offset&limit=$limit'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch products: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchProductImages(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/productImages?productId=$productId'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data.map((item) => item['Путь']));
    } else {
      throw Exception('Failed to fetch images');
    }
  }
}

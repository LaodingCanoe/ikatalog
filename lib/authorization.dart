import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'register.dart';
import 'configuration.dart';
class AuthScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onLoginSuccess; // Define the callback

  const AuthScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Функция для обработки входа
 Future<void> _login() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/login'), // Адрес вашего API для логина
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      // Парсинг ответа
      final data = json.decode(response.body);

      // Сохранение данных пользователя локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(data));

      // Передаем данные о пользователе в родительский виджет через callback
      widget.onLoginSuccess(data);  // Call the callback when login is successful

      // Переход на предыдущую страницу
      Navigator.pop(context); // This will return to the previous screen
    } else {
      // Ошибка авторизации
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка входа: ${response.body}')),
      );
    }
  } catch (e) {
    // Обработка ошибки
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка: $e')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  // Функция для перехода на страницу восстановления пароля
  void _forgotPassword() {
    // Открытие экрана восстановления пароля
    // Navigator.pushNamed(context, '/forgot-password');
  }

  // Переход на экран регистрации
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Авторизация')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Поле для ввода email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Поле для ввода пароля
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            // Кнопка "Войти"
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : Text('Войти'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // На всю ширину
              ),
            ),
            SizedBox(height: 8),
            // Кнопка "Забыл пароль"
            TextButton(
              onPressed: _forgotPassword,
              child: Text('Забыл пароль?'),
            ),
            SizedBox(height: 16),
            // Текст с ссылкой на страницу регистрации
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ещё нет аккаунта? '),
                GestureDetector(
                  onTap: _goToRegister,
                  child: Text(
                    'Регистрация',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class UserListScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const UserListScreen({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  Map<String, dynamic> user = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        user = json.decode(userString);
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user'); // Удаляем данные пользователя

    widget.onLogout(); // Вызываем callback для обновления состояния
    Navigator.pop(context); // Возвращаемся на предыдущий экран
  }

  Future<void> _printSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  final userString = prefs.getString('user');
  if (userString != null) {
    print('user: $userString');
  } else {
    print('Нет данных пользователя');
  }
}


  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['avatarUrl'] ?? 'assets/defolt_logo.jpg';
    final userName = user['name'] ?? 'Имя не указано';
    final userEmail = user['email'] ?? 'Email не указан';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль пользователя'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Фотография пользователя
            CircleAvatar(
  radius: 50,
  backgroundImage: avatarUrl.startsWith('http')
      ? NetworkImage(avatarUrl)  // Загрузка аватара с сервера
      : AssetImage(avatarUrl) as ImageProvider, // Локальное изображение по умолчанию
),

            const SizedBox(height: 16),
            // Имя пользователя
            Text(
              userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Почта пользователя
            Text(
              userEmail,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Кнопка "Выход"
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Выйти',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: _printSharedPreferences,
              child: const Text('Просмотреть данные'),
            ),
          ],
        ),
      ),
    );
  }
}

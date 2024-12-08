import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart'; // Импортируем ваш файл

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(), // Используем виджет из BottomNavigationBar.dart
    );
  }
}

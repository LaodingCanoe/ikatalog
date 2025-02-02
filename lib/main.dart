import 'package:flutter/foundation.dart'; // Для определения платформы
import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart'; // Импортируем ваш файл
import 'desktop_product_list.dart'; // Подключаем DesktopProductList

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _getHomePage(), // Определяем стартовую страницу
    );
  }

  Widget _getHomePage() {
    // Проверяем платформу
    if (kIsWeb) {
      // Для Web выбираем DesktopProductList
      return DesktopProductList();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return MyHomePage(); // Для мобильных устройств
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return DesktopProductList(); // Для ПК
      default:
        return MyHomePage(); // По умолчанию мобильная версия
    }
  }
}

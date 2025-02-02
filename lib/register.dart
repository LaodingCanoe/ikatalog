import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'dart:io';
import 'configuration.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  XFile? _image;
  String? _errorMessage; // Для сообщений об ошибках

  // Проверка корректности email
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(email);
  }

  // Проверка корректности пароля
  bool _isPasswordValid(String password) {
    final passwordRegex = RegExp(r'^(?=.*[0-9]).{6,}$');
    return passwordRegex.hasMatch(password);
  }

  // Проверка, существует ли пользователь
  Future<bool> _isUserExists(String email) async {
    final response = await http.post(
      Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/checkUser'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['exists'] == true;
    }
    return false;
  }

  // Регистрация с email
  Future<void> _registerWithEmail() async {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // Валидация данных
    if (!_isEmailValid(email)) {
      setState(() {
        _errorMessage = 'Некорректный адрес электронной почты.';
      });
      return;
    }
    if (!_isPasswordValid(password)) {
      setState(() {
        _errorMessage = 'Пароль должен содержать не менее 6 символов и хотя бы одну цифру.';
      });
      return;
    }
    if (await _isUserExists(email)) {
      setState(() {
        _errorMessage = 'Пользователь с такой почтой уже зарегистрирован.';
      });
      return;
    }

    final uri = Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/register');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;

    if (_image != null) {
      final file = File(_image!.path);
      request.files.add(
        http.MultipartFile(
          'photo',
          file.readAsBytes().asStream(),
          file.lengthSync(),
          filename: file.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Регистрация успешна')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка регистрации')));
    }
  }

  // Выбор изображения
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
              SizedBox(height: 16),
            ],
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _image != null ? FileImage(File(_image!.path)) : null,
                child: _image == null
                    ? Icon(Icons.add_a_photo, size: 40, color: Colors.grey[700])
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Почта',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _registerWithEmail,
              child: Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}

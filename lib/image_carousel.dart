import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  ProductImageCarousel({required this.imageUrls});

  @override
  _ProductImageCarouselState createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final double imageSize = MediaQuery.of(context).size.width * 0.6; // Размер квадрата (60% ширины экрана)

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index, _) {
            return Container(
              width: imageSize,
              height: imageSize,
              color: Color(0xFFF6F5F3), // Фон для изображения
              alignment: Alignment.center,
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain, // Сохраняет пропорции изображения
                width: imageSize,
                height: imageSize,
              ),
            );
          },
          options: CarouselOptions(
            height: imageSize, // Фиксированная высота карусели
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        // Индикатор текущего изображения
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.imageUrls.map((url) {
              final index = widget.imageUrls.indexOf(url);
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Color(0xFF4D7B4A) : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

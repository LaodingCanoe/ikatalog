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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // Для мобильных устройств
          if (isMobile)
            CarouselSlider.builder(
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index, _) {
                return Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          // Для ПК
          if (!isMobile)
            MouseRegion(
              onHover: (event) {
                final width = MediaQuery.of(context).size.width;
                final sectionWidth = width / widget.imageUrls.length;
                setState(() {
                  _currentIndex = (event.localPosition.dx / sectionWidth).floor();
                });
              },
              child: Image.network(
                widget.imageUrls[_currentIndex],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          // Индикатор страниц
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
                    color: _currentIndex == index ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

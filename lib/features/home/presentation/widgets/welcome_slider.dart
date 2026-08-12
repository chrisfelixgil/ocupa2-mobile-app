import 'dart:async';

import 'package:flutter/material.dart';

class WelcomeSlider extends StatefulWidget {
  const WelcomeSlider({
    super.key,
  });

  @override
  State<WelcomeSlider> createState() {
    return _WelcomeSliderState();
  }
}

class _WelcomeSliderState extends State<WelcomeSlider> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  Timer? _timer;

  final List<String> _images = const [
    'assets/images/home/welcome_1.jpg',
    'assets/images/home/welcome_2.jpg',
    'assets/images/home/welcome_3.jpg',
    'assets/images/home/welcome_4.jpg',
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        _nextPage();
      },
    );
  }

  void _nextPage() {
    if (!_pageController.hasClients) {
      return;
    }

    final int nextPage = (_currentPage + 1) % _images.length;

    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    if (!_pageController.hasClients) {
      return;
    }

    final int previousPage =
        (_currentPage - 1 + _images.length) % _images.length;

    _pageController.animateToPage(
      previousPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        _images[index],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // Flecha izquierda
              Positioned(
                left: 24,
                child: IconButton.filled(
                  onPressed: _previousPage,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                ),
              ),

              // Flecha derecha
              Positioned(
                right: 24,
                child: IconButton.filled(
                  onPressed: _nextPage,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) {
              final bool selected = _currentPage == index;

              return AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                width: selected ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
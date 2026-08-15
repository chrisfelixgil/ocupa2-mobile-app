import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';

class WelcomeSlider extends StatefulWidget {
  const WelcomeSlider({super.key});

  @override
  State<WelcomeSlider> createState() {
    return _WelcomeSliderState();
  }
}

class _WelcomeSliderState extends State<WelcomeSlider> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  Timer? _timer;

  final List<String> _images = const <String>[
    'assets/images/home/banner_1.png',
    'assets/images/home/banner_2.png',
    'assets/images/home/banner_3.png',
    'assets/images/home/banner_4.png',
  ];

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _nextPage();
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (BuildContext context, int index) {
                  return Image.asset(
                    _images[index],
                    fit: BoxFit.cover,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const ColoredBox(color: AppColors.border);
                        },
                  );
                },
              ),
              const ColoredBox(color: Color(0xBF0F172A)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Trabajos en tu zona',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Explora trabajos disponibles en tu comunidad',
                      style: TextStyle(color: AppColors.border, fontSize: 12),
                    ),
                    const Spacer(),
                    Row(
                      children: List<Widget>.generate(_images.length, (
                        int index,
                      ) {
                        final bool selected = _currentPage == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 4),
                          width: selected ? 14 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.surface
                                : AppColors.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

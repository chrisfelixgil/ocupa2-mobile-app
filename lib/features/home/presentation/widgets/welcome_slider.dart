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

  final List<String> _images = const [
    'assets/images/home/welcome_1.png',
    'assets/images/home/welcome_2.png',
    'assets/images/home/welcome_3.png',
    'assets/images/home/welcome_4.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
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
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _images.length,
            (index) {
              final selected = _currentPage == index;

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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_status.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/news_section.dart';
import '../widgets/videos_section.dart';
import '../widgets/welcome_slider.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  @override
  State<HomeView> createState() {
    return _HomeViewState();
  }
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ocupa2',
        ),
        centerTitle: true,
      ),
      body: Consumer<HomeViewModel>(
        builder: (
          context,
          viewModel,
          child,
        ) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 40,
              ),
              children: [
                const WelcomeSlider(),

                const SizedBox(height: 32),

                _SectionTitle(
                  icon: Icons.newspaper_outlined,
                  title: 'Noticias de empleo',
                ),

                const SizedBox(height: 12),

                if (viewModel.status == HomeStatus.loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (viewModel.status == HomeStatus.error)
                  _ErrorMessage(
                    message:
                        viewModel.errorMessage ??
                        'Ocurrió un error.',
                    onRetry: viewModel.loadHome,
                  )
                else ...[
                  NewsSection(
                    news: viewModel.news,
                  ),

                  const SizedBox(height: 28),

                  _SectionTitle(
                    icon: Icons.play_circle_outline,
                    title: 'Videos educativos',
                  ),

                  const SizedBox(height: 12),

                  VideosSection(
                    videos: viewModel.videos,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorMessage({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 45,
          ),

          const SizedBox(height: 12),

          Text(
            message,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Intentar nuevamente',
            ),
          ),
        ],
      ),
    );
  }
}

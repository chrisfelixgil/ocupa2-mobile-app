import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:provider/provider.dart';

import '../viewmodels/home_status.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/news_section.dart';
import '../widgets/videos_section.dart';
import '../widgets/welcome_slider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

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
        title: const Text('Ocupa2'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menú',
            icon: const Icon(Icons.menu_rounded),

            onSelected: (String value) {
              switch (value) {
                case 'offers':
                  context.pushNamed(
                    AppRouteNames.jobSearchExplore,
                  );
                  break;

                case 'myOffers':
                  context.pushNamed(
                    AppRouteNames.jobPostingMyOffers,
                  );
                  break;

                case 'experiences':
                  context.pushNamed(
                    AppRouteNames.myExperiences,
                  );
                  break;

                case 'applications':
                  context.pushNamed(
                    AppRouteNames.myApplications,
                  );
                  break;

                case 'contracts':
                  context.pushNamed(
                    AppRouteNames.myContracts,
                  );
                  break;

                case 'myPayments':
                  context.pushNamed(
                    AppRouteNames.paymentsMyPayments,
                  );
                  break;

                case 'changePassword':
                  context.pushNamed(
                    AppRouteNames.changePassword,
                  );
                  break;

                case 'about':
                  context.pushNamed(
                    AppRouteNames.about,
                  );
                  break;
              }
            },

            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(
                value: 'offers',
                child: ListTile(
                  leading: Icon(
                    Icons.travel_explore_rounded,
                  ),
                  title: Text(
                    'Explorar ofertas',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'myOffers',
                child: ListTile(
                  leading: Icon(
                    Icons.campaign_outlined,
                  ),
                  title: Text(
                    'Mis ofertas',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'experiences',
                child: ListTile(
                  leading: Icon(
                    Icons.work_history_outlined,
                  ),
                  title: Text(
                    'Mis experiencias',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'applications',
                child: ListTile(
                  leading: Icon(
                    Icons.assignment_outlined,
                  ),
                  title: Text(
                    'Mis aplicaciones',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'contracts',
                child: ListTile(
                  leading: Icon(
                    Icons.description_rounded,
                  ),
                  title: Text(
                    'Mis contratos',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'myPayments',
                child: ListTile(
                  leading: Icon(
                    Icons.payments_outlined,
                  ),
                  title: Text(
                    'Mis pagos',
                  ),
                ),
              ),

              PopupMenuDivider(),

              PopupMenuItem<String>(
                value: 'changePassword',
                child: ListTile(
                  leading: Icon(
                    Icons.password_rounded,
                  ),
                  title: Text(
                    'Cambiar contraseña',
                  ),
                ),
              ),

              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline_rounded,
                  ),
                  title: Text(
                    'Acerca de',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 8),
        ],
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
            color: Theme.of(
              context,
            ).colorScheme.primary,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,

              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
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
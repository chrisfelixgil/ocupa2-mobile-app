import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/core/widgets/app_bottom_nav.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/home/data/models/educational_video.dart';
import 'package:ocupa2/features/home/data/models/news.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../viewmodels/home_status.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/welcome_slider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() {
    return _HomeViewState();
  }
}

class _HomeViewState extends State<HomeView> {
  bool _showAllNews = false;
  bool _showAllVideos = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<HomeViewModel>().loadHome();

      final ExploreOffersViewModel offersViewModel = context
          .read<ExploreOffersViewModel>();

      if (offersViewModel.offers.isEmpty && !offersViewModel.isLoading) {
        offersViewModel.load();
      }
    });
  }

  Future<void> _refresh(HomeViewModel viewModel) async {
    await viewModel.refresh();
    if (!mounted) {
      return;
    }
    await context.read<ExploreOffersViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<SessionViewModel>().user;
    final String firstName = (user?.firstName ?? '').trim();
    final String greeting = firstName.isEmpty ? 'Hola 👋' : 'Hola, $firstName 👋';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Consumer<HomeViewModel>(
          builder: (BuildContext context, HomeViewModel viewModel, Widget? child) {
            final ExploreOffersViewModel offersViewModel = context
                .watch<ExploreOffersViewModel>();
            final List<Offer> recentOffers = offersViewModel.offers
                .take(5)
                .toList();

            return RefreshIndicator(
              onRefresh: () {
                return _refresh(viewModel);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Ocupa2',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          greeting,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const Text(
                          '¿Qué necesitas hoy?',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.search,
                            title: 'Buscar trabajo',
                            subtitle: 'Encuentra ofertas cerca',
                            onTap: () {
                              context.pushNamed(AppRouteNames.jobSearchExplore);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add,
                            title: 'Publicar trabajo',
                            subtitle: 'Encuentra a la persona indicada',
                            onTap: () {
                              context.pushNamed(AppRouteNames.jobPostingCreate);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const WelcomeSlider(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Oportunidades recientes',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushNamed(AppRouteNames.jobSearchExplore);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.link,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (recentOffers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Aún no hay ofertas para mostrar.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    _RecentOffersSlider(offers: recentOffers),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Noticias y consejos',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (viewModel.status == HomeStatus.loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (viewModel.status == HomeStatus.error)
                    _ErrorMessage(
                      message: viewModel.errorMessage ?? 'Ocurrió un error.',
                      onRetry: viewModel.loadHome,
                    )
                  else ...<Widget>[
                    ...(_showAllNews ? viewModel.news : viewModel.news.take(2))
                        .map((News item) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: _NewsRow(news: item),
                          );
                        }),
                    if (viewModel.news.length > 2)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllNews = !_showAllNews;
                            });
                          },
                          child: Text(_showAllNews ? 'Ver menos' : 'Ver más'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Videos educativos',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_showAllVideos
                            ? viewModel.videos
                            : viewModel.videos.take(2))
                        .map((EducationalVideo video) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: _VideoRow(video: video),
                          );
                        }),
                    if (viewModel.videos.length > 2)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllVideos = !_showAllVideos;
                            });
                          },
                          child: Text(
                            _showAllVideos ? 'Ver menos' : 'Ver más',
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selected: AppBottomNavTab.home),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentOffersSlider extends StatelessWidget {
  const _RecentOffersSlider({required this.offers});

  static const double _cardSize = 200;

  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (BuildContext context, int index) {
          final Offer offer = offers[index];

          return _RecentOfferCard(
            offer: offer,
            accent: index.isOdd ? AppColors.success : AppColors.primary,
            onTap: () {
              context.pushNamed(
                AppRouteNames.jobSearchOfferDetail,
                pathParameters: <String, String>{'id': offer.id},
              );
            },
          );
        },
      ),
    );
  }
}

class _RecentOfferCard extends StatelessWidget {
  const _RecentOfferCard({
    required this.offer,
    required this.accent,
    required this.onTap,
  });

  final Offer offer;
  final Color accent;
  final VoidCallback onTap;

  String get _payLabel {
    if (offer.paymentAmount == null) {
      return 'A convenir';
    }

    final String amount = offer.paymentAmount!.round().toString();
    final String currency = (offer.paymentCurrency ?? 'DOP').toUpperCase();

    if (currency == 'DOP' || currency == 'RD' || currency == 'RD\$') {
      return 'RD\$$amount';
    }

    return '$currency $amount';
  }

  String get _contractLabel {
    switch (offer.contractType.toLowerCase()) {
      case 'temporal':
        return 'Temporal';
      case 'horas':
        return 'Por horas';
      default:
        return offer.contractType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer.displayJobType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _payLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  offer.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.text,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _contractLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ver oferta',
                      style: TextStyle(
                        color: AppColors.link,
                        fontSize: 11,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.news});

  final News news;

  String get _meta {
    final String source = news.source.isEmpty ? 'Ocupa2' : news.source;
    final DateTime? date = news.date;

    if (date == null) {
      return source;
    }

    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${date.day} ${months[date.month - 1]} · $source';
  }

  Future<void> _open() async {
    if (news.url.isEmpty) {
      return;
    }

    final Uri? uri = Uri.tryParse(news.url);

    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: news.image.isEmpty
                      ? const ColoredBox(
                          color: AppColors.border,
                          child: Icon(Icons.article_outlined),
                        )
                      : CachedNetworkImage(
                          imageUrl: news.image,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) {
                            return const ColoredBox(
                              color: AppColors.border,
                              child: Icon(Icons.broken_image_outlined),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _meta,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                      ),
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

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.video});

  final EducationalVideo video;

  Future<void> _open() async {
    if (video.url.isEmpty) {
      return;
    }

    final Uri? uri = Uri.tryParse(video.url);

    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: video.thumbnail.isEmpty
                      ? const ColoredBox(
                          color: AppColors.border,
                          child: Icon(Icons.play_circle_outline),
                        )
                      : CachedNetworkImage(
                          imageUrl: video.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) {
                            return const ColoredBox(
                              color: AppColors.border,
                              child: Icon(Icons.videocam_off_outlined),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          const Icon(Icons.error_outline, size: 45),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    );
  }
}

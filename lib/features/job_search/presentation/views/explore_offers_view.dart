import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/catalog/data/models/job_type.dart';
import 'package:ocupa2/features/catalog/data/repositories/catalog_repository.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_status.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/offer_card.dart';
import 'package:provider/provider.dart';

const List<MapEntry<String, String>> _contractTypes =
    <MapEntry<String, String>>[
      MapEntry<String, String>('temporal', 'Temporal'),
      MapEntry<String, String>('fijo', 'Fijo'),
      MapEntry<String, String>('horas', 'Por horas'),
    ];

class ExploreOffersView extends StatefulWidget {
  const ExploreOffersView({super.key});

  @override
  State<ExploreOffersView> createState() => _ExploreOffersViewState();
}

class _ExploreOffersViewState extends State<ExploreOffersView> {
  final TextEditingController _searchController = TextEditingController();
  List<JobType> _jobTypes = const <JobType>[];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await context.read<ExploreOffersViewModel>().load();

      if (!mounted) {
        return;
      }

      try {
        final List<JobType> jobTypes = await context
            .read<CatalogRepository>()
            .getJobTypes();

        if (mounted) {
          setState(() {
            _jobTypes = jobTypes;
          });
        }
      } catch (_) {
        // El filtro por tipo de trabajo es una mejora de UX: si el catálogo
        // no carga, seguimos mostrando la lista de ofertas sin bloquear.
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Offer> _visibleOffers(List<Offer> offers) {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return offers;
    }

    return offers.where((Offer offer) {
      return offer.description.toLowerCase().contains(query) ||
          offer.address.toLowerCase().contains(query) ||
          offer.displayJobType.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ExploreOffersViewModel viewModel = context
        .watch<ExploreOffersViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Encuentra trabajo',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () {
                            context.pushNamed(AppRouteNames.jobSearchMap);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.map_outlined,
                              size: 18,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar oportunidades...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChipRow(
                    children: <Widget>[
                      _FilterChip(
                        label: 'Todos',
                        selected: viewModel.contractTypeFilter == null,
                        onTap: () {
                          viewModel.setContractTypeFilter(null);
                        },
                      ),
                      ..._contractTypes.map((MapEntry<String, String> item) {
                        return _FilterChip(
                          label: item.value,
                          selected: viewModel.contractTypeFilter == item.key,
                          onTap: () {
                            viewModel.setContractTypeFilter(item.key);
                          },
                        );
                      }),
                    ],
                  ),
                  if (_jobTypes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    _ChipRow(
                      children: <Widget>[
                        _FilterChip(
                          label: 'Todos los oficios',
                          selected: viewModel.jobTypeFilter == null,
                          onTap: () {
                            viewModel.setJobTypeFilter(null);
                          },
                        ),
                        ..._jobTypes.map((JobType jobType) {
                          return _FilterChip(
                            label: jobType.label,
                            selected: viewModel.jobTypeFilter == jobType.key,
                            onTap: () {
                              viewModel.setJobTypeFilter(jobType.key);
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _Body(
                viewModel: viewModel,
                offers: _visibleOffers(viewModel.offers),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ExploreBottomNav(),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.onPrimary : AppColors.text,
              fontSize: 12,
              fontWeight: selected
                  ? AppTypography.medium
                  : AppTypography.regular,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.viewModel,
    required this.offers,
  });

  final ExploreOffersViewModel viewModel;
  final List<Offer> offers;

  @override
  Widget build(BuildContext context) {
    return switch (viewModel.status) {
      ExploreOffersStatus.idle || ExploreOffersStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ExploreOffersStatus.error => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(viewModel.errorMessage ?? 'Ocurrió un error.'),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: viewModel.load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      ExploreOffersStatus.success => _buildOffersList(context),
    };
  }

  Widget _buildOffersList(BuildContext context) {
    if (viewModel.offers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                viewModel.hiddenOwnCount > 0
                    ? 'No hay ofertas de otros usuarios por ahora.\n'
                        'Tus ${viewModel.hiddenOwnCount} publicaciones no se muestran aquí porque son tuyas.'
                    : 'No hay ofertas disponibles por ahora.',
                textAlign: TextAlign.center,
              ),
              if (viewModel.hiddenOwnCount > 0) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () {
                    context.goNamed(AppRouteNames.jobPostingMyOffers);
                  },
                  child: const Text('Ver mis publicaciones'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (offers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No hay ofertas que coincidan con tu búsqueda.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Offer offer = offers[index];

          return OfferCard(
            offer: offer,
            onTap: () async {
              final Object? applied = await context.pushNamed(
                AppRouteNames.jobSearchOfferDetail,
                pathParameters: <String, String>{'id': offer.id},
              );

              if (!context.mounted) {
                return;
              }

              if (applied == true) {
                viewModel.hideOffer(offer.id);
              }

              await viewModel.load();
            },
          );
        },
      ),
    );
  }
}

class _ExploreBottomNav extends StatelessWidget {
  const _ExploreBottomNav();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () {
                  context.goNamed(AppRouteNames.home);
                },
              ),
              const _NavItem(
                icon: Icons.search,
                label: 'Explorar',
                selected: true,
              ),
              _NavItem(
                icon: Icons.add,
                label: 'Publicar',
                prominent: true,
                onTap: () {
                  context.pushNamed(AppRouteNames.jobPostingCreate);
                },
              ),
              _NavItem(
                icon: Icons.history,
                label: 'Actividad',
                onTap: () {
                  context.pushNamed(AppRouteNames.activityHub);
                },
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () {
                  context.pushNamed(AppRouteNames.profile);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.prominent = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool prominent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primary : AppColors.text;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (prominent)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: AppColors.primary),
              )
            else
              Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected
                    ? AppTypography.medium
                    : AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

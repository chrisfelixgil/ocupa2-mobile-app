import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/catalog/data/models/job_type.dart';
import 'package:ocupa2/features/catalog/data/repositories/catalog_repository.dart';
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
  List<JobType> _jobTypes = const <JobType>[];

  @override
  void initState() {
    super.initState();

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
  Widget build(BuildContext context) {
    final ExploreOffersViewModel viewModel = context
        .watch<ExploreOffersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar ofertas'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Ver en el mapa',
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              context.pushNamed(AppRouteNames.jobSearchMap);
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _Filters(
            jobTypes: _jobTypes,
            selectedJobTypeKey: viewModel.jobTypeFilter,
            selectedContractType: viewModel.contractTypeFilter,
            onJobTypeChanged: viewModel.setJobTypeFilter,
            onContractTypeChanged: viewModel.setContractTypeFilter,
          ),
          Expanded(child: _Body(viewModel: viewModel)),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.jobTypes,
    required this.selectedJobTypeKey,
    required this.selectedContractType,
    required this.onJobTypeChanged,
    required this.onContractTypeChanged,
  });

  final List<JobType> jobTypes;
  final String? selectedJobTypeKey;
  final String? selectedContractType;
  final ValueChanged<String?> onJobTypeChanged;
  final ValueChanged<String?> onContractTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            _FilterDropdown<String?>(
              hint: 'Tipo de trabajo',
              value: selectedJobTypeKey,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(child: Text('Todos')),
                ...jobTypes.map((JobType jobType) {
                  return DropdownMenuItem<String?>(
                    value: jobType.key,
                    child: Text(jobType.label),
                  );
                }),
              ],
              onChanged: onJobTypeChanged,
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterDropdown<String?>(
              hint: 'Contrato',
              value: selectedContractType,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(child: Text('Todos')),
                ..._contractTypes.map((MapEntry<String, String> item) {
                  return DropdownMenuItem<String?>(
                    value: item.key,
                    child: Text(item.value),
                  );
                }),
              ],
              onChanged: onContractTypeChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          hint: Text(hint),
          value: value,
          items: items,
          onChanged: (T? newValue) {
            onChanged(newValue as T);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel});

  final ExploreOffersViewModel viewModel;

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

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: viewModel.offers.length,
        itemBuilder: (BuildContext context, int index) {
          final offer = viewModel.offers[index];

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

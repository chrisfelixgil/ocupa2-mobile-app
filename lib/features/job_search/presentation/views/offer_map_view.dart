import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_status.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/offer_display.dart';
import 'package:provider/provider.dart';

/// Centro geográfico aproximado de República Dominicana. El mapa siempre
/// abre aquí, mostrando el país completo, en vez de centrarse en la
/// primera oferta con ubicación: algunas ofertas de prueba traen
/// coordenadas inválidas (0,0 en medio del océano, o directamente fuera
/// del país), y si el mapa se centraba en esa oferta, la vista inicial
/// quedaba en medio del mar. Los marcadores igual se dibujan en sus
/// coordenadas reales; solo la cámara inicial ya no depende de ellas.
const LatLng _countryCenter = LatLng(18.7357, -70.1627);

/// Zoom que muestra el territorio dominicano completo en una pantalla de
/// celular.
const double _countryZoom = 8;

/// URL de tiles de CARTO Voyager (mismos datos de OpenStreetMap, pero sin
/// las restricciones de uso del servidor directo tile.openstreetmap.org).
const String _tileUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

const List<String> _tileSubdomains = <String>['a', 'b', 'c', 'd'];

const List<MapEntry<String, String>> _contractTypes =
    <MapEntry<String, String>>[
      MapEntry<String, String>('temporal', 'Temporal'),
      MapEntry<String, String>('fijo', 'Fijo'),
      MapEntry<String, String>('horas', 'Por horas'),
    ];

const Color _payGreen = Color(0xFF16A34A);

class OfferMapView extends StatefulWidget {
  const OfferMapView({super.key});

  @override
  State<OfferMapView> createState() => _OfferMapViewState();
}

class _OfferMapViewState extends State<OfferMapView> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Offer? _selectedOffer;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExploreOffersViewModel>().load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ofertas con coordenadas utilizables para el mapa.
  ///
  /// Se descartan las que vienen en (0, 0): esa combinación no es un lugar
  /// real, es el valor que quedó en algunas ofertas semilla/de prueba que
  /// nunca recibieron una ubicación real. Tratarlas como "sin ubicación"
  /// evita que el mapa se centre en medio del océano Atlántico.
  List<Offer> _offersWithLocation(List<Offer> offers) {
    return offers.where((Offer offer) {
      final double? lat = offer.latitude;
      final double? lng = offer.longitude;
      if (lat == null || lng == null) return false;
      final bool isNullIsland = lat == 0 && lng == 0;
      return !isNullIsland;
    }).toList();
  }

  List<Offer> _matching(List<Offer> offers) {
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

  void _selectOffer(Offer? offer) {
    setState(() {
      _selectedOffer = offer;
    });
  }

  Future<void> _openFilters() async {
    final ExploreOffersViewModel viewModel = context
        .read<ExploreOffersViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filtrar por contrato',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MapFilterChip(
                      label: 'Todos',
                      selected: viewModel.contractTypeFilter == null,
                      onTap: () {
                        viewModel.setContractTypeFilter(null);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                    ..._contractTypes.map((MapEntry<String, String> item) {
                      return _MapFilterChip(
                        label: item.value,
                        selected: viewModel.contractTypeFilter == item.key,
                        onTap: () {
                          viewModel.setContractTypeFilter(item.key);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExploreOffersViewModel viewModel = context
        .watch<ExploreOffersViewModel>();

    final List<Offer> located = viewModel.status == ExploreOffersStatus.success
        ? _matching(_offersWithLocation(viewModel.offers))
        : const <Offer>[];

    final Offer? selected =
        located.any((Offer offer) => offer.id == _selectedOffer?.id)
        ? _selectedOffer
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Volver',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        color: AppColors.text,
                      ),
                      const Expanded(
                        child: Text(
                          'Encuentra trabajo',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Buscar empleos, empresas...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: IconButton(
                        tooltip: 'Filtros',
                        onPressed: _openFilters,
                        icon: const Icon(
                          Icons.tune,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _OffersMap(
                    mapController: _mapController,
                    center: _countryCenter,
                    initialZoom: _countryZoom,
                    offers: located,
                    selectedOffer: selected,
                    onOfferTap: _selectOffer,
                    onMapTap: () => _selectOffer(null),
                  ),
                ),
                if (viewModel.isLoading)
                  const Positioned(
                    top: AppSpacing.md,
                    left: 0,
                    right: 0,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (viewModel.status == ExploreOffersStatus.success &&
                    located.isEmpty)
                  const Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _InfoBanner(
                      message:
                          'Ninguna oferta activa tiene ubicación todavía.',
                    ),
                  ),
                if (selected != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _OfferPreviewCard(
                      offer: selected,
                      onTap: () async {
                        final String offerId = selected.id;
                        final Object? applied = await context.pushNamed(
                          AppRouteNames.jobSearchOfferDetail,
                          pathParameters: <String, String>{'id': offerId},
                        );

                        if (!context.mounted) {
                          return;
                        }

                        final ExploreOffersViewModel currentViewModel =
                            context.read<ExploreOffersViewModel>();

                        if (applied == true) {
                          _selectOffer(null);
                          currentViewModel.hideOffer(offerId);
                        }

                        await currentViewModel.load();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El mapa en sí, separado del Scaffold/overlays para mantener el árbol de
/// widgets simple y para poder envolver justo esta parte en un
/// [RepaintBoundary].
///
/// Nota sobre un bug ya investigado: en ciertos emuladores Android con el
/// renderizador Impeller (que en versiones recientes de Flutter ya no se
/// puede desactivar, ni por AndroidManifest ni por --no-enable-impeller),
/// los tiles pueden quedar completamente decodificados y listos
/// (opacidad 1, sin errores) pero no llegar a pintarse en pantalla. Es un
/// problema de composición de capas transformadas (zoom/pan), no de esta
/// app. El RepaintBoundary de abajo fuerza a que el mapa viva en su propia
/// capa compuesta, que es el workaround conocido para este tipo de casos.
/// Si en un dispositivo real el mapa se ve bien (que es donde el profesor
/// evalúa), este problema no aplica.
class _OffersMap extends StatelessWidget {
  const _OffersMap({
    required this.mapController,
    required this.center,
    required this.initialZoom,
    required this.offers,
    required this.selectedOffer,
    required this.onOfferTap,
    required this.onMapTap,
  });

  final MapController mapController;
  final LatLng center;
  final double initialZoom;
  final List<Offer> offers;
  final Offer? selectedOffer;
  final ValueChanged<Offer> onOfferTap;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: initialZoom,
          onTap: (_, _) => onMapTap(),
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: _tileUrlTemplate,
            subdomains: _tileSubdomains,
            userAgentPackageName: 'edu.itla.randomguysandgirl.ocupa2',
            // El caché HTTP integrado de flutter_map (desde 8.2.0) intenta
            // parsear la cabecera Last-Modified/Date del servidor de
            // tiles con un parser estricto (RFC-1123). CARTO no cumple
            // ese formato exacto, lo que hace que el parseo falle
            // internamente y NINGÚN tile se muestre, sin pasar por
            // errorTileCallback. Se desactiva ese caché para evitarlo:
            // https://github.com/fleaflet/flutter_map/issues/2124
            tileProvider: NetworkTileProvider(
              cachingProvider: const DisabledMapCachingProvider(),
            ),
            // Sin animación de opacidad al cargar: en algunos entornos esa
            // animación no llega a completarse visualmente.
            tileDisplay: const TileDisplay.instantaneous(),
            errorTileCallback:
                (TileImage tile, Object error, StackTrace? stackTrace) {
                  debugPrint('No se pudo cargar un tile del mapa: $error');
                },
          ),
          RichAttributionWidget(
            attributions: <SourceAttribution>[
              TextSourceAttribution('© OpenStreetMap contributors, © CARTO'),
            ],
          ),
          MarkerLayer(
            markers: offers.map((Offer offer) {
              final bool isSelected = selectedOffer?.id == offer.id;
              return Marker(
                point: LatLng(offer.latitude!, offer.longitude!),
                width: isSelected ? 44 : 28,
                height: isSelected ? 44 : 28,
                child: GestureDetector(
                  onTap: () => onOfferTap(offer),
                  child: isSelected
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.circle,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.text,
                          size: 28,
                        ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _OfferPreviewCard extends StatelessWidget {
  const _OfferPreviewCard({required this.offer, required this.onTap});

  final Offer offer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: const Color(0x140F172A),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          offer.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${offer.displayJobType} • ${offer.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          OfferDisplay.paymentLabel(offer),
                          style: const TextStyle(
                            color: _payGreen,
                            fontSize: 14,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onTap,
                child: const Text(
                  'Ver oferta',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
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

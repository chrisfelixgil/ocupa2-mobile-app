import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_status.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';
import 'package:provider/provider.dart';

/// Ubicación por defecto cuando ninguna oferta trae coordenadas todavía
/// (Santo Domingo, República Dominicana), solo para que el mapa no abra
/// centrado en el punto (0, 0) del océano.
const LatLng _fallbackCenter = LatLng(18.4861, -69.9312);

class OfferMapView extends StatefulWidget {
  const OfferMapView({super.key});

  @override
  State<OfferMapView> createState() => _OfferMapViewState();
}

class _OfferMapViewState extends State<OfferMapView> {
  final MapController _mapController = MapController();
  Offer? _selectedOffer;

  // TEMPORAL: para ver que esta pasando con los tiles ahora que el
  // cache esta desactivado.
  int _tileErrorCount = 0;
  Object? _lastTileError;
  final Set<String> _builtTileKeys = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExploreOffersViewModel>().load();
      }
    });
  }

  /// Ofertas con coordenadas utilizables. Se descartan además las que
  /// vienen en (0, 0): esa combinación no es un lugar real, es el valor
  /// que quedó en algunas ofertas semilla/de prueba que nunca recibieron
  /// una ubicación real. Tratarlas como "sin ubicación" evita que el mapa
  /// se centre en medio del océano.
  List<Offer> _offersWithLocation(List<Offer> offers) {
    return offers.where((Offer offer) {
      final double? lat = offer.latitude;
      final double? lng = offer.longitude;
      if (lat == null || lng == null) {
        return false;
      }
      final bool isNullIsland = lat == 0 && lng == 0;
      return !isNullIsland;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ExploreOffersViewModel viewModel = context.watch<ExploreOffersViewModel>();

    final List<Offer> located = viewModel.status == ExploreOffersStatus.success
        ? _offersWithLocation(viewModel.offers)
        : const <Offer>[];

    final LatLng center = located.isNotEmpty
        ? LatLng(located.first.latitude!, located.first.longitude!)
        : _fallbackCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de ofertas'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Tiles construidos: ${_builtTileKeys.length} | Errores: $_tileErrorCount'
              '${_lastTileError != null ? ' (ult: $_lastTileError)' : ''}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: located.isEmpty ? 12 : 13,
                onTap: (_, __) {
                  setState(() {
                    _selectedOffer = null;
                  });
                },
              ),
              children: <Widget>[
                TileLayer(
                  // OpenStreetMap directo bloquea muchas peticiones desde apps
                  // (política de uso justo de tiles.openstreetmap.org). CARTO
                  // ofrece los mismos datos de OSM con tiles gratuitos
                  // pensados para consumirse desde apps.
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const <String>['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'edu.itla.randomguysandgirl.ocupa2',
                  // El caché HTTP integrado de flutter_map (desde 8.2.0)
                  // intenta parsear la cabecera Last-Modified/Date del
                  // servidor de tiles con un parser estricto (RFC-1123).
                  // CARTO no cumple ese formato exacto, lo que hace que el
                  // parseo falle internamente y NINGÚN tile se muestre, sin
                  // pasar por errorTileCallback (por eso no había forma de
                  // detectarlo desde la UI). Se desactiva ese caché para
                  // evitar el bug: https://github.com/fleaflet/flutter_map/issues/2124
                  tileProvider: NetworkTileProvider(
                    cachingProvider: const DisabledMapCachingProvider(),
                  ),
                  // TileLayer por defecto anima la opacidad de cada tile
                  // de 0 a 1 al cargar (TileDisplay.fadeIn()). En este
                  // emulador esa animación parece quedarse pegada en 0
                  // (los tiles se "construyen" y no dan error, pero nunca
                  // se ven). Se fuerza a que aparezcan de inmediato.
                  tileDisplay: const TileDisplay.instantaneous(),
                  errorTileCallback: (TileImage tile, Object error, StackTrace? stackTrace) {
                    debugPrint('No se pudo cargar un tile del mapa: $error');
                    if (mounted) {
                      setState(() {
                        _tileErrorCount++;
                        _lastTileError = error;
                      });
                    }
                  },
                  tileBuilder: (BuildContext context, Widget tileWidget, TileImage tile) {
                    final String key = tile.coordinates.toString();
                    if (!_builtTileKeys.contains(key)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_builtTileKeys.contains(key)) {
                          setState(() {
                            _builtTileKeys.add(key);
                          });
                        }
                      });
                    }
                    return tileWidget;
                  },
                ),
                RichAttributionWidget(
                  attributions: <SourceAttribution>[
                    TextSourceAttribution(
                      '© OpenStreetMap contributors, © CARTO',
                      onTap: () {},
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: located.map((Offer offer) {
                    return Marker(
                      point: LatLng(offer.latitude!, offer.longitude!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOffer = offer;
                          });
                        },
                        child: Icon(
                          Icons.location_on_rounded,
                          color: _selectedOffer?.id == offer.id
                              ? AppColors.terracotta
                              : AppColors.navy,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          if (viewModel.isLoading)
            const Positioned(
              top: AppSpacing.md,
              left: 0,
              right: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (viewModel.status == ExploreOffersStatus.success && located.isEmpty)
            const Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _InfoBanner(
                message: 'Ninguna oferta activa tiene ubicación todavía.',
              ),
            ),
          if (_selectedOffer != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _OfferPreviewCard(
                offer: _selectedOffer!,
                onTap: () {
                  context.pushNamed(
                    AppRouteNames.jobSearchOfferDetail,
                    pathParameters: <String, String>{'id': _selectedOffer!.id},
                  );
                },
              ),
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
      color: AppColors.white,
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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      offer.displayJobType,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      offer.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

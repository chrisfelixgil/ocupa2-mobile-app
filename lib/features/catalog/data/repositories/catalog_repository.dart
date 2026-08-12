import 'package:ocupa2/features/catalog/data/models/job_type.dart';
import 'package:ocupa2/features/catalog/data/services/catalog_service.dart';

/// El catálogo de tipos de trabajo casi no cambia durante una sesión, así
/// que se guarda en memoria después de la primera consulta para no pedirlo
/// cada vez que se abre un filtro o un formulario.
class CatalogRepository {
  CatalogRepository({required this._catalogService});

  final CatalogService _catalogService;

  List<JobType>? _cachedJobTypes;

  Future<List<JobType>> getJobTypes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedJobTypes != null) {
      return _cachedJobTypes!;
    }

    final List<JobType> jobTypes = await _catalogService.getJobTypes();
    _cachedJobTypes = jobTypes;
    return jobTypes;
  }
}

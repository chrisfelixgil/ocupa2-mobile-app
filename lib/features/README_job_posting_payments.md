# Módulos `job_posting` y `payments`

Generados siguiendo el patrón real visto en `app_providers.dart` (constructores
con parámetros NOMBRADOS, ej. `AuthServiceImpl(apiClient: ...)`,
`AuthRepositoryImpl(authService: ..., tokenStorage: ...)`) y en `auth` /
`job_search` (viewmodels con enum de status, un archivo por responsabilidad).

## ⚠️ Lo que quedó asumido (revisar y corregir)

1. **Métodos de `ApiClient`**: se asumió `get(path)` / `post(path, {body})`
   devolviendo JSON ya decodificado (o envuelto en `{"data": ...}`). No vi el
   contenido de `core/network/api_client.dart`, solo que se instancia con
   `ApiClient.create(baseUrl:, tokenStorage:, sessionEventBus:)` y tiene
   `.close()`. Si los métodos de lectura/escritura se llaman distinto, solo
   hay que tocar `job_posting_service_impl.dart` y `payment_service_impl.dart`
   — el resto de las capas no cambia.
2. **Respuestas de `POST /offers`, `GET /offers/{id}`, `GET /me/offers`**: no
   estaban en el swagger compartido, así que `Offer.fromJson` es una
   suposición razonable basada en el request. Revisar nombres reales de
   campos (`id` vs `_id`, `status`, `createdAt`, si `GET /me/offers` viene
   paginado, etc).
3. **Módulo de pagos completo (`/payments`, `/me/payments`)**: sin swagger
   compartido; `PaymentRequest`/`Payment` son un supuesto completo (offerId +
   amount + currency + method).
4. **`app_router.dart`**: no vi su contenido, así que no sé si las rutas de
   cada feature se registran como `routes:` anidadas (como dejé
   `JobPostingRoutes.routes` / `PaymentRoutes.routes`) o de otra forma.
   Compárteme ese archivo si quieres el snippet exacto también para el router.

## 🔌 Cómo conectarlo (sin tocar archivos de otros)

**DI** — bloque para agregar dentro de la lista `providers` de
`app/di/app_providers.dart` (después del bloque de `JobSearch`, por ejemplo),
respetando el mismo estilo que ya usan:

```dart
Provider<JobPostingService>(
  create: (BuildContext context) {
    return JobPostingServiceImpl(apiClient: context.read<ApiClient>());
  },
),
Provider<JobPostingRepository>(
  create: (BuildContext context) {
    return JobPostingRepositoryImpl(
      jobPostingService: context.read<JobPostingService>(),
    );
  },
),
Provider<PaymentService>(
  create: (BuildContext context) {
    return PaymentServiceImpl(apiClient: context.read<ApiClient>());
  },
),
Provider<PaymentRepository>(
  create: (BuildContext context) {
    return PaymentRepositoryImpl(
      paymentService: context.read<PaymentService>(),
    );
  },
),
```

No agregué `ChangeNotifierProvider` de los viewmodels acá porque, siguiendo
tu patrón (`ExploreOffersViewModel` sí está global, pero `AuthViewModel`
también) — decide tú si `CreateOfferViewModel` / `MyOffersViewModel` /
`OfferDetailViewModel` / `MakePaymentViewModel` / `MyPaymentsViewModel` van
globales en `app_providers.dart` o si prefieres dejarlos scoped por ruta como
ya los dejé en `job_posting_routes.dart` y `payment_routes.dart` (cada
`GoRoute` los crea con `ChangeNotifierProvider` local). Ambas opciones
funcionan con el código tal cual está.

Imports que necesitarás agregar en `app_providers.dart`:
```dart
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository.dart';
import 'package:ocupa2/features/job_posting/data/repositories/job_posting_repository_impl.dart';
import 'package:ocupa2/features/job_posting/data/services/job_posting_service.dart';
import 'package:ocupa2/features/job_posting/data/services/job_posting_service_impl.dart';
import 'package:ocupa2/features/payments/data/repositories/payment_repository.dart';
import 'package:ocupa2/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:ocupa2/features/payments/data/services/payment_service.dart';
import 'package:ocupa2/features/payments/data/services/payment_service_impl.dart';
```

**Router** (`app_router.dart` — pendiente de ver su contenido real):
```dart
GoRoute(path: '/job-posting', routes: JobPostingRoutes.routes),
GoRoute(path: '/payments', routes: PaymentRoutes.routes),
```

## 📁 Archivos nuevos

```
features/job_posting/
  data/
    job_posting_endpoints.dart
    models/ offer.dart, offer_status.dart, offer_location.dart,
            offer_payment.dart, offer_question.dart, create_offer_request.dart
    repositories/ job_posting_repository.dart (+impl)
    services/ job_posting_service.dart (+impl)
  presentation/
    viewmodels/ create_offer_*, my_offers_*, offer_detail_*
    views/ create_offer_view.dart, my_offers_view.dart,
           job_posting_offer_detail_view.dart
    widgets/ my_offer_card.dart
    routes/ job_posting_routes.dart (reemplaza el placeholder existente)

features/payments/   (módulo nuevo)
  data/
    payment_endpoints.dart
    models/ payment.dart, payment_status.dart, payment_request.dart
    repositories/ payment_repository.dart (+impl)
    services/ payment_service.dart (+impl)
  presentation/
    viewmodels/ make_payment_*, my_payments_*
    views/ make_payment_view.dart, my_payments_view.dart
    widgets/ payment_card.dart
    routes/ payment_routes.dart
```

No se modificó ningún archivo fuera de `features/job_posting/` y
`features/payments/`.

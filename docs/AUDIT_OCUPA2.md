# Auditoría Ocupa2 (cliente Flutter)

**Fecha:** 14 de agosto de 2026  
**Alcance:** código del cliente Android Flutter vs contrato `recursos/openapi.yaml`  
**Regla:** este informe no modifica la aplicación. Las correcciones quedan pendientes de aprobación.

Contrato usado: `proyectoFinal/recursos/openapi.yaml`  
Base API: `https://ocupa2.ia3x.com/apix`

---

## A. Resumen ejecutivo

El cliente cubre **la mayoría del núcleo obligatorio**: autenticación, perfil, explorar/mapa, aplicar, publicar (con foto y pago), experiencias, aplicantes, contratos, pagos, noticias, videos y Acerca de. El JWT se inyecta con un `ApiClient` compartido (`Authorization: Bearer <token>`), salvo **Inicio**, que crea un `Dio` propio.

El riesgo de entrega no es “falta casi todo”, sino **flujos obligatorios incompletos o inconsistentes**:

- publicar no cobra de forma contractual 1.00 USD (mezcla salario de la oferta con `POST /payments`);
- no se recogen `customAnswers` de `GET /job-types`;
- aplicar no usa `GET /me/applications` en el detalle ni trata 409 como “Ya aplicaste”;
- la navegación principal es un menú superior, no una barra persistente;
- likes y foro (extras) no existen.

**Conteo de hallazgos priorizados en este informe**

| Severidad | Cantidad |
|-----------|----------|
| P0 — bloqueante | 2 |
| P1 — requisito obligatorio roto / degradado | 12 |
| P2 — funcional/UX importante | 14 |
| P3 — mejora / extra | 8 |

**Riesgos principales**

1. Un tipo de empleo con campos custom requeridos puede fallar al publicar (422) o publicarse incompleto.  
2. Un usuario puede reintentar aplicar; el 409 se ve como error genérico.  
3. Tras elegir ganador, Finalista/Descartar siguen activos (riesgo de toque accidental).  
4. Videos/noticias pueden desaparecer juntos si una de las dos llamadas de Inicio falla.  
5. Contratos: no se confirmó un loop infinito en código; sí hay retry muerto y `myRole` por defecto `contratante`.

Auth (registro, login, forgot, completar perfil, cambiar contraseña, Acerca de, interceptor JWT) está **estable**. No se recomienda reescribirlo.

---

## B. Cobertura API (39 endpoints)

Leyenda de **Estado**:

- `OK` — flujo Service → estado → UI usable  
- `PARCIAL` — llamado, pero request/UX/errores incompletos  
- `NO INTEGRADO` — código existe, UI no lo usa (o usa otra ruta)  
- `AUSENTE` — no hay cliente Dart

| Método | Endpoint | Módulo | Obligatorio/Extra | Servicio Dart | Método Dart | Provider / VM | Pantalla | Implementado | Alcanzable UI | Request correcto | Response manejado | Errores manejados | Estado |
|--------|----------|--------|-------------------|---------------|-------------|---------------|----------|--------------|---------------|------------------|-------------------|-------------------|--------|
| POST | `/auth/register` | Auth | Obligatorio | `AuthServiceImpl` | `register` | `AuthViewModel` | `RegisterView` | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/auth/login` | Auth | Obligatorio | `AuthServiceImpl` | `login` | `AuthViewModel` / `SessionViewModel` | `LoginView` | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/auth/forgot-password` | Auth | Obligatorio | `AuthServiceImpl` | `forgotPassword` | `AuthViewModel` | `ForgotPasswordView` | Sí | Sí | Sí | Sí | Sí | OK |
| GET | `/me` | Perfil | Obligatorio | `AuthServiceImpl` | `getMe` | `SessionViewModel` | Splash / guards | Sí | Sí | Sí | Sí | Sí | OK |
| PUT | `/me/profile` | Perfil | Obligatorio | `AuthServiceImpl` | `completeProfile` | `AuthViewModel` | `CompleteProfileView` | Sí | Sí (forzado) | Sí | Sí | Sí | OK |
| PUT | `/me/password` | Perfil | Obligatorio | `AuthServiceImpl` | `changePassword` | `SessionViewModel` | `ChangePasswordView` | Sí | Sí | Sí | Sí | Sí | OK |
| GET | `/job-types` | Catálogo | Obligatorio | `CatalogService` | `getJobTypes` | Create offer / explore / experiencias | Varias | Sí | Parcial | Sí | Sí | Parcial | PARCIAL |
| GET | `/me/experiences` | Experiencias | Obligatorio | `ExperienceService` | `getMyExperiences` | `ExperiencesViewModel` | `ExperiencesView` | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/me/experiences` | Experiencias | Obligatorio | `ExperienceService` | `create` | `ExperiencesViewModel` | `ExperiencesView` | Sí | Sí | Sí | Sí | Sí | OK |
| DELETE | `/me/experiences/{id}` | Experiencias | Obligatorio | `ExperienceService` | `delete` | `ExperiencesViewModel` | `ExperiencesView` | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/uploads` | Uploads | Obligatorio | 2× `UploadService` | `uploadImage` | Create offer / experiencias / contratos | Varias | Sí | Sí | Sí | Sí | Parcial | PARCIAL |
| POST | `/payments` | Pagos | Obligatorio | `PaymentServiceImpl` | `createPayment` | `MakePaymentViewModel` | Dialog publicar / `MakePaymentView` | Sí | Sí | No (extra `amount`/`currency`; tarjeta hardcode) | Sí | No (402) | PARCIAL |
| GET | `/me/payments` | Pagos | Obligatorio | `PaymentServiceImpl` | `getMyPayments` | `MyPaymentsViewModel` | `MyPaymentsView` + detalle | Sí | Sí | Sí | Sí | Sí | OK |
| GET | `/offers` | Ofertas | Obligatorio | `JobSearchServiceImpl` | `getOffers` | `ExploreOffersViewModel` | Explorar / mapa | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/offers` | Ofertas | Obligatorio | `JobPostingServiceImpl` | `createOffer` | `CreateOfferViewModel` | `CreateOfferView` | Sí | Sí | Parcial (`customAnswers` vacío) | Sí | Parcial | PARCIAL |
| GET | `/me/offers` | Ofertas | Obligatorio | Job posting + my_activity | `getMyOffers` | 2 VM distintos | 2 pantallas `MyOffersView` | Sí | Sí (ruta job_posting) | Sí | Sí | Sí | PARCIAL |
| GET | `/offers/{id}` | Ofertas | Obligatorio | Job search + job posting | `getOfferById` | Detail VMs | Detalle buscar / detalle publicar | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/offers/{id}/deactivate` | Ofertas | Obligatorio | Ambos módulos | `deactivateOffer` | My offers / detail posting | Mis ofertas job_posting | Sí | Sí | Sí | Sí | Parcial (409) | OK |
| POST | `/offers/{id}/apply` | Aplicaciones | Obligatorio | `JobSearchServiceImpl` | `applyToOffer` | `OfferDetailViewModel` | `OfferDetailView` | Sí | Sí | Sí (comment + answers) | Ignora body | No 409 UX | PARCIAL |
| GET | `/offers/{id}/applications` | Aplicaciones | Obligatorio | `ApplicationService` | `getOfferApplications` | `JobPostingOfferDetailViewModel` | Detalle publicante | Sí | Sí | Sí | Parcial (parse experiencias) | Parcial | PARCIAL |
| GET | `/me/applications` | Aplicaciones | Obligatorio | `ApplicationService` | `getMyApplications` | `ApplicationsViewModel` + explore | Mis aplicaciones; filtro explore | Sí | Parcial | Sí | Sí | Filtro silencioso | PARCIAL |
| PATCH | `/applications/{id}` | Aplicaciones | Obligatorio | `ApplicationService` | `updateApplication` | `JobPostingOfferDetailViewModel` | Cards aplicante | Sí | Sí | Sí | Sí | Acciones no gated | PARCIAL |
| POST | `/offers/{id}/like` | Likes | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| DELETE | `/offers/{id}/like` | Likes | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| GET | `/me/likes` | Likes | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| GET | `/forum/topics` | Foro | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| POST | `/forum/topics` | Foro | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| GET | `/forum/topics/{id}` | Foro | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| POST | `/forum/topics/{id}/comments` | Foro | Extra | — | — | — | — | No | No | — | — | — | AUSENTE |
| GET | `/me/contracts` | Contratos | Obligatorio | `ContractService` | `getMyContracts` | `ContractsViewModel` | `MyContractsView` | Sí | Sí | Query `status` no se envía | Sí | Sí | PARCIAL |
| GET | `/contracts/{id}` | Contratos | Obligatorio | `ContractService` | `getContractDetail` | `ContractDetailViewModel` | `ContractDetailView` | Sí | Sí | Sí | Sí | Retry roto | PARCIAL |
| PUT | `/contracts/{id}/terms` | Contratos | Obligatorio | `ContractService` | `setTerms` | `ContractDetailViewModel` | Detalle (contratante) | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/contracts/{id}/accept` | Contratos | Obligatorio | `ContractService` | `accept` | `ContractDetailViewModel` | Detalle (contratado) | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/contracts/{id}/reject` | Contratos | Obligatorio | `ContractService` | `reject` | `ContractDetailViewModel` | Detalle (contratado) | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/contracts/{id}/comments` | Contratos | Obligatorio | `ContractService` | `addComment` | `ContractDetailViewModel` | Detalle activo | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/contracts/{id}/photos` | Contratos | Obligatorio | `ContractService` | `addPhoto` | `ContractDetailViewModel` | Detalle activo | Sí | Sí | Sí | Sí | Sí | OK |
| POST | `/contracts/{id}/cancel` | Contratos | Obligatorio | `ContractService` | `cancel` | `ContractDetailViewModel` | Detalle activo | Sí | Sí | Sí | Sí | Sí | OK |
| GET | `/news` | Contenido | Obligatorio | `HomeServiceImpl` | `getNews` | `HomeViewModel` | `HomeView` | Sí | Sí | Sí (`limit=12`) | Frágil | Acoplado a videos | PARCIAL |
| GET | `/videos` | Contenido | Obligatorio | `HomeServiceImpl` | `getVideos` | `HomeViewModel` | `HomeView` | Sí | Sí | Sí | Frágil | Acoplado a news | PARCIAL |

**Totales:** 32/39 con algún código cliente; **7 extras ausentes** (likes + foro); ~15 obligatorios en estado PARCIAL.

---

## C. Cobertura de requisitos (módulos mínimos)

| # | Módulo | Estado | Por qué |
|---|--------|--------|---------|
| 1 | Inicio | ⚠️ Parcial | Slider + noticias + videos existen. Sin BottomNavigation. Menú overflow. Dio propio. `Future.wait` oculta ambas secciones si una falla. |
| 2 | Noticias | ⚠️ Parcial | `GET /news?limit=12` OK. Fuente remolacha.net **es del contrato**, no es bug. Sin detalle in-app (abre URL). Fecha no se muestra. |
| 3 | Videos | ⚠️ / 🐛 | Endpoint y modelo coinciden con OpenAPI. Reproductor in-app no existe (`url_launcher`). Si QA no ve videos, causa probable: error conjunto con noticias o thumbnail/red. |
| 4 | Registro y login | ✅ | Flujos completos, validación, JWT en secure storage. |
| 5 | Recuperar contraseña | ✅ | Clave temporal por correo → login → cambio forzado. |
| 6 | Completar perfil | ✅ | Guard de router por `profileCompleted`. |
| 7 | Explorar ofertas | ⚠️ | Lista + filtros. Oculta propias y ya aplicadas **solo si** `/me/offers` y `/me/applications` no fallan. |
| 8 | Mapa | ✅ | `flutter_map` + mismos filtros del explore. |
| 9 | Detalle + aplicar | ⚠️ | Carga `GET /offers/{id}`, preguntas dinámicas, `comment` + `answers`. No bloquea re-aplicar. 409 genérico. |
| 10 | Publicar oferta | ⚠️ / 🐛 | Foto, job types API, preguntas extra, pago previo. Faltan custom fields. Pago no es 1 USD contractual. Tarjeta no editable. |
| 11 | Mis ofertas | ⚠️ | Ruta usable: `/my-offers` (job_posting) con FAB publicar. Ruta my_activity `/my-activity/offers` tiene `onTap: () {}`. Tras crear no refresca esta lista. |
| 12 | Mis aplicaciones | ✅ / ⚠️ | Lista `GET /me/applications`. No se reutiliza en detalle de oferta. |
| 13 | Perfil / experiencias | ✅ / ⚠️ | CRUD + certificado via `/uploads`. En evaluación de candidatos falta `jobTypeKey` y preview de certificado. |
| 14 | Mis pagos | ⚠️ | Lista y detalle existen. Lista muy pobre (monto + estado). Detalle cubre más campos del modelo. |
| 15 | Cambiar contraseña | ✅ | Voluntario y forzado post-recuperación. |
| 16 | Acerca de | ✅ | Foto, matrícula, tel, Telegram. |

---

## D. Hallazgos QA y defectos

### D1. Videos no aparecen

| Campo | Valor |
|-------|--------|
| ID | QA-01 |
| Severidad | P1 |
| Módulo | Inicio / Videos |
| Actual | `GET /videos` está implementado; UI en `VideosSection` / `VideoCard`. Si `loadHome` falla, **tampoco** se ven noticias. |
| Esperado | Lista de videos (youtubeId, url, title, description, thumbnail). |
| Causa probable | 1) `HomeViewModel.loadHome` usa `Future.wait` noticias+videos: un fallo oculta ambos. 2) `HomeServiceImpl` exige `response.data is Map<String, dynamic>` (Dio a veces entrega `Map<dynamic, dynamic>`). 3) Cliente Home **no** usa `ApiClient`. |
| Archivos | `lib/app/router/app_router.dart`, `lib/features/home/presentation/viewmodels/home_view_model.dart`, `lib/features/home/data/services/home_service_impl.dart`, `lib/features/home/presentation/widgets/video_card.dart` |
| Endpoint | `GET /videos` (público) |
| Origen | **Frontend** (parsing/acoplamiento). El schema OpenAPI coincide. |
| Solución | Usar `ApiClient` público; parsear con `Map<String, dynamic>.from`; cargar news/videos independientes; fallback `youtubeId` si `url` vacío. |

### D2. Slider de baja calidad / poco mensaje

| Campo | Valor |
|-------|--------|
| ID | QA-02 |
| Severidad | P2 |
| Módulo | Inicio |
| Actual | 4 JPG locales, auto-slide, sin textos de bienvenida. |
| Esperado | Slider con imágenes **y** mensajes. |
| Causa | `WelcomeSlider` solo lista assets. |
| Archivos | `lib/features/home/presentation/widgets/welcome_slider.dart` |
| Solución | Overlay de título/cuerpo; no sustituir fotos del equipo si ya cumplen consigna. |

### D3. Noticias de remolacha.net

| Campo | Valor |
|-------|--------|
| ID | QA-03 |
| Severidad | P3 (no es bug de origen) |
| Módulo | Noticias |
| Actual | Fuente `remolacha.net` en payload. |
| Esperado | OpenAPI: *artículos de empleo publicados en remolacha.net*. |
| Causa | Contrato del API. |
| Solución | No cambiar fuente. Mejorar presentación (fecha, detalle, duplicados si aparecen). |

### D4. Navegación solo en AppBar / menú

| Campo | Valor |
|-------|--------|
| ID | QA-04 |
| Severidad | P1 (UX de consigna: módulos principales difíciles) |
| Módulo | Navegación |
| Actual | `PopupMenuButton` en Home. Publicar está dos toques adentro (Mis ofertas → FAB). |
| Esperado | Destinos principales persistentes (Inicio, Buscar, Publicar, Actividad, Perfil). |
| Archivos | `lib/features/home/presentation/views/home_view.dart`, `lib/app/router/app_router.dart` |
| Solución | `StatefulShellRoute` / `NavigationBar` con GoRouter, **sin** reescribir auth guards. |

### D5. Atrás repetido entre módulos

| Campo | Valor |
|-------|--------|
| ID | QA-05 |
| Severidad | P2 |
| Módulo | Navegación |
| Actual | `context.pushNamed` apila rutas. Mis ofertas job_posting hace `goNamed(home)` en back. |
| Esperado | Cambiar de módulo sin vaciar el stack. |
| Solución | Misma navegación persistente que D4. |

### D6. Feedback seco al aplicar

| Campo | Valor |
|-------|--------|
| ID | QA-06 |
| Severidad | P2 |
| Módulo | Aplicar |
| Actual | Ya no hay pantalla `_ApplicationSubmittedView`. Hay `AlertDialog` y pop. |
| Esperado | SnackBar / bottom sheet y permanecer explorando. |
| Archivos | `lib/features/job_search/presentation/views/offer_detail_view.dart` |
| Solución | SnackBar + `context.pop` a explorar; recargar lista. |

### D7. Reaplicar pese a 409

| Campo | Valor |
|-------|--------|
| ID | QA-07 |
| Severidad | P1 |
| Módulo | Aplicar |
| Actual | Explore filtra IDs de `/me/applications`. Detalle **no** consulta ese estado. Botón sigue activo. 409 → mensaje genérico de conflicto. |
| Esperado | “Ya aplicaste”; acción deshabilitada. |
| Archivos | `offer_detail_view.dart`, `explore_offers_view_model.dart`, `error_mapper.dart` |
| Endpoint | `POST /offers/{id}/apply` (409), `GET /me/applications` |
| Solución | Pasar `alreadyApplied` o consultar `/me/applications`; mapear 409 a copy específica. |

### D8. Ofertas propias en explorar

| Campo | Valor |
|-------|--------|
| ID | QA-08 |
| Severidad | P1 (si `/me/offers` falla) / mitigado si no falla |
| Módulo | Explorar |
| Actual | Cliente resta IDs de `GET /me/offers` vs `GET /offers`. No usa identidad del publicante. |
| Esperado | No ver las propias al buscar empleo. |
| Archivos | `lib/features/job_search/presentation/viewmodels/explore_offers_view_model.dart` |
| Solución | No silenciar errores de `/me/offers`; si falla, no mostrar lista cruda o reintentar. |

---

### Publicación, custom fields, preguntas, pago

### D9. `customAnswers` no se recogen (P0)

| Campo | Valor |
|-------|--------|
| ID | PUB-01 |
| Severidad | **P0** |
| Módulo | Publicar |
| Actual | `JobType.customFields` se parsea. Create offer solo muestra el dropdown de `key`. `submit(..., customAnswers)` no se usa; el request manda `{}`. |
| Esperado | Render dinámico text/number/date/select/check y envío en `POST /offers`. |
| Archivos | `create_offer_view.dart`, `create_offer_request.dart`, `catalog/data/models/custom_field.dart` |
| Endpoint | `GET /job-types`, `POST /offers` (`OfferInput.customAnswers`) |
| Origen | **Frontend** |
| Solución | Formulario dinámico según `customFields` del tipo elegido. |

### D10. Preguntas adicionales al publicar

| Campo | Valor |
|-------|--------|
| ID | PUB-02 |
| Severidad | P2 (código existe; QA puede estar desactualizado) |
| Actual | UI para text/date/select/check, required, options. Se envían en `questions`. Apply las renderiza desde `GET /offers/{id}`. |
| Esperado | Cero o más preguntas. |
| Nota | Hay métodos `_updateQuestionType` etc. **sin usar** (`flutter analyze` unused_element). Riesgo de UI a medias si el builder no llama esos updaters. Verificar en dispositivo antes de rehacer. |
| Archivos | `create_offer_view.dart`, `offer_question.dart`, `offer_detail_view.dart` |

### D11. Pago de publicación ≠ contrato 1 USD (P0)

| Campo | Valor |
|-------|--------|
| ID | PAY-01 |
| Severidad | **P0** |
| Actual | Dialog dice “Monto a pagar: $1 USD”. `pay(amount: amount, currency: currency)` usa el **salario de la oferta** (p. ej. 1500 DOP). OpenAPI `POST /payments` **no** documenta `amount`/`currency`; describe cobro simulado 1 USD. |
| Esperado | Informar 1.00 USD; Cancelar no cobra; Continuar formulario de tarjeta editable; `paymentId` → `POST /offers`. |
| Archivos | `create_offer_view.dart` (~596–758), `payment_request.dart` |
| Endpoint | `POST /payments`, `POST /offers` |
| Origen | **Frontend** (campos extra + UI). Si el API ignora `amount`, el cobro real igual es 1 USD; la UX y el body siguen incorrectos. |
| Solución | Pagar siempre `1` + `USD` (o solo campos de tarjeta del OpenAPI). Salario solo en `offer.payment`. |

### D12. Tarjeta hardcodeada; no se puede probar rechazo

| Campo | Valor |
|-------|--------|
| ID | PAY-02 |
| Severidad | P1 |
| Actual | Campos `readOnly`. Display `...4232`, envío `4242424242424242`. `MakePaymentView` también hardcodea. |
| Esperado | Inputs reales; 4242 aprueba; 4000000000000002 → 402. |
| Archivos | `create_offer_view.dart`, `make_payment_view.dart` |
| Seguridad | No se persiste PAN/CVV. No hay `print` del número. OK. |

### D13. HTTP 402 no mapeado

| Campo | Valor |
|-------|--------|
| ID | PAY-03 |
| Severidad | P1 |
| Actual | `ErrorMapper` cubre 400/401/403/404/409/422; 402 cae en `default`. |
| Archivos | `lib/core/network/error_mapper.dart`, `api_exception.dart` |
| Endpoint | `POST /payments` 402, `POST /offers` 402 |

### D14. Tras publicar hay que refrescar Mis ofertas

| Campo | Valor |
|-------|--------|
| ID | PUB-03 |
| Severidad | P2 |
| Actual | Éxito llama `ExploreOffersViewModel.load()` y `pop`. **No** llama `MyOffersViewModel.loadMyOffers()`. El VM de Mis ofertas se crea por ruta (lista cacheada al volver). |
| Causa exacta | Falta invalidación/refetch de `/me/offers` después de `POST /offers`. No es `notifyListeners` ausente en create; es **otro** ChangeNotifier. |
| Archivos | `create_offer_view.dart`, `job_posting_routes.dart` |

### D15. Historial de pagos insuficiente en lista

| Campo | Valor |
|-------|--------|
| ID | PAY-04 |
| Severidad | P2 |
| Actual | Modelo: id, amount, currency, status, concept, cardLast4, cardholder, reference, consumed, offerId, declineReason, createdAt. Lista: monto + estado. Detalle: concept, monto, estado, fecha, last4, titular, referencia, declineReason. |
| Esperado | Resumen con fecha, monto, moneda, estado, referencia. |
| Archivos | `payment_card.dart`, `payment_detail_view.dart`, `payment.dart` |
| Nota | OpenAPI no detalla schema de pago; no inventar campos. Usar solo los que ya parsea el modelo. |

---

### Aplicantes, rating, ganador

### D16. Experiencias del aplicante “solo título”

| Campo | Valor |
|-------|--------|
| ID | APP-01 |
| Severidad | P2 |
| Actual | UI de `_ApplicantCard` muestra **título y description**; certificado por tap. **No** muestra `jobTypeKey`. Si el JSON no trae `experiences` en las claves esperadas, la lista queda vacía y parece que “solo hay nombre/título de postulación”. Un item mal formado lanza `FormatException` y puede tumbar **todo** el parse de aplicantes. |
| Archivos | `application.dart`, `experience.dart`, `job_posting_offer_detail_view.dart` |
| Endpoint | `GET /offers/{id}/applications` |
| Origen | Frontend (UI + parse). Si el API anida distinto, también hay mismatch de contrato no documentado en OpenAPI (response 200 genérico). |

### D17. Calificación 1–5 y estados

| Campo | Valor |
|-------|--------|
| ID | APP-02 |
| Severidad | P1 |
| Actual | Estrellas llaman `PATCH` con `rating` y `status: applicant.status`. Botones Finalista / Ganador / Descartar **siempre** visibles, también si ya es `winner`. |
| Esperado | Máquina de estados: tras `winner` no descartar/finalista; `discarded` sin contrato. |
| Archivos | `job_posting_offer_detail_view.dart`, `offer_detail_view_model.dart` (job_posting), `application_service.dart` |
| Endpoint | `PATCH /applications/{id}` |

### D18. Descartado recibe contrato

| Campo | Valor |
|-------|--------|
| ID | APP-03 |
| Severidad | P1 (riesgo) / backend **no confirmado** |
| Actual | Cliente envía `status: 'winner'` **solo** del `applicationId` tocado. No hay bulk winner. `discarded` es otro botón. |
| Hipótesis | A) toque accidental Ganador (botones sin gate). B) API crea contrato incorrecto. C) UI de contratos asocia mal. D) `myRole` default `contratante` muestra acciones de publicante. |
| Origen | No se puede afirmar D (backend) sin request/response reales. El cliente **no** manda `winner` al descartar en código. |
| Solución | Gate UI (P1 frontend) + reproducir con logs de `PATCH` (sin PII) para ver si el API responde contrato en `discarded`. |

---

## E. Bugs de contratos (sección independiente)

### E1. Query `status` OpenAPI vs modelo

OpenAPI `GET /me/contracts?status=` enum: **`active` \| `inactive`**.  
Schema `Contract.status`: **`pending` \| `active` \| `rejected` \| `cancelled`**.

Cliente: `getMyContracts({String? status})` existe; **el VM no pasa query**. Carga todos y filtra local `isActive` / `!isActive` con labels UI active/inactive.

**Recomendación (aún no implementar):** seguir trayendo todos y filtrar por `status` real del modelo. No enviar `pending` como query (no está en el enum). Documentar inconsistencia OpenAPI; no “arreglar” el backend.

### E2. App se congela al abrir Contratos (publicante)

Búsqueda en cliente:

- No hay `while(true)` ni `notifyListeners` en loop en `ContractsViewModel`.
- Load termina en success/error.
- **Retry del detalle** usa `viewModel.contract?.id`; si el load falló, `contract` es null → Retry no hace nada (parece colgado).
- Default `myRole = 'contratante'` si el API omite el campo: el contratado vería UI de publicante (términos), no necesariamente freeze.
- Parse defensivo de parties/comments/photos.

**Causa más probable de “no responde”:** excepción de parse no visible, request colgada (timeout 15–20s), o Retry muerto. **No** se halló rebuild infinito.

| ID | Sev | Hallazgo |
|----|-----|----------|
| CON-01 | P1 | Retry detalle inútil si `contract == null` |
| CON-02 | P2 | `myRole` default `contratante` |
| CON-03 | P2 | Filtro local vs query OpenAPI (aceptable si se documenta) |
| CON-04 | P2 | Dos módulos “Mis ofertas”; my_activity `onTap: () {}` |

Endpoints de contratos (terms/accept/reject/comments/photos/cancel) **sí están integrados** en `ContractDetailView`.

---

## F. Auditoría UI/UX

**Navegación persistente:** no existe `NavigationBar`/`BottomNavigationBar`. Recomendación (sin implementar): Inicio · Buscar · Publicar · Actividad · Perfil, con GoRouter `StatefulShellRoute`.

**Estados API:** auth y varios módulos tienen loading/error/empty. Home acopla error. Explore silencia fallos de filtros.

**Doble toque:** aplicar y publicar tienen flags de submitting en parte; confirmar pago/aplicar no siempre deshabilita de forma uniforme.

**Feedback:** aplicar usa dialog; publicar SnackBar. Evitar pantallas full-screen de éxito.

**Formularios:** auth usa form_builder + validators. Publicar mezcla controllers. Pago no es formulario real. Teclado: revisar `textInputAction` en tarjeta cuando se habilite.

**Accesibilidad:** chips de Acerca de OK. Menú overflow con `ListTile` en `PopupMenuItem` puede ser estrecho. Contraste cream/navy del tema es razonable.

**Stack vs `pubspec.yaml`:** hay Dio, Provider, GoRouter, secure_storage, form_builder, flutter_map, geolocator, image_picker, cached_network_image, url_launcher, dotenv. **No** está `permission_handler` ni `youtube_player_flutter` (la consigna permite url_launcher para videos).

---

## G. Código: duplicación y riesgos

| Riesgo | Dónde |
|--------|--------|
| Segundo cliente HTTP | `app_router.dart` Home: `Dio(BaseOptions(baseUrl: 'https://ocupa2.ia3x.com/apix'))` ignora `.env` y JWT |
| Dos `UploadService` | `features/uploads` vs `features/job_posting/data/services/upload_service.dart` |
| Dos `MyOffersView` + dos VM | `job_posting` (`/my-offers`, usado en Home) vs `my_activity` (`/my-activity/offers`, tap vacío) |
| Endpoints duplicados | `ApiEndpoints` + `JobPostingEndpoints` + `PaymentEndpoints` |
| `debugPrint` de token length | `auth_interceptor.dart` (no imprime JWT completo; quitar en entrega) |
| `deleteOffer` = deactivate | Correcto vs OpenAPI (no hay DELETE) |
| Campos extra en pago | `PaymentRequest.amount/currency` no están en OpenAPI |
| Analyze (14 ago 2026) | 16 issues: 4 warnings (unused en create_offer / my_offer_card / import), resto info. **0 errors** |

No se encontraron tarjetas de usuario ni JWT persistidos fuera de `flutter_secure_storage`.

---

## H. Plan de corrección (orden recomendado)

No ejecutar hasta aprobación.

1. **P0 PUB-01** Custom fields → `customAnswers` en publicar.  
2. **P0 PAY-01** Cobro 1.00 USD / body `POST /payments` alineado a OpenAPI; salario solo en oferta.  
3. **P1 PAY-02 + PAY-03** Formulario de tarjeta + mapeo 402.  
4. **P1 QA-07** Ya aplicaste (detalle + 409).  
5. **P1 QA-08** No silenciar fallo de `/me/offers` al filtrar propias.  
6. **P1 APP-02** Máquina de estados aplicante (ocultar Finalista/Descartar si winner/discarded).  
7. **P1 QA-01** Home: `ApiClient` + cargas independientes news/videos.  
8. **P1 CON-01** Retry de contrato con el `id` de ruta, no `contract?.id`.  
9. **P1 QA-04/05** NavigationBar persistente (shell GoRouter).  
10. **P2 PUB-03** Refetch `/me/offers` al publicar.  
11. **P2 PAY-04** Enriquecer lista de pagos con campos ya parseados.  
12. **P2 APP-01** Mostrar `jobTypeKey` + miniatura certificado; parse más tolerante.  
13. **P2** Unificar Mis ofertas / UploadService / Home Dio.  
14. **P3** Slider con mensajes; fecha en noticias.  
15. **Extras** Likes y foro: **después** del núcleo.

---

## I. Pruebas de regresión (post-fix)

**Usuario A (publicante)**  
Registrar → Login → Completar perfil → Experiencia + certificado → Publicar (custom fields si aplica) → Cancelar pago (no debe cobrar) → Pagar 1 USD con `4242…4242` → Ver en Mis ofertas **sin pull-to-refresh forzado** → Aplicantes → Calificar 1–5 → Finalista → Ganador (opcional términos) → Contrato pending → Fijar términos → Tras aceptación: comentarios/fotos/cancelar.

**Usuario B (aplicante)**  
Registrar → Login → Perfil → Experiencias → Explorar (no ver ofertas de A si A es el mismo user en otra cuenta: usar dos cuentas) → Mapa → Detalle → Preguntas → Aplicar → Mis aplicaciones → Reabrir detalle = Ya aplicaste → Ser winner → Ver contrato → Aceptar/Rechazar.

**Pago rechazado:** tarjeta `4000000000000002` → mensaje 402, oferta no publicada.

**Auth (no romper):** forgot → clave temporal → cambio forzado → completar perfil → Acerca de (llamada/Telegram).

**Contenido:** noticias limit 12; videos visibles aunque falle el otro endpoint.

**Negativos:** no aplicar dos veces; no ver propias en explorar; descartar no debe crear contrato (verificar respuesta PATCH).

---

## Arquitectura observada (fase 1)

```
lib/
  app/          tema, GoRouter, AppProviders
  core/         ApiClient, AuthInterceptor, ErrorMapper, TokenStorage
  features/
    auth/       OK
    home/       Dio propio
    catalog/    job-types
    job_search/ explorar, mapa, aplicar
    job_posting/ publicar, mis ofertas (ruta viva), aplicantes
    my_activity/ experiencias, aplicaciones, contratos, mis ofertas muerta
    payments/
    uploads/    duplicado
    about/
```

JWT: `AuthInterceptor` lee `TokenStorage` y pone `Bearer` si `RequestAuth.protected`. Home no pasa por ahí.

---

## Estática

| Comando | Resultado |
|---------|-----------|
| `flutter analyze` | 16 issues (warnings/info), 0 errors |
| `flutter test` | No re-ejecutado en esta auditoría (suite grande). Recomendado antes de merge de fixes. |

Warnings relevantes: elementos muertos en `create_offer_view.dart` (preguntas); no borrar a ciegas hasta confirmar que el builder de preguntas funciona.

---

*Fin de la auditoría. Esperar aprobación antes de editar la aplicación.*

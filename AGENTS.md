# AGENTS.md — Ocupa2 (Proyecto Final, Aplicaciones Móviles, ITLA)

## Qué es el proyecto
Ocupa2 es una plataforma de empleos temporales (cuidado de mayores, niñeras, limpieza, chofer, plomero, electricista, etc). Un usuario publica una oferta o aplica a las que le interesan. Quien publica revisa aplicantes, califica, descarta y elige un ganador. La identidad de quien publica permanece oculta hasta elegir al ganador.

**No se construye backend.** Ya existe y está documentado en Swagger. Este repo es solo el cliente Android en **Flutter** que consume ese API REST.

- Base del API: `https://ocupa2.ia3x.com/apix`
- Swagger: `https://ocupa2.ia3x.com/apix/docs`
- Consigna: `https://ocupa2.ia3x.com/consigna/`

## Fecha límite
Entrega: **lunes 17 de agosto de 2026, 6:00 p.m.**

## Stack tecnológico (usar exactamente estas libs, no sustituir)
- Flutter SDK + Dart
- `dio` — cliente HTTP
- `provider` — manejo de estado
- `go_router` — navegación (~15 pantallas)
- `flutter_secure_storage` — token de sesión (JWT)
- `flutter_form_builder` + `form_builder_validators` — formularios dinámicos
- `flutter_map` + `latlong2` — mapa de ofertas (OpenStreetMap)
- `geolocator` — ubicación actual
- `permission_handler` — permisos ubicación/cámara/galería
- `image_picker` — fotos
- `cached_network_image` — cache de imágenes del API
- `youtube_player_flutter` o `url_launcher` — módulo de Videos
- `url_launcher` — llamadas telefónicas / Telegram en "Acerca de"
- `flutter_dotenv` — URL del servidor en variable de entorno
- `flutter_launcher_icons` — ícono final con caras del equipo

**Pago:** pasarela simulada del propio API, sin SDK externo. `POST /payments` con `cardNumber, cvv, expMonth, expYear, cardholder`. Tarjeta aprobada de prueba: `4242424242424242`. Rechazada: `4000000000000002`.

## Reglas de negocio del proyecto (aplican a toda la app, no solo a mi módulo)
- **Registro:** correo + número de referencia (matrícula de estudiante ITLA válida). El API rechaza el registro si la matrícula no corresponde a un estudiante habilitado.
- **Completar perfil (primer acceso obligatorio):** cédula, nombre, apellido, género, fecha de nacimiento. Sin esto no se puede usar el resto de la app.
- **Tipos de empleo dinámicos:** no están hardcodeados, se obtienen de `GET /job-types`. Cada tipo puede traer campos personalizados (ej. categoría de licencia para chofer) que la UI debe renderizar dinámicamente según lo que devuelva el API.
- **Un mismo usuario puede publicar Y aplicar** — no hay roles separados de "empleador" vs "trabajador", es la misma cuenta actuando en ambos flujos. Mi módulo (`my_activity`) debe contemplar ambos: cuando el usuario es dueño de una oferta (gestiona aplicantes/contrato como contratante) y cuando es aplicante (ve el estado de su aplicación/contrato como contratado).
- **Privacidad:** la identidad de quien publica una oferta permanece oculta para los aplicantes hasta que ese aplicante es elegido ganador.
- **Publicar oferta es de pago:** 1.00 USD vía la pasarela simulada. Sin pago confirmado, la oferta no se publica (esto es del módulo de Ismael, pero afecta el flujo de "Mis ofertas" si alguna vez está incompleta/no publicada).
- **Preguntas adicionales de una oferta:** tipos `text`, `date`, `select`, `check`, definidas por quien publica y respondidas por quien aplica.
- **Estados de una aplicación:** `applied` (en revisión) → `discarded` / `finalist` / `winner`. Al pasar a `winner` se crea el contrato automáticamente.

## Módulos mínimos de la app completa (para tener el panorama, no todos son míos)
Inicio (slider bienvenida) · Noticias · Videos · Registro y Login · Completar perfil · Explorar ofertas (+ filtro) · Mapa de ofertas · Detalle de oferta + aplicar · Publicar oferta (+ foto + pago) · **Mis ofertas publicadas** · **Mis aplicaciones** · **Mi perfil/experiencias** · Mis pagos · Cambiar contraseña · Acerca de.

## Flujo de ramas Git (respetar siempre)
- Cada quien trabaja en su rama de módulo (ej. `feature/auth`, `feature/mapa`, `feature/contratos`).
- Al terminar, se fusiona a `dev` (donde el equipo revisa).
- Solo cuando `dev` está estable, se fusiona a `main` (versión final para compilar el APK).
- **Nunca subir código directo a `main`.**

## Convenciones de código
- Capa HTTP centralizada (cliente `dio` + interceptor de token) construida por Christian — todos los módulos la reutilizan, no duplicar clientes HTTP.
- Todos los endpoints requieren `Authorization: Bearer <token>` salvo los marcados "público" abajo.
- Modelos de datos en su propia carpeta, servicios de API separados de las pantallas.
- Antes de integrar un endpoint nuevo, probarlo con Postman/Insomnia.

## Equipo y módulos (5 personas)
| Nombre | Matrícula | Módulo |
|---|---|---|
| Christian Gil | 2012-1036 | Cuentas y sesión (base HTTP compartida) |
| Kaysha Hiciano | 2023-1599 | Bienvenida, noticias, videos |
| Joseph Luis Cante Brito | 2021-1538 | Buscar trabajo (explorar, mapa, aplicar) |
| **Abisai Mora Quezada** | **2023-0598** | **Mi actividad y gestión de contratos** |
| Ismael Polanco | 2021-0293 | Publicar trabajo y pagos |

### Mi módulo (Abisai) — `lib/features/my_activity/`

**Alcance completo del módulo:**
1. **Mis aplicaciones** — mostrar las ofertas a las que apliqué y su estado (`GET /me/applications`).
2. **Mi perfil profesional / experiencias** — listar, agregar y eliminar experiencias. Cada experiencia puede tener un certificado: la imagen se sube primero a `/uploads` y la URL resultante se guarda en la experiencia.
3. **Mis ofertas publicadas** — ver mis ofertas y, al abrir una, ver sus aplicantes (`GET /offers/{id}/applications`).
4. **Gestión de aplicantes** — calificar (1–5), descartar, marcar finalista o elegir ganador. Al elegir `winner` el API crea el contrato automáticamente.
5. **Contratos** — listar y ver contratos, fijar términos cuando soy contratante, aceptar/rechazar cuando soy contratado. Los contratos activos permiten comentarios, fotos y cancelación con justificación.

**Importante:** una misma cuenta puede publicar ofertas y aplicar a otras, así que las pantallas de contratos/aplicantes deben contemplar ambos roles según corresponda al contrato específico (soy contratante vs. soy contratado).

**Arquitectura del repo (por módulos):**
```
lib/
  app/          inicio, tema, rutas y dependencias compartidas
  core/         cliente API, token, errores, widgets reutilizables
  features/
    auth/        ya avanzado
    job_search/  ya avanzado en dev (módulo de Joseph)
    my_activity/ MI MÓDULO — todavía solo tiene una ruta vacía, no ha comenzado
```

**Estado del repo ahora mismo:** la rama `dev` es la versión de integración más actual — ya incluye autenticación, sesión, conexión con el API y búsqueda de ofertas. `main` está bastante atrasada frente a `dev`. Mi carpeta `my_activity/` está vacía, así que mi trabajo no choca con el de Joseph (`job_search/`) — trabajar sobre `dev`, no sobre `main`.

**Secuencia de trabajo recomendada:**
1. Crear modelos, servicio y repositorio para: aplicaciones, experiencias, ofertas propias, aplicantes y contratos.
2. Crear las pantallas de "Mis aplicaciones" y "Mis experiencias".
3. Añadir certificados mediante carga de imagen.
4. Crear "Mis ofertas" y la pantalla de aplicantes con acciones de calificar/descartar/finalista/ganador.
5. Crear lista y detalle de contratos.
6. Registrar rutas, proveedores, y probar el recorrido completo con una cuenta que publica y otra que aplica.

**Endpoints de mi módulo:**
- `GET /me/applications`
- `GET /me/experiences` / `POST /me/experiences` (title, description, jobTypeKey, certificateImage) / `DELETE /me/experiences/{id}`
- `GET /offers/{id}/applications` — solo dueño de la oferta
- `PATCH /applications/{id}` — rating, status (applied/discarded/finalist/winner), salary, currency, startDate, duration
- `GET /me/contracts` / `GET /contracts/{id}`
- `PUT /contracts/{id}/terms`
- `POST /contracts/{id}/accept` / `/reject`
- `POST /contracts/{id}/comments` / `POST /contracts/{id}/photos` / `POST /contracts/{id}/cancel`

## Endpoints compartidos (capa HTTP de Christian)
- `POST /auth/register` — email, firstName, lastName, password, referralMatricula → token + user
- `POST /auth/login` — email, password → token + user
- `POST /auth/forgot-password` — email, referralMatricula
- `GET /me` — cuenta autenticada
- `PUT /me/password`
- `POST /uploads` — image (base64), filename → devuelve URL pública
- `GET /job-types` — público, catálogo de tipos de trabajo con campos personalizados

## Endpoints de otros módulos (para referencia, no tocar sin avisar al dueño)
**Kaysha:** `GET /news?limit=12` (público) · `GET /videos` (público)
**Joseph:** `GET /offers?jobTypeKey=&contractType=` · `GET /offers/{id}` · `POST /offers/{id}/apply`
**Ismael:** `POST /payments` · `POST /offers` · `GET /me/offers` · `POST /offers/{id}/deactivate` · `GET /me/payments`

## Extras opcionales (no requeridos por la consigna, dejar para el final)
Likes de ofertas (`POST/DELETE /offers/{id}/like`, `GET /me/likes`) y foro interno (`GET/POST /forum/topics` + comentarios).

## Reglas del equipo que afectan cómo trabajo
- Somos programadores novatos en desarrollo móvil — preferir explicaciones claras y patrones simples y consistentes por sobre soluciones muy elegantes/complejas.
- Cualquiera del equipo puede ser elegido en la defensa en vivo para explicar cualquier parte de la app, no solo su módulo — el código debe quedar legible y comentado donde no sea obvio.
- Coordinación por WhatsApp, sin Jira/GitHub Projects — no asumir que existen issues o tableros en el repo.

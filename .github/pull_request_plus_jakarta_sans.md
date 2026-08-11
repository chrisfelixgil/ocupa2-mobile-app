# feat(theme): integrar tipografía Plus Jakarta Sans

**Rama:** `feature/auth-session` → `dev`  
**Commit:** `03ab46d`

## Módulo

Theme / Tipografía

## Cambios realizados

Integración de la familia **Plus Jakarta Sans** como tipografía oficial de Ocupa2.

- Se agregaron los archivos de fuente en `assets/fonts/plus_jakarta_sans/` (incluye licencia `OFL.txt`).
- Se registraron en `pubspec.yaml` tres pesos activos: **Regular (400)**, **Medium (500)** y **Bold (700)**.
- Se unificó el bloque `flutter:` del pubspec (`.env` + fuentes).
- Se aplicó `fontFamily: PlusJakartaSans` de forma global en `AppTheme`.
- Jerarquía tipográfica definida:
  - **Regular** → cuerpo (`bodyLarge`, `bodyMedium`).
  - **Medium** → títulos de auth, AppBar, botones y textos de énfasis intermedio.
  - **Bold** → títulos de ofertas (`displaySmall` / `AppTypography.offerTitle`).
- Se eliminó el uso de `FontWeight.w600` en `AuthFeedbackMessage` (ahora usa Medium).

## Cómo probar

1. **Comandos necesarios**

```bash
cd ocupa2
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

2. **Flujo manual**

- Abrir la app y revisar splash, login, registro y home autenticada.
- Confirmar que los textos ya no usan la fuente del sistema (Roboto).
- Verificar que títulos de pantallas auth se vean en **Medium**.
- Verificar que párrafos y labels se vean en **Regular**.
- Cuando existan pantallas de ofertas, usar `Theme.of(context).textTheme.displaySmall` para títulos en **Bold**.

3. **Condiciones esperadas**

- La app compila sin errores de fuentes.
- `flutter analyze` sin issues.
- `flutter test` pasa (55 tests).
- Tipografía consistente en todas las pantallas de auth.

## Evidencias

- No hay

## Checklist

- [x] Ejecuté `flutter analyze`.
- [x] Ejecuté `flutter test`.
- [x] No incluí contraseñas, tokens ni credenciales.

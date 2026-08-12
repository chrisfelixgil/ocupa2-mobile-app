# feat(about): pantalla del equipo con llamada y Telegram

**Rama:** `feature/about` → `dev`  
**Commit:** `2c0906d`

## Módulo

About / Acerca de

## Cambios realizados

Implementa la pantalla **Acerca de** con el equipo de desarrollo de Ocupa2.

- Nueva ruta `/about` y acceso desde la sesión activa con el botón **Acerca de**.
- Catálogo de 5 integrantes con:
  - Foto (`assets/images/team/`)
  - Nombre completo
  - Matrícula
  - Teléfono con opción de llamar (`tel:`)
  - Telegram con enlace funcional (`https://t.me/...`)
- Integración de `url_launcher` y queries en `AndroidManifest` para `tel`/`https`.
- Helper reutilizable `launchAppUri` para abrir enlaces externos.
- Pruebas unitarias/widget del catálogo, la pantalla y la navegación desde sesión activa.

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

- Iniciar sesión con un usuario válido.
- En la pantalla de sesión activa, pulsar **Acerca de**.
- Verificar que aparecen los 5 integrantes con foto, nombre, matrícula, teléfono y Telegram.
- Pulsar un teléfono y confirmar que abre el marcador.
- Pulsar **Telegram** y confirmar que abre el enlace correspondiente.

3. **Condiciones esperadas**

- La ruta `/about` carga correctamente.
- Los datos del equipo coinciden con los integrantes del proyecto.
- Llamada y Telegram funcionan en dispositivo/emulador Android.
- `flutter test` pasa (incluye `test/features/about`).

## Evidencias

- (Agregar capturas de la pantalla Acerca de y del botón en sesión activa)

## Checklist

- [x] Mi rama parte de una versión actualizada de `dev`.
- [x] Ejecuté `dart format .`.
- [x] Ejecuté `flutter analyze`.
- [x] Ejecuté `flutter test`.
- [x] No incluí contraseñas, tokens ni credenciales.
- [x] No modifiqué módulos asignados a otros integrantes.
- [x] Documenté cualquier cambio en archivos compartidos.
- [x] La aplicación inicia correctamente en Android.

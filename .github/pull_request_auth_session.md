# feat(auth): completar perfil y cerrar flujo de clave temporal

**Rama:** `feature/auth-session` → `dev`  
**Commit:** `55b10ca`

## Módulo

Auth / Sesión / Router

## Cambios realizados

Cierra el flujo de autenticación pendiente según OpenAPI: completar perfil en primer acceso y recuperación con clave temporal.

### Completar perfil (primer acceso)

- Nuevo modelo `CompleteProfileRequest` y endpoint `PUT /me/profile`.
- Pantalla `CompleteProfileView` en `/complete-profile`.
- El modelo `User` ahora incluye `profileCompleted`, `cedula`, `gender` y `birthDate`.
- Guard de router: si el usuario está autenticado y `profileCompleted != true`, se fuerza `/complete-profile`.
- Validaciones nuevas (nombre, cédula de 11 dígitos, género, fecha de nacimiento).

### Recuperación de contraseña (clave temporal)

- Tras `forgot-password`, se redirige al login con email precargado y mensaje de guía.
- El flujo correcto es: correo con clave temporal → login → cambiar contraseña (no hay OTP en la API).

### Cambio de contraseña forzado

- Flag en sesión `requiresPasswordChange` al iniciar sesión desde recuperación.
- Prioridad de redirección autenticada:
  1. `requiresPasswordChange` → `/change-password`
  2. `!profileCompleted` → `/complete-profile`
  3. Home normal
- `ChangePasswordView` en modo obligatorio (sin volver atrás; opción de cerrar sesión).

### Tests

- Cobertura de views, viewmodels, repositorio, modelos y smoke del flujo.

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

**Completar perfil**

- Registrar o iniciar sesión con un usuario cuyo `profileCompleted` sea `false`.
- Verificar redirección a Completar perfil.
- Completar datos válidos y confirmar que luego permite continuar al home.

**Recuperar contraseña**

- En Olvidé mi contraseña, enviar un email válido.
- Abrir el correo, copiar la clave temporal.
- En login, iniciar sesión con esa clave.
- Verificar redirección obligatoria a Cambiar contraseña.
- Cambiar la clave y confirmar acceso (y completar perfil si aplica).

3. **Condiciones esperadas**

- No se puede omitir Completar perfil si el perfil está incompleto.
- No se puede omitir Cambiar contraseña tras login con clave temporal.
- `flutter test` pasa.
- La app inicia correctamente en Android/web.

## Evidencias

- (Agregar capturas de Completar perfil, login con clave temporal y Cambiar contraseña forzado)

## Checklist

- [x] Mi rama parte de una versión actualizada de `dev`.
- [x] Ejecuté `dart format .`.
- [x] Ejecuté `flutter analyze`.
- [x] Ejecuté `flutter test`.
- [x] No incluí contraseñas, tokens ni credenciales.
- [x] No modifiqué módulos asignados a otros integrantes.
- [x] Documenté cualquier cambio en archivos compartidos.
- [ ] La aplicación inicia correctamente en Android.

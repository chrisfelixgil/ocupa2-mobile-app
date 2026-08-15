import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_feedback_message.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:ocupa2/features/auth/presentation/widgets/password_field.dart';
import 'package:provider/provider.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({this.isRequired = false, super.key});

  final bool isRequired;

  @override
  State<ChangePasswordView> createState() {
    return _ChangePasswordViewState();
  }
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  static const String _passwordField = 'password';
  static const String _confirmPasswordField = 'confirmPassword';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthViewModel>().resetFeedback();
      }
    });
  }

  String? _currentPassword() {
    final Object? value = _formKey.currentState?.fields[_passwordField]?.value;

    return value is String ? value : null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final FormBuilderState? formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    final Map<String, dynamic> values = formState.value;
    final bool wasRequired = widget.isRequired;

    final bool success = await context.read<AuthViewModel>().changePassword(
      password: values[_passwordField] as String,
    );

    if (!success || !mounted) {
      return;
    }

    formState.reset();

    if (wasRequired) {
      context.go(RoutePaths.home);
    }
  }

  Future<void> _logout(SessionViewModel session) async {
    final bool success = await session.logout();

    if (!success && mounted) {
      final String message =
          session.sessionActionErrorMessage ??
          'No fue posible cerrar la sesión.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();
    final bool isBusy = authViewModel.isLoading || session.isLoggingOut;

    return PopScope(
      canPop: !widget.isRequired,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.isRequired
                        ? const SizedBox(width: 48)
                        : IconButton(
                            onPressed: isBusy ? null : _goBack,
                            tooltip: 'Volver',
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.text,
                              size: 20,
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    size: 24,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.isRequired
                                    ? 'Actualiza tu clave temporal'
                                    : 'Cambiar contraseña',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 24,
                                  fontWeight: AppTypography.bold,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.isRequired
                                    ? 'Iniciaste sesión con una clave temporal. '
                                          'Debes crear una nueva contraseña para continuar.'
                                    : 'Crea una nueva contraseña segura que no '
                                          'uses en otros sitios.',
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: AppTypography.regular,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const _FieldLabel(text: 'Nueva contraseña'),
                              PasswordField(
                                key: const Key('change_password_field'),
                                name: _passwordField,
                                label: 'Nueva contraseña',
                                hintText: 'Ingresa nueva contraseña',
                                showFloatingLabel: false,
                                enabled: !isBusy,
                                validator: AppValidators.newPassword(),
                                autofillHints: const <String>[
                                  AutofillHints.newPassword,
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Debe tener al menos 6 caracteres.',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 12,
                                  fontWeight: AppTypography.regular,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(
                                text: 'Confirmar nueva contraseña',
                              ),
                              PasswordField(
                                key: const Key(
                                  'change_confirm_password_field',
                                ),
                                name: _confirmPasswordField,
                                label: 'Confirmar nueva contraseña',
                                hintText: 'Repite la nueva contraseña',
                                showFloatingLabel: false,
                                enabled: !isBusy,
                                validator: AppValidators.confirmPassword(
                                  _currentPassword,
                                ),
                                autofillHints: const <String>[
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  _submit();
                                },
                              ),
                              const SizedBox(height: 32),
                              AuthFeedbackMessage(
                                errorMessage: authViewModel.errorMessage,
                                successMessage: authViewModel.successMessage,
                              ),
                              if (authViewModel.hasFeedback)
                                const SizedBox(height: AppSpacing.md),
                              AuthSubmitButton(
                                key: const Key(
                                  'change_password_submit_button',
                                ),
                                label: 'Actualizar contraseña',
                                loadingLabel: 'Actualizando...',
                                isLoading: authViewModel.isLoading,
                                onPressed: _submit,
                              ),
                              if (widget.isRequired) ...<Widget>[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  key: const Key(
                                    'change_password_logout_button',
                                  ),
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          _logout(session);
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.link,
                                  ),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: Text(
                                    session.isLoggingOut
                                        ? 'Cerrando sesión...'
                                        : 'Cerrar sesión',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: AppTypography.medium,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/route_paths.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();
    final SessionViewModel session = context.watch<SessionViewModel>();
    final bool isBusy = authViewModel.isLoading || session.isLoggingOut;

    return PopScope(
      canPop: !widget.isRequired,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambiar contraseña'),
          automaticallyImplyLeading: !widget.isRequired,
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Icon(
                        Icons.password_rounded,
                        size: 72,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          widget.isRequired
                              ? 'Actualiza tu clave temporal'
                              : 'Protege tu cuenta',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.isRequired
                            ? 'Iniciaste sesión con una clave temporal. '
                                  'Debes crear una nueva contraseña para continuar.'
                            : 'La nueva contraseña debe tener al menos '
                                  '6 caracteres.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              PasswordField(
                                key: const Key('change_password_field'),
                                name: _passwordField,
                                label: 'Nueva contraseña',
                                enabled: !isBusy,
                                validator: AppValidators.newPassword(),
                                autofillHints: const <String>[
                                  AutofillHints.newPassword,
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              PasswordField(
                                key: const Key('change_confirm_password_field'),
                                name: _confirmPasswordField,
                                label: 'Confirmar nueva contraseña',
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
                              const SizedBox(height: AppSpacing.lg),
                              AuthFeedbackMessage(
                                errorMessage: authViewModel.errorMessage,
                                successMessage: authViewModel.successMessage,
                              ),
                              if (authViewModel.hasFeedback)
                                const SizedBox(height: AppSpacing.md),
                              AuthSubmitButton(
                                key: const Key('change_password_submit_button'),
                                label: 'Actualizar contraseña',
                                loadingLabel: 'Actualizando...',
                                isLoading: authViewModel.isLoading,
                                icon: Icons.lock_reset_rounded,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Ocupa2 nunca mostrará ni almacenará tu '
                        'contraseña en texto visible.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (widget.isRequired) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        TextButton.icon(
                          key: const Key('change_password_logout_button'),
                          onPressed: isBusy
                              ? null
                              : () {
                                  _logout(session);
                                },
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_feedback_message.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:ocupa2/features/auth/presentation/widgets/password_field.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({
    this.initialEmail,
    this.fromPasswordRecovery = false,
    super.key,
  });

  final String? initialEmail;
  final bool fromPasswordRecovery;

  @override
  State<LoginView> createState() {
    return _LoginViewState();
  }
}

class _LoginViewState extends State<LoginView> {
  static const String _emailField = 'email';
  static const String _passwordField = 'password';

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

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final FormBuilderState? formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    final Map<String, dynamic> values = formState.value;

    final bool success = await context.read<AuthViewModel>().login(
      email: values[_emailField] as String,
      password: values[_passwordField] as String,
      requirePasswordChange: widget.fromPasswordRecovery,
    );

    if (success && mounted) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Ocupa2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 28,
                        fontWeight: AppTypography.bold,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bienvenido de nuevo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 22,
                          fontWeight: AppTypography.bold,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.fromPasswordRecovery
                            ? 'Usa la clave temporal enviada a tu correo. '
                                  'Después cámbiala desde Cambiar contraseña.'
                            : 'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: AppTypography.regular,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AutofillGroup(
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (widget.fromPasswordRecovery) ...<Widget>[
                                const AuthFeedbackMessage(
                                  successMessage:
                                      'Revisa tu correo e inicia sesión con la clave temporal.',
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              const _FieldLabel(text: 'Correo electrónico'),
                              FormBuilderTextField(
                                key: const Key('login_email_field'),
                                name: _emailField,
                                initialValue: widget.initialEmail,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.email(),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const <String>[
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'correo@ejemplo.com',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _FieldLabel(
                                text: widget.fromPasswordRecovery
                                    ? 'Clave temporal'
                                    : 'Contraseña',
                              ),
                              PasswordField(
                                key: const Key('login_password_field'),
                                name: _passwordField,
                                label: widget.fromPasswordRecovery
                                    ? 'Clave temporal'
                                    : 'Contraseña',
                                hintText: 'Ingresa tu contraseña',
                                showFloatingLabel: false,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.loginPassword(),
                                autofillHints: const <String>[
                                  AutofillHints.password,
                                ],
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  _submit();
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: authViewModel.isLoading
                                      ? null
                                      : () {
                                          context.goNamed(
                                            AppRouteNames.forgotPassword,
                                          );
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.link,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: AppTypography.medium,
                                    ),
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                  ),
                                ),
                              ),
                              AuthFeedbackMessage(
                                errorMessage: authViewModel.errorMessage,
                                successMessage: authViewModel.successMessage,
                              ),
                              if (authViewModel.hasFeedback)
                                const SizedBox(height: AppSpacing.md),
                              AuthSubmitButton(
                                key: const Key('login_submit_button'),
                                label: 'Iniciar sesión',
                                loadingLabel: 'Iniciando sesión...',
                                isLoading: authViewModel.isLoading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _OrDivider(),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          const Text(
                            '¿No tienes una cuenta?',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: authViewModel.isLoading
                                ? null
                                : () {
                                    context.goNamed(AppRouteNames.register);
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.link,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: AppTypography.medium,
                              ),
                            ),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}

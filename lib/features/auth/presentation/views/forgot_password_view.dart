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
import 'package:provider/provider.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() {
    return _ForgotPasswordViewState();
  }
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  static const String _emailField = 'email';
  static const String _referralMatriculaField = 'referralMatricula';

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
    final String email = values[_emailField] as String;

    final bool success = await context.read<AuthViewModel>().forgotPassword(
      email: email,
      referralMatricula: values[_referralMatriculaField] as String,
    );

    if (!success || !mounted) {
      return;
    }

    context.goNamed(
      AppRouteNames.login,
      queryParameters: <String, String>{'email': email, 'recovered': '1'},
    );
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.goNamed(AppRouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
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
                  child: IconButton(
                    onPressed: authViewModel.isLoading ? null : _goToLogin,
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: FormBuilder(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(36),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Recuperar contraseña',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 24,
                                fontWeight: AppTypography.bold,
                                fontFamily: AppTypography.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Ingresa el correo y la matrícula de referido. '
                              'Si coinciden, recibirás una clave temporal por '
                              'correo para iniciar sesión.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: AppTypography.regular,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const _FieldLabel(text: 'Correo electrónico'),
                            FormBuilderTextField(
                              key: const Key('forgot_email_field'),
                              name: _emailField,
                              enabled: !authViewModel.isLoading,
                              validator: AppValidators.email(),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                hintText: 'correo@ejemplo.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _FieldLabel(text: 'Matrícula de referido'),
                            FormBuilderTextField(
                              key: const Key(
                                'forgot_referral_matricula_field',
                              ),
                              name: _referralMatriculaField,
                              enabled: !authViewModel.isLoading,
                              validator: AppValidators.referralMatricula(),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onSubmitted: (_) {
                                _submit();
                              },
                              decoration: const InputDecoration(
                                hintText: '20121036',
                                helperText: 'Escríbela sin guion.',
                                prefixIcon: Icon(Icons.numbers_rounded),
                              ),
                            ),
                            const SizedBox(height: 24),
                            AuthFeedbackMessage(
                              errorMessage: authViewModel.errorMessage,
                              successMessage: authViewModel.successMessage,
                            ),
                            if (authViewModel.hasFeedback)
                              const SizedBox(height: AppSpacing.md),
                            AuthSubmitButton(
                              key: const Key('forgot_submit_button'),
                              label: 'Solicitar clave temporal',
                              loadingLabel: 'Procesando solicitud...',
                              isLoading: authViewModel.isLoading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed: authViewModel.isLoading
                                  ? null
                                  : _goToLogin,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.link,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: AppTypography.medium,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.arrow_back, size: 16),
                                  SizedBox(width: 8),
                                  Text('Volver al inicio de sesión'),
                                ],
                              ),
                            ),
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

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

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() {
    return _RegisterViewState();
  }
}

class _RegisterViewState extends State<RegisterView> {
  static const String _firstNameField = 'firstName';
  static const String _lastNameField = 'lastName';
  static const String _emailField = 'email';
  static const String _referralMatriculaField = 'referralMatricula';
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

    final bool success = await context.read<AuthViewModel>().register(
      email: values[_emailField] as String,
      firstName: values[_firstNameField] as String,
      lastName: values[_lastNameField] as String,
      password: values[_passwordField] as String,
      referralMatricula: values[_referralMatriculaField] as String,
    );

    if (success && mounted) {
      TextInput.finishAutofillContext();
    }
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AutofillGroup(
                        child: FormBuilder(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              const Text(
                                'Crea tu cuenta',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 24,
                                  fontWeight: AppTypography.bold,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Regístrate para comenzar a buscar o publicar '
                                'trabajos hoy mismo',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: AppTypography.regular,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const _FieldLabel(text: 'Nombre'),
                              FormBuilderTextField(
                                key: const Key('register_first_name_field'),
                                name: _firstNameField,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.requiredText(
                                  'El nombre',
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.givenName,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Tu nombre',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Apellido'),
                              FormBuilderTextField(
                                key: const Key('register_last_name_field'),
                                name: _lastNameField,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.requiredText(
                                  'El apellido',
                                ),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                autofillHints: const <String>[
                                  AutofillHints.familyName,
                                ],
                                decoration: const InputDecoration(
                                  hintText: 'Tu apellido',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Correo electrónico'),
                              FormBuilderTextField(
                                key: const Key('register_email_field'),
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
                                  'register_referral_matricula_field',
                                ),
                                name: _referralMatriculaField,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.referralMatricula(),
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: '20121036',
                                  helperText: 'Escríbela sin guion.',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Contraseña'),
                              PasswordField(
                                key: const Key('register_password_field'),
                                name: _passwordField,
                                label: 'Contraseña',
                                hintText: 'Mínimo 8 caracteres',
                                showFloatingLabel: false,
                                enabled: !authViewModel.isLoading,
                                validator: AppValidators.newPassword(),
                                autofillHints: const <String>[
                                  AutofillHints.newPassword,
                                ],
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel(text: 'Confirmar contraseña'),
                              PasswordField(
                                key: const Key(
                                  'register_confirm_password_field',
                                ),
                                name: _confirmPasswordField,
                                label: 'Confirmar contraseña',
                                hintText: 'Repite tu contraseña',
                                showFloatingLabel: false,
                                enabled: !authViewModel.isLoading,
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
                                key: const Key('register_submit_button'),
                                label: 'Crear cuenta',
                                loadingLabel: 'Creando cuenta...',
                                isLoading: authViewModel.isLoading,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  const Text(
                                    '¿Ya tienes una cuenta?',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: authViewModel.isLoading
                                        ? null
                                        : _goToLogin,
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
                                    child: const Text('Iniciar sesión'),
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

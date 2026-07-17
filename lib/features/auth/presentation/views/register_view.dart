import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_feedback_message.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_page_layout.dart';
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

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();

    return AuthPageLayout(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Crea tu cuenta',
      subtitle: 'Regístrate para publicar o solicitar empleos temporales.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('¿Ya tienes una cuenta?'),
          TextButton(
            onPressed: authViewModel.isLoading
                ? null
                : () {
                    context.goNamed(AppRouteNames.login);
                  },
            child: const Text('Inicia sesión'),
          ),
        ],
      ),
      child: AutofillGroup(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FormBuilderTextField(
                key: const Key('register_first_name_field'),
                name: _firstNameField,
                enabled: !authViewModel.isLoading,
                validator: AppValidators.requiredText('El nombre'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.givenName],
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormBuilderTextField(
                key: const Key('register_last_name_field'),
                name: _lastNameField,
                enabled: !authViewModel.isLoading,
                validator: AppValidators.requiredText('El apellido'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.familyName],
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormBuilderTextField(
                key: const Key('register_email_field'),
                name: _emailField,
                enabled: !authViewModel.isLoading,
                validator: AppValidators.email(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'usuario@itla.edu.do',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormBuilderTextField(
                key: const Key('register_referral_matricula_field'),
                name: _referralMatriculaField,
                enabled: !authViewModel.isLoading,
                validator: AppValidators.referralMatricula(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Matrícula de referido',
                  hintText: '20121036',
                  helperText: 'Escríbela sin guion.',
                  prefixIcon: Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                key: const Key('register_password_field'),
                name: _passwordField,
                label: 'Contraseña',
                enabled: !authViewModel.isLoading,
                validator: AppValidators.newPassword(),
                autofillHints: const <String>[AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                key: const Key('register_confirm_password_field'),
                name: _confirmPasswordField,
                label: 'Confirmar contraseña',
                enabled: !authViewModel.isLoading,
                validator: AppValidators.confirmPassword(_currentPassword),
                autofillHints: const <String>[AutofillHints.newPassword],
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
                key: const Key('register_submit_button'),
                label: 'Crear cuenta',
                loadingLabel: 'Creando cuenta...',
                isLoading: authViewModel.isLoading,
                icon: Icons.person_add_alt_1_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

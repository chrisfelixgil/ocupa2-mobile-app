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

class LoginView extends StatefulWidget {
  const LoginView({super.key});

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
    );

    if (success && mounted) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();

    return AuthPageLayout(
      icon: Icons.lock_outline_rounded,
      title: 'Inicia sesión en Ocupa2',
      subtitle: 'Accede con tu correo electrónico y contraseña.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Text('¿No tienes una cuenta?'),
          TextButton(
            onPressed: authViewModel.isLoading
                ? null
                : () {
                    context.goNamed(AppRouteNames.register);
                  },
            child: const Text('Regístrate'),
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
                key: const Key('login_email_field'),
                name: _emailField,
                enabled: !authViewModel.isLoading,
                validator: AppValidators.email(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'usuario@itla.edu.do',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                key: const Key('login_password_field'),
                name: _passwordField,
                label: 'Contraseña',
                enabled: !authViewModel.isLoading,
                validator: AppValidators.loginPassword(),
                autofillHints: const <String>[AutofillHints.password],
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
                          context.goNamed(AppRouteNames.forgotPassword);
                        },
                  child: const Text('¿Olvidaste tu contraseña?'),
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
                icon: Icons.login_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    await context.read<AuthViewModel>().forgotPassword(
      email: values[_emailField] as String,
      referralMatricula: values[_referralMatriculaField] as String,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authViewModel = context.watch<AuthViewModel>();

    return AuthPageLayout(
      icon: Icons.key_rounded,
      title: 'Recupera tu contraseña',
      subtitle:
          'Ingresa el correo y la matrícula de referido utilizados al crear la cuenta.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text('¿Recordaste tu contraseña?'),
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
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FormBuilderTextField(
              key: const Key('forgot_email_field'),
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
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FormBuilderTextField(
              key: const Key('forgot_referral_matricula_field'),
              name: _referralMatriculaField,
              enabled: !authViewModel.isLoading,
              validator: AppValidators.referralMatricula(),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onSubmitted: (_) {
                _submit();
              },
              decoration: const InputDecoration(
                labelText: 'Matrícula de referido',
                helperText: 'Escríbela sin guion.',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
              icon: Icons.mark_email_read_outlined,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

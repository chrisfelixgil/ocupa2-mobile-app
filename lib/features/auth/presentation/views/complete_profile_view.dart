import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_feedback_message.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:provider/provider.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() {
    return _CompleteProfileViewState();
  }
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  static const String _firstNameField = 'firstName';
  static const String _lastNameField = 'lastName';
  static const String _cedulaField = 'cedula';
  static const String _genderField = 'gender';
  static const String _birthDateField = 'birthDate';

  static const Map<String, String> _genderOptions = <String, String>{
    'masculino': 'Masculino',
    'femenino': 'Femenino',
    'otro': 'Otro',
  };

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

    await context.read<AuthViewModel>().completeProfile(
      firstName: values[_firstNameField] as String,
      lastName: values[_lastNameField] as String,
      cedula: values[_cedulaField] as String,
      gender: values[_genderField] as String,
      birthDate: values[_birthDateField] as DateTime,
    );
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
    final User? user = session.user;
    final bool isBusy = authViewModel.isLoading || session.isLoggingOut;

    return PopScope(
      canPop: false,
      child: AuthPageLayout(
        icon: Icons.assignment_ind_outlined,
        title: 'Completa tu perfil',
        subtitle:
            'Necesitamos estos datos para habilitar todas las funciones de tu cuenta.',
        footer: TextButton.icon(
          onPressed: isBusy
              ? null
              : () {
                  _logout(session);
                },
          icon: const Icon(Icons.logout_rounded),
          label: Text(
            session.isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
          ),
        ),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FormBuilderTextField(
                key: const Key('complete_profile_first_name_field'),
                name: _firstNameField,
                initialValue: user?.firstName,
                enabled: !isBusy,
                validator: AppValidators.profileName('El nombre'),
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
                key: const Key('complete_profile_last_name_field'),
                name: _lastNameField,
                initialValue: user?.lastName,
                enabled: !isBusy,
                validator: AppValidators.profileName('El apellido'),
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
                key: const Key('complete_profile_cedula_field'),
                name: _cedulaField,
                initialValue: user?.cedula,
                enabled: !isBusy,
                validator: AppValidators.cedula(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  labelText: 'Cédula',
                  hintText: '40212345678',
                  helperText: 'Escríbela sin guiones.',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FormBuilderDropdown<String>(
                key: const Key('complete_profile_gender_field'),
                name: _genderField,
                initialValue: user?.gender,
                enabled: !isBusy,
                validator: AppValidators.gender(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Género',
                  prefixIcon: Icon(Icons.people_outline_rounded),
                ),
                items: _genderOptions.entries.map((
                  MapEntry<String, String> option,
                ) {
                  return DropdownMenuItem<String>(
                    value: option.key,
                    child: Text(option.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              FormBuilderDateTimePicker(
                key: const Key('complete_profile_birth_date_field'),
                name: _birthDateField,
                initialValue: user?.birthDate,
                enabled: !isBusy,
                inputType: InputType.date,
                lastDate: DateUtils.dateOnly(DateTime.now()),
                validator: AppValidators.birthDate(),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
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
                key: const Key('complete_profile_submit_button'),
                label: 'Guardar perfil',
                loadingLabel: 'Guardando perfil...',
                isLoading: authViewModel.isLoading,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

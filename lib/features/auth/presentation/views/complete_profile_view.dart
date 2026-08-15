import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/auth/data/models/user.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:ocupa2/features/auth/presentation/viewmodels/session_view_model.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_feedback_message.dart';
import 'package:ocupa2/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:provider/provider.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({this.editing = false, super.key});

  final bool editing;

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

    final bool success = await context.read<AuthViewModel>().completeProfile(
      firstName: values[_firstNameField] as String,
      lastName: values[_lastNameField] as String,
      cedula: values[_cedulaField] as String,
      gender: values[_genderField] as String,
      birthDate: values[_birthDateField] as DateTime,
    );

    if (success && widget.editing && mounted) {
      Navigator.of(context).pop();
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
    final User? user = session.user;
    final bool isBusy = authViewModel.isLoading || session.isLoggingOut;

    return PopScope(
      canPop: widget.editing,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FormBuilder(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (widget.editing) ...<Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          widget.editing
                              ? 'Editar perfil'
                              : 'Completa tu perfil',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: AppTypography.bold,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.editing
                              ? 'Actualiza tus datos de identidad'
                              : 'Solo tomará un minuto para validar tu identidad',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _FieldLabel(text: 'Nombre'),
                        FormBuilderTextField(
                          key: const Key('complete_profile_first_name_field'),
                          name: _firstNameField,
                          initialValue: user?.firstName,
                          enabled: !isBusy,
                          validator: AppValidators.profileName('El nombre'),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.givenName,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Ej. Christian',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel(text: 'Apellido'),
                        FormBuilderTextField(
                          key: const Key('complete_profile_last_name_field'),
                          name: _lastNameField,
                          initialValue: user?.lastName,
                          enabled: !isBusy,
                          validator: AppValidators.profileName('El apellido'),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const <String>[
                            AutofillHints.familyName,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Ej. Martínez',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel(text: 'Cédula'),
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
                            hintText: '00100000000',
                            helperText: 'Escríbela sin guiones.',
                            prefixIcon: Icon(Icons.info_outline),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel(text: 'Género'),
                        FormBuilderDropdown<String>(
                          key: const Key('complete_profile_gender_field'),
                          name: _genderField,
                          initialValue: user?.gender,
                          enabled: !isBusy,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.chevron_right,
                            color: AppColors.text,
                          ),
                          validator: AppValidators.gender(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: const InputDecoration(
                            hintText: 'Selecciona tu género',
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
                        const SizedBox(height: 16),
                        const _FieldLabel(text: 'Fecha de nacimiento'),
                        FormBuilderDateTimePicker(
                          key: const Key(
                            'complete_profile_birth_date_field',
                          ),
                          name: _birthDateField,
                          initialValue: user?.birthDate,
                          enabled: !isBusy,
                          inputType: InputType.date,
                          format: DateFormat('dd / MM / yyyy'),
                          lastDate: DateUtils.dateOnly(DateTime.now()),
                          validator: AppValidators.birthDate(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'DD / MM / AAAA',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthFeedbackMessage(
                          errorMessage: authViewModel.errorMessage,
                          successMessage: authViewModel.successMessage,
                        ),
                        if (authViewModel.hasFeedback)
                          const SizedBox(height: AppSpacing.md),
                        AuthSubmitButton(
                          key: const Key('complete_profile_submit_button'),
                          label: widget.editing
                              ? 'Guardar cambios'
                              : 'Guardar y continuar',
                          loadingLabel: 'Guardando perfil...',
                          isLoading: authViewModel.isLoading,
                          onPressed: _submit,
                        ),
                        if (!widget.editing) ...<Widget>[
                          const SizedBox(height: 16),
                          TextButton.icon(
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

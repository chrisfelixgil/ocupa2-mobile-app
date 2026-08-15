import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

abstract final class AppValidators {
  static FormFieldValidator<String> requiredText(String fieldName) {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(errorText: '$fieldName es obligatorio.'),
      (String? value) {
        if (value != null && value.trim().isEmpty) {
          return '$fieldName es obligatorio.';
        }

        return null;
      },
    ]);
  }

  static FormFieldValidator<String> email() {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(errorText: 'El correo es obligatorio.'),
      FormBuilderValidators.email(
        errorText: 'Ingresa un correo electrónico válido.',
      ),
    ]);
  }

  static FormFieldValidator<String> profileName(String fieldName) {
    return FormBuilderValidators.compose([
      requiredText(fieldName),
      (String? value) {
        final String normalizedValue = value?.trim() ?? '';

        if (normalizedValue.isNotEmpty && normalizedValue.length < 2) {
          return '$fieldName debe tener al menos 2 caracteres.';
        }

        return null;
      },
    ]);
  }

  static FormFieldValidator<String> cedula() {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(errorText: 'La cédula es obligatoria.'),
      (String? value) {
        final String normalizedValue = (value ?? '').replaceAll(
          RegExp(r'[\s-]'),
          '',
        );

        if (normalizedValue.isEmpty) {
          return null;
        }

        if (!RegExp(r'^\d{11}$').hasMatch(normalizedValue)) {
          return 'La cédula debe contener 11 dígitos.';
        }

        return null;
      },
    ]);
  }

  static FormFieldValidator<String> gender() {
    return FormBuilderValidators.required(
      errorText: 'El género es obligatorio.',
    );
  }

  static FormFieldValidator<DateTime> birthDate() {
    return (DateTime? value) {
      if (value == null) {
        return 'La fecha de nacimiento es obligatoria.';
      }

      final DateTime today = DateUtils.dateOnly(DateTime.now());

      if (DateUtils.dateOnly(value).isAfter(today)) {
        return 'La fecha de nacimiento no puede ser futura.';
      }

      return null;
    };
  }

  static FormFieldValidator<String> loginPassword() {
    return FormBuilderValidators.required(
      errorText: 'La contraseña es obligatoria.',
    );
  }

  static FormFieldValidator<String> newPassword() {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(
        errorText: 'La contraseña es obligatoria.',
      ),
      FormBuilderValidators.minLength(
        6,
        errorText: 'La contraseña debe tener al menos 6 caracteres.',
      ),
    ]);
  }

  static FormFieldValidator<String> referralMatricula() {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(
        errorText: 'La matrícula de referido es obligatoria.',
      ),
      (String? value) {
        final String normalizedValue = value?.trim() ?? '';

        if (normalizedValue.isEmpty) {
          return null;
        }

        final bool containsOnlyDigits = RegExp(
          r'^\d+$',
        ).hasMatch(normalizedValue);

        if (!containsOnlyDigits) {
          return 'La matrícula debe contener solamente números.';
        }

        return null;
      },
    ]);
  }

  static FormFieldValidator<String> confirmPassword(
    String? Function() passwordProvider,
  ) {
    return FormBuilderValidators.compose([
      FormBuilderValidators.required(errorText: 'Confirma la contraseña.'),
      (String? value) {
        if (value != passwordProvider()) {
          return 'Las contraseñas no coinciden.';
        }

        return null;
      },
    ]);
  }
}

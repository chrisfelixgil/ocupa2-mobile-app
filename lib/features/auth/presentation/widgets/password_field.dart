import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.name,
    required this.label,
    required this.validator,
    required this.enabled,
    required this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.hintText,
    this.showFloatingLabel = true,
    super.key,
  });

  final String name;
  final String label;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final Iterable<String> autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String?>? onSubmitted;
  final String? hintText;
  final bool showFloatingLabel;

  @override
  State<PasswordField> createState() {
    return _PasswordFieldState();
  }
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: widget.name,
      enabled: widget.enabled,
      obscureText: _obscureText,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.showFloatingLabel ? widget.label : null,
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: widget.enabled
              ? () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                }
              : null,
          tooltip: _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

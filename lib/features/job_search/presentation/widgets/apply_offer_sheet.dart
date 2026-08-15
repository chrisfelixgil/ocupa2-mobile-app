import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/models/offer_question.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:provider/provider.dart';

Future<bool> showApplyOfferSheet({
  required BuildContext context,
  required Offer offer,
  required OfferDetailViewModel viewModel,
}) async {
  final bool? submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      return ChangeNotifierProvider<OfferDetailViewModel>.value(
        value: viewModel,
        child: ApplyOfferSheet(offer: offer),
      );
    },
  );

  return submitted == true;
}

class ApplyOfferSheet extends StatefulWidget {
  const ApplyOfferSheet({required this.offer, super.key});

  final Offer offer;

  @override
  State<ApplyOfferSheet> createState() => _ApplyOfferSheetState();
}

class _ApplyOfferSheetState extends State<ApplyOfferSheet> {
  static const String _commentField = 'comment';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    final FormBuilderState? formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    final Map<String, dynamic> values = formState.value;
    final OfferDetailViewModel viewModel = context.read<OfferDetailViewModel>();

    final List<ApplyAnswer> answers = widget.offer.questions
        .where((OfferQuestion question) => question.id != null)
        .map((OfferQuestion question) {
          final Object? rawValue = values[question.id];
          final String value = switch (rawValue) {
            final DateTime date => date.toIso8601String(),
            final bool flag => flag.toString(),
            null => '',
            _ => rawValue.toString(),
          };

          return ApplyAnswer(questionId: question.id!, value: value);
        })
        .toList();

    final bool success = await viewModel.apply(
      comment: (values[_commentField] as String).trim(),
      answers: answers,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final OfferDetailViewModel viewModel = context.watch<OfferDetailViewModel>();
    final bool enabled = !viewModel.isSubmittingApplication;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: FormBuilder(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Aplicar a esta oferta',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: enabled
                            ? () => Navigator.of(context).pop(false)
                            : null,
                        icon: const Icon(Icons.cancel_outlined, size: 22),
                        color: AppColors.text,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Por qué eres una buena opción?',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FormBuilderTextField(
                    name: _commentField,
                    maxLines: 4,
                    minLines: 3,
                    enabled: enabled,
                    validator: (String? value) {
                      final String text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return 'Explica por qué eres apto para este puesto. No dejes este espacio vacío.';
                      }
                      if (text.length < 20) {
                        return 'Escribe un poco más: cuenta tu experiencia o habilidades para este puesto (mínimo 20 caracteres).';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText:
                          'Escribe un breve mensaje describiendo tu experiencia relevante...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.offer.questions.map((OfferQuestion question) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuestionField(
                        question: question,
                        enabled: enabled,
                      ),
                    );
                  }),
                  if (viewModel.applyErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        viewModel.applyErrorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  FilledButton(
                    onPressed: enabled ? _submit : null,
                    child: viewModel.isSubmittingApplication
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Enviar aplicación',
                            style: TextStyle(fontSize: 14),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: enabled
                        ? () => Navigator.of(context).pop(false)
                        : null,
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({required this.question, required this.enabled});

  final OfferQuestion question;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (question.id == null) {
      return const SizedBox.shrink();
    }

    final String? Function(String?)? textValidator = question.required
        ? AppValidators.requiredText(question.label)
        : null;

    switch (question.type) {
      case 'date':
        final String? Function(DateTime?)? dateValidator = question.required
            ? (DateTime? value) {
                if (value == null) {
                  return '${question.label} es obligatorio.';
                }
                return null;
              }
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question.label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 6),
            FormBuilderDateTimePicker(
              name: question.id!,
              enabled: enabled,
              inputType: InputType.date,
              validator: dateValidator,
              decoration: const InputDecoration(
                hintText: 'Selecciona fecha...',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
              ),
            ),
          ],
        );

      case 'select':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question.label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 6),
            FormBuilderDropdown<String>(
              name: question.id!,
              enabled: enabled,
              validator: textValidator,
              decoration: const InputDecoration(
                hintText: 'Selecciona una opción...',
              ),
              items: question.options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ],
        );

      case 'check':
        return FormBuilderCheckbox(
          name: question.id!,
          enabled: enabled,
          initialValue: false,
          title: Text(question.label),
        );

      case 'text':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              question.label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 6),
            FormBuilderTextField(
              name: question.id!,
              enabled: enabled,
              validator: textValidator,
              decoration: const InputDecoration(
                hintText: 'Escribe tu respuesta...',
              ),
            ),
          ],
        );
    }
  }
}

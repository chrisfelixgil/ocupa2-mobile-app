import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/job_search/data/models/apply_request.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/models/offer_question.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_status.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:provider/provider.dart';

class OfferDetailView extends StatelessWidget {
  const OfferDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final OfferDetailViewModel viewModel = context.watch<OfferDetailViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la oferta')),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, OfferDetailViewModel viewModel) {
    return switch (viewModel.status) {
      OfferDetailStatus.idle || OfferDetailStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
      OfferDetailStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(viewModel.errorMessage ?? 'Ocurrió un error.'),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: viewModel.load,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      OfferDetailStatus.loaded =>
        // Siempre mostramos el contenido del formulario
        _OfferDetailContent(
          offer: viewModel.offer!,
          viewModel: viewModel,
        ),
    };
  }
}

// Eliminamos la clase _ApplicationSubmittedView (ya no se usa)

class _OfferDetailContent extends StatefulWidget {
  const _OfferDetailContent({required this.offer, required this.viewModel});

  final Offer offer;
  final OfferDetailViewModel viewModel;

  @override
  State<_OfferDetailContent> createState() => _OfferDetailContentState();
}

class _OfferDetailContentState extends State<_OfferDetailContent> {
  static const String _commentField = 'comment';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit() async {
    final FormBuilderState? formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    final Map<String, dynamic> values = formState.value;

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

    // Llamamos al método apply del viewModel
    await widget.viewModel.apply(
      comment: (values[_commentField] as String).trim(),
      answers: answers,
    );

    // Después de la llamada, verificamos si hubo error
    // Suponemos que viewModel.applyErrorMessage es null si fue exitoso
    // (o usamos un flag como applicationSubmitted si prefieres)
    final bool success = widget.viewModel.applyErrorMessage == null;

    if (success && mounted) {
      // Mostrar diálogo de éxito
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('¡Aplicación enviada!'),
            content: const Text(
              'Tu postulación ha sido registrada. Puedes seguir explorando otras ofertas.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // cierra el diálogo
                },
                child: const Text('Seguir explorando'),
              ),
            ],
          );
        },
      );

      // Si el widget sigue montado, salimos de la pantalla de detalle
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
    // Si falla, el error ya se muestra en el formulario (ver abajo)
  }

  @override
  Widget build(BuildContext context) {
    final Offer offer = widget.offer;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (offer.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                offer.photoUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(offer.displayJobType, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(offer.address, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              Chip(label: Text(offer.contractType)),
              if (offer.paymentAmount != null)
                Chip(
                  label: Text(
                    '${offer.paymentAmount} ${offer.paymentCurrency ?? ''}'
                        .trim(),
                  ),
                ),
              if (offer.deadline != null)
                Chip(
                  label: Text(
                    'Aplica antes del '
                    '${offer.deadline!.day}/${offer.deadline!.month}/${offer.deadline!.year}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Descripción', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(offer.description, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('Aplicar a esta oferta', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FormBuilderTextField(
                  name: _commentField,
                  maxLines: 3,
                  enabled: !widget.viewModel.isSubmittingApplication,
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
                    labelText: '¿Por qué eres apto para este puesto?',
                    alignLabelWithHint: true,
                    helperText:
                        'Cuenta tu experiencia o habilidades. Mínimo 20 caracteres.',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...offer.questions.map((OfferQuestion question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _QuestionField(
                      question: question,
                      enabled: !widget.viewModel.isSubmittingApplication,
                    ),
                  );
                }),
                if (widget.viewModel.applyErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      widget.viewModel.applyErrorMessage!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                FilledButton(
                  onPressed: widget.viewModel.isSubmittingApplication
                      ? null
                      : _submit,
                  child: widget.viewModel.isSubmittingApplication
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar aplicación'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
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

        return FormBuilderDateTimePicker(
          name: question.id!,
          enabled: enabled,
          inputType: InputType.date,
          validator: dateValidator,
          decoration: InputDecoration(labelText: question.label),
        );

      case 'select':
        return FormBuilderDropdown<String>(
          name: question.id!,
          enabled: enabled,
          validator: textValidator,
          decoration: InputDecoration(labelText: question.label),
          items: question.options.map((String option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
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
        return FormBuilderTextField(
          name: question.id!,
          enabled: enabled,
          validator: textValidator,
          decoration: InputDecoration(labelText: question.label),
        );
    }
  }
}
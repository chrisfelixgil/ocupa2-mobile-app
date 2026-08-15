import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_posting/data/models/offer_question.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/offer_detail_status.dart';
import 'package:ocupa2/features/job_posting/presentation/viewmodels/offer_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/data/models/experience.dart';
import 'package:provider/provider.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class ApplicantDetailView extends StatelessWidget {
  const ApplicantDetailView({
    required this.offerId,
    required this.applicationId,
    super.key,
  });

  final String offerId;
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    final JobPostingOfferDetailViewModel viewModel =
        context.watch<JobPostingOfferDetailViewModel>();

    Application? applicant;
    for (final Application item in viewModel.applicants) {
      if (item.id == applicationId) {
        applicant = item;
        break;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Perfil del candidato',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, viewModel, applicant)),
            if (viewModel.status == JobPostingOfferDetailStatus.loaded &&
                applicant != null)
              _ActionFooter(
                applicant: applicant,
                isUpdating: viewModel.isUpdatingApplicant,
                hasWinner: viewModel.hasWinner,
                onSelectFinalist: () => _runAction(
                  context,
                  viewModel.updateApplicantStatus(
                    applicationId: applicant!.id,
                    status: 'finalist',
                  ),
                ),
                onSelectWinner: () => _confirmWinner(
                  context,
                  applicant!,
                  () => viewModel.updateApplicantStatus(
                    applicationId: applicant!.id,
                    status: 'winner',
                  ),
                ),
                onDiscard: () => _confirmDiscard(
                  context,
                  applicant!,
                  () => viewModel.updateApplicantStatus(
                    applicationId: applicant!.id,
                    status: 'discarded',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    JobPostingOfferDetailViewModel viewModel,
    Application? applicant,
  ) {
    switch (viewModel.status) {
      case JobPostingOfferDetailStatus.idle:
      case JobPostingOfferDetailStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case JobPostingOfferDetailStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  viewModel.errorMessage ??
                      'No fue posible cargar el candidato.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => viewModel.load(offerId),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case JobPostingOfferDetailStatus.loaded:
        if (applicant == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se encontró este candidato.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => viewModel.load(offerId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              _ProfileHeader(applicant: applicant),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if ((applicant.comment ?? '').trim().isNotEmpty) ...<Widget>[
                      const _SectionTitle('Comentario de aplicación'),
                      const SizedBox(height: 8),
                      _BoxedText('"${applicant.comment!.trim()}"'),
                      const SizedBox(height: 20),
                    ],
                    if (_visibleAnswers(applicant, viewModel).isNotEmpty) ...<Widget>[
                      const _SectionTitle('Respuestas'),
                      const SizedBox(height: 8),
                      ..._visibleAnswers(applicant, viewModel).map(
                        (ApplicationAnswer answer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AnswerCard(answer: answer),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (applicant.applicantExperiences.isNotEmpty) ...<Widget>[
                      const _SectionTitle('Experiencia laboral'),
                      const SizedBox(height: 8),
                      ...applicant.applicantExperiences.map(
                        (Experience experience) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ExperienceCard(experience: experience),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _RateCard(
                      rating: applicant.rating,
                      enabled: !viewModel.isUpdatingApplicant,
                      onRate: (int value) => _runAction(
                        context,
                        viewModel.rateApplicant(
                          applicationId: applicant.id,
                          rating: value,
                        ),
                      ),
                    ),
                    if ((viewModel.errorMessage ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.applicant});

  final Application applicant;

  @override
  Widget build(BuildContext context) {
    final String meta = applicant.applicantMetaLabel;
    final int rating = applicant.rating ?? 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: <Widget>[
            Text(
              applicant.applicantDisplayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            if (meta.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                meta,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ...List<Widget>.generate(5, (int index) {
                  final bool filled = rating > index;
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: AppColors.primary,
                  );
                }),
                if (applicant.ratingLabel.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    applicant.ratingLabel,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _StatusChip(
              status: applicant.status,
              label: 'Estado: ${applicant.displayStatusLabel}',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        fontWeight: AppTypography.bold,
      ),
    );
  }
}

class _BoxedText extends StatelessWidget {
  const _BoxedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            height: 20 / 13,
            fontWeight: AppTypography.regular,
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final ApplicationAnswer answer;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              answer.question,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              answer.value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({required this.experience});

  final Experience experience;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = experience.certificateImage?.trim();
    final bool hasCertificate = imageUrl != null && imageUrl.isNotEmpty;
    final String meta = experience.metaLabel;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    experience.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (meta.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      meta,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (experience.description.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                experience.description,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ],
            if (hasCertificate) ...<Widget>[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _openCertificate(context, experience, imageUrl),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 12,
                      color: _successGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Ver certificado',
                      style: TextStyle(
                        color: _successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({
    required this.rating,
    required this.enabled,
    required this.onRate,
  });

  final int? rating;
  final bool enabled;
  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final int current = rating ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            const Text(
              'Calificar candidato',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(5, (int index) {
                final int value = index + 1;
                final bool filled = current >= value;
                return IconButton(
                  onPressed: enabled ? () => onRate(value) : null,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) =
        switch (status.toLowerCase().trim()) {
      'winner' => (
          _successGreen.withValues(alpha: 0.08),
          _successGreen,
        ),
      'discarded' => (
          _discardRed.withValues(alpha: 0.08),
          _discardRed,
        ),
      _ => (
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.primary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: AppTypography.bold,
        ),
      ),
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({
    required this.applicant,
    required this.isUpdating,
    required this.hasWinner,
    required this.onSelectFinalist,
    required this.onSelectWinner,
    required this.onDiscard,
  });

  final Application applicant;
  final bool isUpdating;
  final bool hasWinner;
  final VoidCallback onSelectFinalist;
  final VoidCallback onSelectWinner;
  final VoidCallback onDiscard;

  String get _status => applicant.status.toLowerCase().trim();

  bool get _showActions {
    if (hasWinner || _status == 'winner' || _status == 'discarded') {
      return false;
    }
    return _status == 'applied' || _status == 'finalist';
  }

  @override
  Widget build(BuildContext context) {
    if (!_showActions) {
      return const SizedBox.shrink();
    }

    final bool isFinalist = _status == 'finalist';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: isUpdating ? null : onDiscard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _discardRed,
                  backgroundColor: _discardRed.withValues(alpha: 0.08),
                  side: const BorderSide(color: _discardRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Descartar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: isUpdating
                    ? null
                    : (isFinalist ? onSelectWinner : onSelectFinalist),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isFinalist ? 'Elegir ganador' : 'Hacer finalista'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ApplicationAnswer> _visibleAnswers(
  Application applicant,
  JobPostingOfferDetailViewModel viewModel,
) {
  final List<OfferQuestion> questions = viewModel.offer?.questions ?? const <OfferQuestion>[];
  final List<ApplicationAnswer> resolved = <ApplicationAnswer>[];

  for (final ApplicationAnswer answer in applicant.answers) {
    final String question = _questionLabel(answer, questions);
    final String value = answer.value.trim();
    if (question.isEmpty && value.isEmpty) {
      continue;
    }
    resolved.add(
      ApplicationAnswer(
        questionId: answer.questionId,
        question: question.isEmpty ? 'Pregunta' : question,
        value: value.isEmpty ? 'Sin respuesta' : value,
      ),
    );
  }

  return resolved;
}

String _questionLabel(
  ApplicationAnswer answer,
  List<OfferQuestion> questions,
) {
  if (answer.question.trim().isNotEmpty) {
    return answer.question.trim();
  }

  final String? id = answer.questionId?.trim();
  if (id == null || id.isEmpty) {
    return '';
  }

  for (final OfferQuestion question in questions) {
    if ((question.id ?? '').trim() == id) {
      return question.label;
    }
  }
  return '';
}

Future<void> _runAction(BuildContext context, Future<bool> action) async {
  final bool success = await action;
  if (success || !context.mounted) {
    return;
  }

  final String? message =
      context.read<JobPostingOfferDetailViewModel>().errorMessage;
  if (message == null) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _confirmDiscard(
  BuildContext context,
  Application applicant,
  Future<bool> Function() onConfirm,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Descartar candidato'),
        content: Text(
          '¿Estás seguro de que quieres descartar a '
          '${applicant.applicantDisplayName}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await _runAction(context, onConfirm());
}

Future<void> _confirmWinner(
  BuildContext context,
  Application applicant,
  Future<bool> Function() onConfirm,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Elegir ganador'),
        content: Text(
          '¿Elegir a ${applicant.applicantDisplayName} como ganador? '
          'Se creará el contrato automáticamente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Elegir'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  await _runAction(context, onConfirm());
}

Future<void> _openCertificate(
  BuildContext context,
  Experience experience,
  String imageUrl,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close),
            ),
            title: Text(experience.title),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Text('No se pudo cargar el certificado');
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

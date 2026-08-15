import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_search/data/models/offer.dart';
import 'package:ocupa2/features/job_search/data/models/offer_question.dart';
import 'package:ocupa2/features/job_search/data/repositories/job_search_repository.dart';
import 'package:ocupa2/features/job_search/presentation/widgets/offer_display.dart';
import 'package:ocupa2/features/my_activity/data/models/application.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/applications_view_model.dart';
import 'package:provider/provider.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

class MyApplicationDetailView extends StatefulWidget {
  const MyApplicationDetailView({
    required this.applicationId,
    this.initialApplication,
    super.key,
  });

  final String applicationId;
  final Application? initialApplication;

  @override
  State<MyApplicationDetailView> createState() =>
      _MyApplicationDetailViewState();
}

class _MyApplicationDetailViewState extends State<MyApplicationDetailView> {
  Offer? _offer;
  bool _loadingOffer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _prepare();
      }
    });
  }

  Future<void> _prepare() async {
    final ApplicationsViewModel viewModel =
        context.read<ApplicationsViewModel>();
    Application? application = widget.initialApplication ??
        _findApplication(viewModel, widget.applicationId);

    if (application == null &&
        viewModel.status != ApplicationsStatus.success) {
      await viewModel.load();
      if (!mounted) {
        return;
      }
      application = _findApplication(viewModel, widget.applicationId);
    }

    final String? offerId = application?.offerId ?? application?.offer?.id;
    if (offerId == null || offerId.isEmpty) {
      return;
    }

    setState(() {
      _loadingOffer = true;
    });

    try {
      final Offer offer =
          await context.read<JobSearchRepository>().getOfferById(offerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _offer = offer;
        _loadingOffer = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingOffer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ApplicationsViewModel viewModel =
        context.watch<ApplicationsViewModel>();
    final Application? application = widget.initialApplication ??
        _findApplication(viewModel, widget.applicationId);

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
                      'Detalle de la aplicación',
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
            Expanded(
              child: _buildBody(context, viewModel, application),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ApplicationsViewModel viewModel,
    Application? application,
  ) {
    if (application == null) {
      if (viewModel.status == ApplicationsStatus.loading ||
          viewModel.status == ApplicationsStatus.idle ||
          _loadingOffer) {
        return const Center(child: CircularProgressIndicator());
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                viewModel.errorMessage ??
                    'No se encontró esta aplicación.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: viewModel.load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final Offer? offer = _offer ?? application.offer;
    final String description =
        (offer?.description.trim().isNotEmpty == true)
            ? offer!.description.trim()
            : application.displayDescription;
    final String jobType = offer?.displayJobType ?? application.displayTitle;
    final String? photoUrl = offer?.photoUrl ?? application.displayPhotoUrl;
    final String payment = offer == null
        ? 'A convenir'
        : OfferDisplay.paymentLabel(offer);
    final List<ApplicationAnswer> answers =
        _visibleAnswers(application, offer);

    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.load();
        await _prepare();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          _StatusChip(
            status: application.status,
            label: 'Estado: ${application.displayStatusLabel}',
          ),
          const SizedBox(height: 16),
          const _SectionTitle('La propuesta'),
          const SizedBox(height: 8),
          _ProposalCard(
            title: jobType,
            description: description,
            photoUrl: photoUrl,
            payment: payment,
            address: (offer?.address ?? application.offerAddress ?? '').trim(),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Calificación del contratante'),
          const SizedBox(height: 8),
          _RatingCard(rating: application.rating),
          const SizedBox(height: 16),
          const _SectionTitle('Mi aplicación'),
          const SizedBox(height: 8),
          _BoxedText(
            (application.comment ?? '').trim().isEmpty
                ? 'No enviaste un comentario al aplicar.'
                : '"${application.comment!.trim()}"',
          ),
          if (answers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            const _SectionTitle('Mis respuestas'),
            const SizedBox(height: 8),
            ...answers.map(
              (ApplicationAnswer answer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AnswerCard(answer: answer),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _appliedLabel(application.createdAt),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: AppTypography.regular,
            ),
          ),
        ],
      ),
    );
  }
}

Application? _findApplication(
  ApplicationsViewModel viewModel,
  String applicationId,
) {
  for (final Application item in viewModel.applications) {
    if (item.id == applicationId) {
      return item;
    }
  }
  return null;
}

List<ApplicationAnswer> _visibleAnswers(
  Application application,
  Offer? offer,
) {
  final List<OfferQuestion> questions =
      offer?.questions ?? const <OfferQuestion>[];
  final List<ApplicationAnswer> resolved = <ApplicationAnswer>[];

  for (final ApplicationAnswer answer in application.answers) {
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

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.title,
    required this.description,
    required this.payment,
    this.photoUrl,
    this.address = '',
  });

  final String title;
  final String description;
  final String payment;
  final String? photoUrl;
  final String address;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: _OfferPhoto(url: photoUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        payment,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ],
            if (address.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                address,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfferPhoto extends StatelessWidget {
  const _OfferPhoto({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: AppColors.border,
        child: Icon(Icons.work_outline, color: AppColors.text),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.border),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.border,
        child: Icon(Icons.work_outline, color: AppColors.text),
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({this.rating});

  final int? rating;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(5, (int index) {
                final bool filled = current > index;
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 22,
                  color: AppColors.primary,
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              rating == null
                  ? 'Aún no hay calificación'
                  : '${rating!.toDouble().toStringAsFixed(1)} de 5',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
      ),
    );
  }
}

String _appliedLabel(DateTime? date) {
  if (date == null) {
    return 'Aplicado: Sin fecha';
  }

  const List<String> months = <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  return 'Aplicado: ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

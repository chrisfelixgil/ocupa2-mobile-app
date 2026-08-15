import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contract_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_view_model.dart';
import 'package:provider/provider.dart';

const Color _successGreen = Color(0xFF16A34A);
const Color _discardRed = Color(0xFFEF4444);

const List<String> _months = <String>[
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

void _showContractMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String _formatContractDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
}

String _formatContractDateTime(DateTime date) {
  final int hour = date.hour > 12
      ? date.hour - 12
      : (date.hour == 0 ? 12 : date.hour);
  final String minute = date.minute.toString().padLeft(2, '0');
  final String suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${_formatContractDate(date)}, $hour:$minute $suffix';
}

String _toApiDate(DateTime date) {
  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _paymentLabel(Contract contract) {
  if (contract.salary == null) {
    return 'A convenir';
  }
  final String amount = _group(contract.salary!.round());
  final String currency = (contract.currency ?? 'DOP').toUpperCase();
  if (currency == 'USD' || currency == 'US\$') {
    return 'US\$$amount';
  }
  return 'RD\$$amount';
}

String _group(int value) {
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  if (value < 0) {
    return '-$buffer';
  }
  return buffer.toString();
}

class ContractDetailView extends StatefulWidget {
  const ContractDetailView({super.key});

  @override
  State<ContractDetailView> createState() => _ContractDetailViewState();
}

class _ContractDetailViewState extends State<ContractDetailView> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContractDetailViewModel viewModel =
        context.watch<ContractDetailViewModel>();
    final Contract? contract = viewModel.contract;

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
                      'Detalle del contrato',
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
            Expanded(child: _buildBody(context, viewModel)),
            if (viewModel.status == ContractsStatus.success && contract != null)
              _ContractFooter(
                contract: contract,
                isSaving: viewModel.isSaving,
                onSetTerms: () =>
                    _showSetTermsSheet(context, viewModel, contract),
                onAccept: () => _accept(context, viewModel),
                onReject: () => _reject(context, viewModel),
                onCancel: () => _showCancelDialog(context, viewModel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) {
    if (viewModel.status == ContractsStatus.loading ||
        viewModel.status == ContractsStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.status == ContractsStatus.error) {
      return _ErrorState(
        message: viewModel.errorMessage,
        onRetry: () {
          final String? contractId = viewModel.contract?.id;
          if (contractId != null) {
            viewModel.load(contractId);
          }
        },
      );
    }
    return _buildContent(context, viewModel);
  }

  Future<void> _accept(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) async {
    final bool accepted = await viewModel.acceptContract();
    if (!context.mounted) {
      return;
    }
    if (accepted) {
      final Contract? updated = viewModel.contract;
      if (updated != null) {
        context.read<ContractsViewModel>().updateContractInList(updated);
      }
      _showContractMessage(
        context,
        'Contrato aceptado. El estado ahora es activo.',
      );
    } else {
      _showMessage(
        context,
        viewModel.errorMessage ?? 'No fue posible aceptar el contrato.',
      );
    }
  }

  Future<void> _reject(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) async {
    final bool rejected = await viewModel.rejectContract();
    if (!context.mounted) {
      return;
    }
    if (rejected) {
      final Contract? updated = viewModel.contract;
      if (updated != null) {
        context.read<ContractsViewModel>().updateContractInList(updated);
      }
    } else {
      _showMessage(
        context,
        viewModel.errorMessage ?? 'No fue posible rechazar el contrato.',
      );
    }
  }

  Widget _buildContent(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) {
    final Contract? contract = viewModel.contract;
    if (contract == null) {
      return const Center(child: Text('No se encontró el contrato.'));
    }

    final String description = (contract.offerDescription ?? '').trim();
    final String? firstComment = contract.comments.isNotEmpty
        ? contract.comments.first.body.trim()
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: <Widget>[
        _StatusHero(contract: contract),
        const SizedBox(height: 16),
        const _SectionTitle('Trabajo'),
        const SizedBox(height: 8),
        _JobCard(
          title: contract.displayTitle,
          description: description,
        ),
        const SizedBox(height: 16),
        const _SectionTitle('Participantes'),
        const SizedBox(height: 8),
        _PartiesRow(contract: contract),
        const SizedBox(height: 16),
        const _SectionTitle('Términos del acuerdo'),
        const SizedBox(height: 8),
        _TermsCard(contract: contract),
        const SizedBox(height: 16),
        const _SectionTitle('Estado del proceso'),
        const SizedBox(height: 8),
        _TimelineCard(contract: contract),
        if (!contract.isActive &&
            firstComment != null &&
            firstComment.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const _SectionTitle('Comentarios adicionales'),
          const SizedBox(height: 8),
          _QuotedComment(text: firstComment),
        ],
        if ((contract.cancelJustification ?? '').trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          const _SectionTitle('Justificación'),
          const SizedBox(height: 8),
          _QuotedComment(text: contract.cancelJustification!.trim()),
        ],
        if (contract.isActive) ...<Widget>[
          const SizedBox(height: 16),
          _CommentsSection(
            comments: contract.comments,
            controller: _commentController,
            isSaving: viewModel.isSaving,
            onSend: () async {
              final bool success = await viewModel.addComment(
                _commentController.text,
              );
              if (!context.mounted) {
                return;
              }
              if (success) {
                _commentController.clear();
              } else {
                _showMessage(
                  context,
                  viewModel.errorMessage ??
                      'No fue posible agregar el comentario.',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _PhotosSection(
            photos: contract.photos,
            isSaving: viewModel.isSaving,
            onAddPhoto: () => _pickPhoto(context, viewModel),
          ),
        ],
      ],
    );
  }

  Future<void> _showSetTermsSheet(
    BuildContext context,
    ContractDetailViewModel viewModel,
    Contract contract,
  ) async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) {
        return _SetTermsSheet(
          contract: contract,
          viewModel: viewModel,
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (saved == true) {
      _showContractMessage(context, 'Términos guardados correctamente.');
    }
  }

  Future<void> _pickPhoto(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (file == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final TextEditingController descriptionController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Agregar descripción'),
          content: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Descripción'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Subir foto'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final bool uploaded = await viewModel.addPhoto(
      photoFile: file,
      description: descriptionController.text.trim(),
    );

    if (!context.mounted) return;
    if (!uploaded) {
      _showMessage(
        context,
        viewModel.errorMessage ?? 'No fue posible subir la foto.',
      );
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) async {
    final TextEditingController justificationController =
        TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar contrato'),
          content: TextField(
            controller: justificationController,
            decoration: const InputDecoration(labelText: 'Justificación'),
            maxLines: 4,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final bool cancelled = await viewModel.cancelContract(
      justificationController.text.trim(),
    );
    if (!context.mounted) return;
    if (cancelled) {
      final Contract? updated = viewModel.contract;
      if (updated != null) {
        context.read<ContractsViewModel>().updateContractInList(updated);
      }
      _showContractMessage(context, 'Contrato cancelado.');
    } else {
      _showMessage(
        context,
        viewModel.errorMessage ?? 'No fue posible cancelar el contrato.',
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    _showContractMessage(context, message);
  }
}

class _SetTermsSheet extends StatefulWidget {
  const _SetTermsSheet({
    required this.contract,
    required this.viewModel,
  });

  final Contract contract;
  final ContractDetailViewModel viewModel;

  @override
  State<_SetTermsSheet> createState() => _SetTermsSheetState();
}

class _SetTermsSheetState extends State<_SetTermsSheet> {
  late final TextEditingController _salaryController;
  late final TextEditingController _currencyController;
  late final TextEditingController _durationController;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final num? salaryValue = widget.contract.salary;
    _salaryController = TextEditingController(
      text: salaryValue != null ? salaryValue.toString() : '',
    );
    _currencyController = TextEditingController(
      text: widget.contract.currency ?? 'DOP',
    );
    _durationController = TextEditingController(
      text: widget.contract.duration ?? '',
    );
    _startDate = widget.contract.startDate;
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _currencyController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final num? salary = num.tryParse(_salaryController.text.trim());
    if (salary == null) {
      _showContractMessage(context, 'Ingresa un salario válido.');
      return;
    }

    if (_startDate == null) {
      _showContractMessage(context, 'Selecciona la fecha de inicio.');
      return;
    }

    final String duration = _durationController.text.trim();
    if (duration.isEmpty) {
      _showContractMessage(context, 'Ingresa la duración del contrato.');
      return;
    }

    final bool saved = await widget.viewModel.setTerms(
      salary: salary,
      currency: _currencyController.text.trim().isNotEmpty
          ? _currencyController.text.trim()
          : 'DOP',
      startDate: _toApiDate(_startDate!),
      duration: duration,
    );

    if (!mounted) {
      return;
    }

    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }

    _showContractMessage(
      context,
      widget.viewModel.errorMessage ?? 'No fue posible fijar los términos.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, Widget? child) {
        final bool isSaving = widget.viewModel.isSaving;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Fijar términos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _salaryController,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Salario'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _currencyController,
                enabled: !isSaving,
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: isSaving ? null : _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de inicio',
                    suffixIcon: Icon(Icons.calendar_today),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  child: Text(
                    _startDate == null
                        ? 'Selecciona una fecha'
                        : _formatContractDate(_startDate!),
                    style: TextStyle(
                      color: _startDate == null
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _durationController,
                enabled: !isSaving,
                decoration: const InputDecoration(
                  labelText: 'Duración',
                  hintText: 'Ej. 2 semanas',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSaving ? null : _save,
                  child: Text(isSaving ? 'Guardando...' : 'Guardar términos'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 13,
        fontWeight: AppTypography.bold,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final String eyebrow;
    final String title;
    String? subtitle;

    if (contract.isCancelled) {
      accent = AppColors.text;
      eyebrow = 'Contrato cancelado';
      title = 'Cancelado';
      subtitle = contract.cancelledAt == null
          ? null
          : 'Cancelado el ${_formatContractDate(contract.cancelledAt!)}';
    } else if (contract.isRejected) {
      accent = _discardRed;
      eyebrow = 'Contrato rechazado';
      title = 'Rechazado';
      subtitle = contract.createdAt == null
          ? null
          : 'Propuesta enviada el ${_formatContractDate(contract.createdAt!)}';
    } else if (contract.isActive) {
      accent = _successGreen;
      eyebrow = 'Contrato activo';
      title = 'En vigencia';
      subtitle = contract.acceptedAt == null
          ? null
          : 'Aceptado el ${_formatContractDate(contract.acceptedAt!)}';
    } else {
      accent = AppColors.primary;
      eyebrow = 'Propuesta de contrato';
      title = 'Pendiente de aceptación';
      subtitle = contract.createdAt == null
          ? 'Enviado por el contratante'
          : 'Enviado por el contratante el ${_formatContractDate(contract.createdAt!)}';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              eyebrow.toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: AppTypography.bold,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle,
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

class _JobCard extends StatelessWidget {
  const _JobCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
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
          if (description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.regular,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartiesRow extends StatelessWidget {
  const _PartiesRow({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _PartyCard(
            role: 'Contratante',
            name: contract.contratante?.nombre.trim().isNotEmpty == true
                ? contract.contratante!.nombre.trim()
                : 'Sin información',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PartyCard(
            role: 'Prestador',
            name: contract.contratado?.nombre.trim().isNotEmpty == true
                ? contract.contratado!.nombre.trim()
                : 'Sin información',
          ),
        ),
      ],
    );
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({required this.role, required this.name});

  final String role;
  final String name;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            role,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: AppTypography.regular,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final List<(String, String, bool)> rows = <(String, String, bool)>[
      ('Monto', _paymentLabel(contract), true),
      (
        'Duración',
        (contract.duration ?? '').trim().isNotEmpty
            ? contract.duration!.trim()
            : 'Sin definir',
        false,
      ),
      if (contract.startDate != null)
        (
          'Fecha de inicio',
          _formatContractDate(contract.startDate!),
          false,
        ),
    ];

    return _SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: TextStyle(
                      color: rows[i].$3 ? AppColors.primary : AppColors.text,
                      fontSize: 13,
                      fontWeight: rows[i].$3
                          ? AppTypography.bold
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final String workerName =
        (contract.contratado?.nombre.trim().isNotEmpty == true)
            ? contract.contratado!.nombre.trim()
            : 'el prestador';

    final List<_TimelineStep> steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Oferta de contrato enviada',
        subtitle: contract.createdAt == null
            ? null
            : _formatContractDateTime(contract.createdAt!),
        done: contract.createdAt != null || contract.isOngoing || contract.isClosed,
      ),
    ];

    if (contract.isRejected) {
      steps.add(
        const _TimelineStep(
          title: 'Contrato rechazado',
          subtitle: 'La propuesta no fue aceptada',
          done: true,
        ),
      );
    } else if (contract.isCancelled) {
      steps.add(
        _TimelineStep(
          title: 'Contrato cancelado',
          subtitle: contract.cancelledAt == null
              ? null
              : _formatContractDateTime(contract.cancelledAt!),
          done: true,
        ),
      );
    } else if (contract.isActive) {
      steps.add(
        _TimelineStep(
          title: 'Contrato aceptado',
          subtitle: contract.acceptedAt == null
              ? null
              : _formatContractDateTime(contract.acceptedAt!),
          done: true,
        ),
      );
    } else {
      steps.add(
        _TimelineStep(
          title: 'Pendiente firma de $workerName',
          subtitle: 'En espera',
          waiting: true,
        ),
      );
    }

    return _SurfaceCard(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++)
            _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    this.subtitle,
    this.done = false,
    this.waiting = false,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final bool waiting;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 20,
            child: Column(
              children: <Widget>[
                _TimelineDot(done: step.done, waiting: step.waiting),
                if (!isLast)
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: SizedBox(
                          width: 2,
                          height: double.infinity,
                          child: ColoredBox(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((step.subtitle ?? '').isNotEmpty)
                    Text(
                      step.subtitle!,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.done, required this.waiting});

  final bool done;
  final bool waiting;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _successGreen,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(Icons.check, size: 11, color: AppColors.surface),
          ),
        ),
      );
    }

    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: waiting ? AppColors.primary : AppColors.border,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuotedComment extends StatelessWidget {
  const _QuotedComment({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Text(
        '"$text"',
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: AppTypography.regular,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.controller,
    required this.isSaving,
    required this.onSend,
  });

  final List<ContractComment> comments;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Comentarios'),
        const SizedBox(height: 8),
        if (comments.isEmpty)
          const _SurfaceCard(
            child: Text(
              'Aún no hay comentarios.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        for (final ContractComment comment in comments) ...<Widget>[
          _SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        comment.by?.nombre.trim().isNotEmpty == true
                            ? comment.by!.nombre.trim()
                            : 'Anónimo',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (comment.createdAt != null)
                      Text(
                        _formatContractDate(comment.createdAt!),
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: AppTypography.regular,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.body,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe un comentario',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: isSaving ? null : onSend,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Enviar comentario'),
          ),
        ),
      ],
    );
  }
}

class _PhotosSection extends StatelessWidget {
  const _PhotosSection({
    required this.photos,
    required this.isSaving,
    required this.onAddPhoto,
  });

  final List<ContractPhoto> photos;
  final bool isSaving;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle('Fotos'),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          const _SurfaceCard(
            child: Text(
              'No hay fotos agregadas aún.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        for (final ContractPhoto photo in photos) ...<Widget>[
          _SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (photo.url.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      errorBuilder: (_, _, _) {
                        return const SizedBox(
                          height: 80,
                          child: Center(
                            child: Text('No se pudo cargar la foto'),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (photo.description.isNotEmpty)
                        Text(
                          photo.description,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                      if (photo.by != null || photo.createdAt != null)
                        Text(
                          '${photo.by?.nombre ?? 'Usuario'}'
                          '${photo.createdAt == null ? '' : ' · ${_formatContractDate(photo.createdAt!)}'}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: AppTypography.regular,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : onAddPhoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Agregar foto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContractFooter extends StatelessWidget {
  const _ContractFooter({
    required this.contract,
    required this.isSaving,
    required this.onSetTerms,
    required this.onAccept,
    required this.onReject,
    required this.onCancel,
  });

  final Contract contract;
  final bool isSaving;
  final VoidCallback onSetTerms;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    Widget? actions;
    if (contract.isContratante && contract.isPending) {
      actions = SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: isSaving ? null : onSetTerms,
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
          child: Text(
            isSaving
                ? 'Guardando...'
                : (contract.hasTerms ? 'Editar términos' : 'Fijar términos'),
          ),
        ),
      );
    } else if (contract.isContratado && contract.isPending) {
      actions = Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: _discardRed,
                backgroundColor: AppColors.surface,
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
              child: const Text('Rechazar contrato'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: isSaving ? null : onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: _successGreen,
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
              child: const Text('Aceptar contrato'),
            ),
          ),
        ],
      );
    } else if (contract.isActive) {
      actions = SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isSaving ? null : onCancel,
          style: OutlinedButton.styleFrom(
            foregroundColor: _discardRed,
            backgroundColor: AppColors.surface,
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
          child: const Text('Cancelar contrato'),
        ),
      );
    }

    if (actions == null) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: actions,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message ?? 'No fue posible cargar el contrato.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

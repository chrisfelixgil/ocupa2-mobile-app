import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/features/my_activity/data/models/contract.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_comment.dart';
import 'package:ocupa2/features/my_activity/data/models/contract_photo.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contract_detail_view_model.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/contracts_status.dart';
import 'package:provider/provider.dart';

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
    final ContractDetailViewModel viewModel = context
        .watch<ContractDetailViewModel>();

    Widget body;
    if (viewModel.status == ContractsStatus.loading ||
        viewModel.status == ContractsStatus.idle) {
      body = const Center(child: CircularProgressIndicator());
    } else if (viewModel.status == ContractsStatus.error) {
      body = _ErrorState(
        message: viewModel.errorMessage,
        onRetry: () {
          final String? contractId = viewModel.contract?.id;
          if (contractId != null) {
            viewModel.load(contractId);
          }
        },
      );
    } else {
      body = _buildContent(context, viewModel);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del contrato')),
      body: body,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ContractDetailViewModel viewModel,
  ) {
    final Contract? contract = viewModel.contract;
    if (contract == null) {
      return const Center(child: Text('No se encontró el contrato.'));
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        _ContractHeader(contract: contract),
        const SizedBox(height: AppSpacing.md),
        _InfoCard(
          title: 'Información básica',
          children: <Widget>[
            _InfoRow(label: 'Oferta', value: contract.displayTitle),
            if (contract.otherParty != null)
              _InfoRow(
                label: contract.isContratante ? 'Contratado' : 'Contratante',
                value: contract.otherParty!.nombre,
              ),
            _InfoRow(label: 'Estado', value: contract.displayStatusLabel),
            if (contract.salary != null)
              _InfoRow(
                label: 'Salario',
                value: "${contract.currency ?? 'DOP'} ${contract.salary}",
              ),
            if (contract.startDate != null)
              _InfoRow(
                label: 'Inicio',
                value: _formatDate(contract.startDate!),
              ),
            if (contract.duration != null && contract.duration!.isNotEmpty)
              _InfoRow(label: 'Duración', value: contract.duration!),
            if (contract.acceptedAt != null)
              _InfoRow(
                label: 'Aceptado el',
                value: _formatDate(contract.acceptedAt!),
              ),
            if (contract.cancelledAt != null)
              _InfoRow(
                label: 'Cancelado el',
                value: _formatDate(contract.cancelledAt!),
              ),
            if (contract.cancelJustification != null &&
                contract.cancelJustification!.isNotEmpty)
              _InfoRow(
                label: 'Justificación',
                value: contract.cancelJustification!,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (contract.isContratante && contract.isPending)
          _PrimaryActionCard(
            label: contract.hasTerms ? 'Editar términos' : 'Fijar términos',
            icon: Icons.edit_rounded,
            onPressed: () => _showSetTermsSheet(context, viewModel, contract),
            isLoading: viewModel.isSaving,
          ),
        if (contract.isContratado && contract.isPending)
          _ActionButtonsRow(
            firstLabel: 'Aceptar',
            firstIcon: Icons.check_rounded,
            firstColor: AppColors.success,
            firstOnPressed: viewModel.isSaving
                ? null
                : () async {
                    final bool accepted = await viewModel.acceptContract();
                    if (!context.mounted) return;
                    if (!accepted) {
                      _showMessage(
                        context,
                        viewModel.errorMessage ??
                            'No fue posible aceptar el contrato.',
                      );
                    }
                  },
            secondLabel: 'Rechazar',
            secondIcon: Icons.close_rounded,
            secondColor: AppColors.error,
            secondOnPressed: viewModel.isSaving
                ? null
                : () async {
                    final bool rejected = await viewModel.rejectContract();
                    if (!context.mounted) return;
                    if (!rejected) {
                      _showMessage(
                        context,
                        viewModel.errorMessage ??
                            'No fue posible rechazar el contrato.',
                      );
                    }
                  },
          ),
        if (contract.isActive) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _CommentsSection(
            comments: contract.comments,
            controller: _commentController,
            isSaving: viewModel.isSaving,
            onSend: () async {
              final bool success = await viewModel.addComment(
                _commentController.text,
              );
              if (!context.mounted) return;
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
          const SizedBox(height: AppSpacing.md),
          _PhotosSection(
            photos: contract.photos,
            isSaving: viewModel.isSaving,
            onAddPhoto: () => _pickPhoto(context, viewModel),
          ),
          const SizedBox(height: AppSpacing.md),
          _PrimaryActionCard(
            label: 'Cancelar contrato',
            icon: Icons.cancel_rounded,
            onPressed: viewModel.isSaving
                ? null
                : () => _showCancelDialog(context, viewModel),
            isLoading: viewModel.isSaving,
            color: AppColors.error,
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
    final TextEditingController salaryController = TextEditingController(
      text: contract.salary != null ? contract.salary!.toString() : '',
    );
    final TextEditingController currencyController = TextEditingController(
      text: contract.currency ?? 'DOP',
    );
    final TextEditingController startDateController = TextEditingController(
      text: contract.startDate != null ? _formatDate(contract.startDate!) : '',
    );
    final TextEditingController durationController = TextEditingController(
      text: contract.duration ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
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
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Salario'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: startDateController,
                decoration: const InputDecoration(labelText: 'Fecha de inicio'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duración'),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: viewModel.isSaving
                    ? null
                    : () async {
                        final num? salary = num.tryParse(
                          salaryController.text.trim(),
                        );
                        if (salary == null) {
                          _showMessage(
                            bottomSheetContext,
                            'Ingresa un salario válido.',
                          );
                          return;
                        }

                        final bool saved = await viewModel.setTerms(
                          salary: salary,
                          currency: currencyController.text.trim().isNotEmpty
                              ? currencyController.text.trim()
                              : 'DOP',
                          startDate: startDateController.text.trim(),
                          duration: durationController.text.trim(),
                        );

                        if (!bottomSheetContext.mounted) return;
                        if (saved) {
                          Navigator.pop(bottomSheetContext);
                        } else {
                          _showMessage(
                            bottomSheetContext,
                            viewModel.errorMessage ??
                                'No fue posible fijar los términos.',
                          );
                        }
                      },
                child: const Text('Guardar términos'),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
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
    if (!cancelled) {
      _showMessage(
        context,
        viewModel.errorMessage ?? 'No fue posible cancelar el contrato.',
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _ContractHeader extends StatelessWidget {
  const _ContractHeader({required this.contract});

  final Contract contract;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              contract.displayTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                _RoleBadge(isContratante: contract.isContratante),
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(
                  label: contract.displayStatusLabel,
                  status: contract.status,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (contract.otherParty != null)
              Text('Con: ${contract.otherParty!.nombre}'),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isContratante});

  final bool isContratante;

  @override
  Widget build(BuildContext context) {
    final Color color = isContratante ? AppColors.navy : AppColors.terracotta;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isContratante ? 'Soy contratante' : 'Soy contratado',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, IconData icon) = switch (status
        .toLowerCase()
        .trim()) {
      'active' => (
        AppColors.successSurface,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      'pending' => (
        const Color(0xFFFFF8E1),
        const Color(0xFFF57F17),
        Icons.schedule_rounded,
      ),
      'rejected' => (
        AppColors.errorSurface,
        AppColors.error,
        Icons.cancel_outlined,
      ),
      'cancelled' => (
        AppColors.errorSurface,
        AppColors.error,
        Icons.cancel_outlined,
      ),
      _ => (const Color(0xFFEEEEEE), Colors.grey, Icons.info_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 5, child: Text(value)),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.icon(
              onPressed: onPressed,
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    required this.firstLabel,
    required this.firstIcon,
    required this.firstColor,
    required this.firstOnPressed,
    required this.secondLabel,
    required this.secondIcon,
    required this.secondColor,
    required this.secondOnPressed,
  });

  final String firstLabel;
  final IconData firstIcon;
  final Color firstColor;
  final VoidCallback? firstOnPressed;
  final String secondLabel;
  final IconData secondIcon;
  final Color secondColor;
  final VoidCallback? secondOnPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FilledButton.icon(
            onPressed: firstOnPressed,
            icon: Icon(firstIcon),
            label: Text(firstLabel),
            style: FilledButton.styleFrom(backgroundColor: firstColor),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: secondOnPressed,
            icon: Icon(secondIcon),
            label: Text(secondLabel),
            style: FilledButton.styleFrom(backgroundColor: secondColor),
          ),
        ),
      ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Comentarios',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (comments.isEmpty) const Text('Aún no hay comentarios.'),
            if (comments.isNotEmpty)
              ...comments.map((ContractComment comment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            comment.by?.nombre ?? 'Anónimo',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          if (comment.createdAt != null)
                            Text(
                              '· ${comment.createdAt!.day}/${comment.createdAt!.month}/${comment.createdAt!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(comment.body),
                    ],
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Escribe un comentario',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: isSaving ? null : onSend,
                child: const Text('Enviar comentario'),
              ),
            ),
          ],
        ),
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Fotos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (photos.isEmpty) const Text('No hay fotos agregadas aún.'),
            if (photos.isNotEmpty)
              Column(
                children: photos.map((ContractPhoto photo) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Image.network(photo.url, fit: BoxFit.cover),
                        const SizedBox(height: AppSpacing.xs),
                        Text(photo.description),
                        if (photo.by != null || photo.createdAt != null)
                          Text(
                            '${photo.by?.nombre ?? 'Usuario'}${photo.createdAt != null ? ' · ${photo.createdAt!.day}/${photo.createdAt!.month}/${photo.createdAt!.year}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: isSaving ? null : onAddPhoto,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Agregar foto'),
            ),
          ],
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_spacing.dart';
import 'package:ocupa2/core/validation/app_validators.dart';
import 'package:ocupa2/features/my_activity/data/models/experience.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_status.dart';
import 'package:ocupa2/features/my_activity/presentation/viewmodels/experiences_view_model.dart';
import 'package:provider/provider.dart';

class ExperiencesView extends StatefulWidget {
  const ExperiencesView({super.key});

  @override
  State<ExperiencesView> createState() => _ExperiencesViewState();
}

class _ExperiencesViewState extends State<ExperiencesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExperiencesViewModel>().load();
      }
    });
  }

  Future<void> _showAddExperienceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExperiencesViewModel>(),
        child: const _AddExperienceSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExperiencesViewModel viewModel = context.watch<ExperiencesViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mis experiencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isSaving ? null : _showAddExperienceSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
      ),
      body: switch (viewModel.status) {
        ExperiencesStatus.idle || ExperiencesStatus.loading =>
          const Center(child: CircularProgressIndicator()),
        ExperiencesStatus.error => _ErrorState(
            message: viewModel.errorMessage,
            onRetry: viewModel.load,
          ),
        ExperiencesStatus.success => _ExperiencesList(
            experiences: viewModel.experiences,
            onDelete: (Experience experience) => _confirmDelete(context, experience),
          ),
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Experience experience) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar experiencia'),
        content: Text('¿Eliminar “${experience.title}”? Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final bool success = await context.read<ExperiencesViewModel>().deleteExperience(experience);
    if (!context.mounted) {
      return;
    }
    if (!success) {
      final String message = context.read<ExperiencesViewModel>().errorMessage ??
          'No fue posible eliminar la experiencia.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ExperiencesList extends StatelessWidget {
  const _ExperiencesList({required this.experiences, required this.onDelete});

  final List<Experience> experiences;
  final ValueChanged<Experience> onDelete;

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: context.read<ExperiencesViewModel>().load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          96,
        ),
        itemCount: experiences.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, int index) {
          final Experience experience = experiences[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: AppColors.successSurface,
                    foregroundColor: AppColors.success,
                    child: Icon(Icons.work_outline_rounded),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          experience.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(experience.description),
                        if (experience.certificateImage != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.sm),
                          ActionChip(
                            avatar: Icon(Icons.verified_outlined, size: 18),
                            label: Text('Certificado adjunto'),
                            onPressed: () {
                              _showCertificate(
                                context,
                                title: experience.title,
                                imageUrl: experience.certificateImage!,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar experiencia',
                    onPressed: () => onDelete(experience),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _showCertificate(
  BuildContext context, {
  required String title,
  required String imageUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('Certificado - $title'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return const SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                          size: 56,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No fue posible cargar el certificado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.work_history_outlined, size: 64, color: AppColors.terracotta),
            SizedBox(height: AppSpacing.md),
            Text('Todavía no has agregado experiencias.', textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Agrega tu experiencia laboral para que quienes publiquen ofertas conozcan tu perfil.',
              textAlign: TextAlign.center,
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
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(message ?? 'No fue posible cargar tus experiencias.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _AddExperienceSheet extends StatefulWidget {
  const _AddExperienceSheet();

  @override
  State<_AddExperienceSheet> createState() => _AddExperienceSheetState();
}

class _AddExperienceSheetState extends State<_AddExperienceSheet> {
  static const String _titleField = 'title';
  static const String _descriptionField = 'description';
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _certificate;

  Future<void> _pickCertificate() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _certificate = image);
    }
  }

  Future<void> _save() async {
    final FormBuilderState? form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      return;
    }
    final Map<String, dynamic> values = form.value;
    final bool saved = await context.read<ExperiencesViewModel>().addExperience(
      title: values[_titleField] as String,
      description: values[_descriptionField] as String,
      certificate: _certificate,
    );
    if (saved && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSaving = context.watch<ExperiencesViewModel>().isSaving;
    final String? errorMessage = context.watch<ExperiencesViewModel>().errorMessage;
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, viewInsets.bottom + AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Agregar experiencia', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.lg),
                FormBuilderTextField(
                  name: _titleField,
                  enabled: !isSaving,
                  validator: AppValidators.requiredText('El cargo o experiencia'),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Cargo o experiencia',
                    hintText: 'Ej. Cuidado de adultos mayores',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FormBuilderTextField(
                  name: _descriptionField,
                  enabled: !isSaving,
                  validator: AppValidators.requiredText('La descripción'),
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Cuenta brevemente qué hacías y qué sabes hacer.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickCertificate,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    _certificate == null
                        ? 'Adjuntar certificado (opcional)'
                        : 'Cambiar certificado',
                  ),
                ),
                if (_certificate != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.verified_outlined,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _certificate!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quitar certificado',
                        onPressed: isSaving
                            ? null
                            : () => setState(() => _certificate = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(errorMessage, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: isSaving ? null : _save,
                  icon: isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Guardando...' : 'Guardar experiencia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

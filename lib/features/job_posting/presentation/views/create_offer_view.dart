import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocupa2/app/router/app_routes.dart';
import 'package:ocupa2/core/widgets/app_bottom_nav.dart';
import 'package:ocupa2/app/theme/app_colors.dart';
import 'package:ocupa2/app/theme/app_typography.dart';
import 'package:ocupa2/features/job_posting/data/custom_field_date.dart';
import 'package:ocupa2/features/job_posting/presentation/widgets/publish_stepper.dart';

import '../../../catalog/data/models/custom_field.dart';
import '../../../catalog/data/models/job_type.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../payments/presentation/viewmodels/make_payment_view_model.dart';
import '../../data/models/offer_question.dart';
import '../viewmodels/create_offer_status.dart';
import '../viewmodels/create_offer_view_model.dart';
import 'package:ocupa2/features/job_posting/data/services/upload_service.dart';
import 'package:ocupa2/features/job_search/presentation/viewmodels/explore_offers_view_model.dart';

class CreateOfferView extends StatefulWidget {
  const CreateOfferView({super.key});

  @override
  State<CreateOfferView> createState() => _CreateOfferViewState();
}

class _CreateOfferViewState extends State<CreateOfferView> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _amountController = TextEditingController(text: '1500');
  final _currencyController = TextEditingController(text: 'DOP');
  final List<_OfferQuestionForm> _questions = [];

  String? _jobTypeKey;
  String? _contractType;

  /// Nombre del archivo elegido (no es una ruta de disco en web).
  String? _photo;

  /// Bytes locales para previsualizar (Android y Chrome).
  Uint8List? _photoBytes;

  /// URL pública devuelta por el endpoint de subida.
  String? _photoUrl;

  DateTime? _deadline;

  List<JobType> _jobTypes = [];
  bool _loadingJobTypes = true;
  String? _jobTypesError;

  final Map<String, TextEditingController> _customTextControllers =
      <String, TextEditingController>{};
  final Map<String, String?> _customSelectValues = <String, String?>{};
  final Map<String, bool> _customCheckValues = <String, bool>{};
  final Map<String, DateTime?> _customDates = <String, DateTime?>{};

  bool _loadingLocation = false;
  bool _uploadingPhoto = false;
  bool _publishing = false;
  bool _publishedSuccessfully = false;

  /// 0 Información · 1 Detalles · 2 Preguntas · 3 Revisar
  int _currentStep = 0;

  /// Último paso alcanzado; el stepper puede volver a cualquiera hasta aquí.
  int _farthestStep = 0;

  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadJobTypes();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _disposeCustomFieldControllers();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // JOB TYPES
  // ============================================================

  Future<void> _loadJobTypes() async {
    try {
      final repository = context.read<CatalogRepository>();

      final jobTypes = await repository.getJobTypes();

      if (!mounted) return;

      setState(() {
        _jobTypes = jobTypes;
        _loadingJobTypes = false;
        _jobTypesError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingJobTypes = false;
        _jobTypesError = 'No se pudieron cargar los tipos de trabajo';
      });

      debugPrint('ERROR CARGANDO JOB TYPES: $e');
    }
  }

  JobType? get _selectedJobType {
    if (_jobTypeKey == null) {
      return null;
    }

    for (final JobType jobType in _jobTypes) {
      if (jobType.key == _jobTypeKey) {
        return jobType;
      }
    }

    return null;
  }

  void _disposeCustomFieldControllers() {
    for (final TextEditingController controller
        in _customTextControllers.values) {
      controller.dispose();
    }
    _customTextControllers.clear();
    _customSelectValues.clear();
    _customCheckValues.clear();
    _customDates.clear();
  }

  void _onJobTypeChanged(String? value) {
    _disposeCustomFieldControllers();
    _jobTypeKey = value;

    final JobType? jobType = _selectedJobType;
    if (jobType != null) {
      for (final CustomField field in jobType.customFields) {
        if (field.type == 'select') {
          _customSelectValues[field.key] = null;
        } else if (field.type == 'check') {
          _customCheckValues[field.key] = false;
        } else if (field.type == 'date') {
          _customDates[field.key] = null;
        } else {
          _customTextControllers[field.key] = TextEditingController();
        }
      }
    }

    setState(() {});
  }

  String? _validateCustomFields() {
    final JobType? jobType = _selectedJobType;
    if (jobType == null) {
      return null;
    }

    for (final CustomField field in jobType.customFields) {
      if (!field.required) {
        continue;
      }

      if (field.type == 'select') {
        final String? selected = _customSelectValues[field.key];
        if (selected == null || selected.trim().isEmpty) {
          return 'Completa el campo "${field.label}".';
        }
      } else if (field.type == 'check') {
        if (_customCheckValues[field.key] != true) {
          return 'Debes marcar "${field.label}".';
        }
      } else if (field.type == 'date') {
        if (_customDates[field.key] == null) {
          return 'Completa el campo "${field.label}".';
        }
      } else {
        final String value =
            _customTextControllers[field.key]?.text.trim() ?? '';
        if (value.isEmpty) {
          return 'Completa el campo "${field.label}".';
        }
      }
    }

    return null;
  }

  Map<String, dynamic> _buildCustomAnswers() {
    final JobType? jobType = _selectedJobType;
    if (jobType == null) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> answers = <String, dynamic>{};

    for (final CustomField field in jobType.customFields) {
      if (field.type == 'select') {
        final String? selected = _customSelectValues[field.key];
        if (selected != null && selected.trim().isNotEmpty) {
          answers[field.key] = selected;
        }
      } else if (field.type == 'check') {
        answers[field.key] = _customCheckValues[field.key] ?? false;
      } else if (field.type == 'date') {
        final DateTime? date = _customDates[field.key];
        if (date != null) {
          answers[field.key] = CustomFieldDate.toApi(date);
        }
      } else if (field.type == 'number') {
        final String raw = _customTextControllers[field.key]?.text.trim() ?? '';
        if (raw.isNotEmpty) {
          answers[field.key] = num.tryParse(raw) ?? raw;
        }
      } else {
        final String raw = _customTextControllers[field.key]?.text.trim() ?? '';
        if (raw.isNotEmpty) {
          answers[field.key] = raw;
        }
      }
    }

    return answers;
  }

  Future<void> _pickCustomDate(CustomField field) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customDates[field.key] ?? now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _customDates[field.key] = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Widget _buildCustomFieldsSection({required bool enabled}) {
    final JobType? jobType = _selectedJobType;
    if (jobType == null || jobType.customFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Campos personalizados de ${jobType.label}'.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...jobType.customFields.map(
            (CustomField field) => Padding(
              key: ValueKey<String>('${jobType.key}-${field.key}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCustomFieldControl(field, enabled: enabled),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldControl(CustomField field, {required bool enabled}) {
    final String label = field.required ? '${field.label} *' : field.label;

    switch (field.type) {
      case 'number':
        return _labeledField(
          label: label,
          child: TextFormField(
            controller: _customTextControllers[field.key],
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _figmaDecoration(),
          ),
        );
      case 'date':
        final DateTime? selected = _customDates[field.key];
        return _labeledField(
          label: label,
          child: InkWell(
            onTap: enabled ? () => _pickCustomDate(field) : null,
            child: InputDecorator(
              decoration: _figmaDecoration(
                prefixIcon: Icons.calendar_today_outlined,
              ),
              child: Text(
                selected == null
                    ? 'Selecciona una fecha'
                    : CustomFieldDate.toDisplay(selected),
                style: TextStyle(
                  color: selected == null
                      ? Theme.of(context).hintColor
                      : AppColors.text,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      case 'select':
        return _labeledField(
          label: label,
          child: DropdownButtonFormField<String>(
            initialValue: _customSelectValues[field.key],
            isExpanded: true,
            decoration: _figmaDecoration(),
            hint: const Text('Selecciona una opción'),
            items: field.options
                .map(
                  (String option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (String? value) {
                    setState(() {
                      _customSelectValues[field.key] = value;
                    });
                  }
                : null,
          ),
        );
      case 'check':
        return CheckboxListTile(
          value: _customCheckValues[field.key] ?? false,
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: enabled
              ? (bool? value) {
                  setState(() {
                    _customCheckValues[field.key] = value ?? false;
                  });
                }
              : null,
        );
      default:
        return _labeledField(
          label: label,
          child: TextFormField(
            controller: _customTextControllers[field.key],
            enabled: enabled,
            decoration: _figmaDecoration(),
          ),
        );
    }
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Future<void> _pickImage() async {
    if (_pickingImage || _uploadingPhoto) {
      return;
    }
    _pickingImage = true;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _photo = image.name.trim().isEmpty ? 'image.jpg' : image.name;
        _photoBytes = null;
        _photoUrl = null;
        _uploadingPhoto = true;
      });

      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _photoBytes = bytes;
      });

      final uploadService = context.read<UploadService>();
      final uploadedUrl = await uploadService.uploadImage(
        bytes: bytes,
        filename: _photo!,
      );

      if (!mounted) return;

      setState(() {
        _photoUrl = uploadedUrl;
      });

      _showMessage('Imagen subida correctamente.');
    } catch (e) {
      debugPrint('ERROR SELECCIONANDO/SUBIENDO IMAGEN: $e');

      if (!mounted) return;

      setState(() {
        _photo = null;
        _photoBytes = null;
        _photoUrl = null;
      });

      _showMessage('No se pudo subir la imagen.');
    } finally {
      _pickingImage = false;
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  void _removePhoto() {
    if (_uploadingPhoto || _publishing) {
      return;
    }

    setState(() {
      _photo = null;
      _photoBytes = null;
      _photoUrl = null;
    });
  }

  // ============================================================
  // UBICACIÓN
  // ============================================================

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage('Activa la ubicación de tu dispositivo.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage('Se necesita permiso para acceder a tu ubicación.');
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'El permiso de ubicación está bloqueado. '
        'Actívalo desde los ajustes.',
      );
      return false;
    }

    return true;
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    if (!kIsWeb) {
      final String fromPlugin = await _addressFromGeocodingPlugin(lat, lng);
      if (fromPlugin.isNotEmpty) {
        return fromPlugin;
      }
    }

    return _addressFromHttp(lat, lng);
  }

  Future<String> _addressFromGeocodingPlugin(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isEmpty) {
        return '';
      }

      final Placemark place = placemarks.first;
      return _joinAddressParts(<String?>[
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ]);
    } catch (e) {
      debugPrint('ERROR OBTENIENDO DIRECCIÓN: $e');
      return '';
    }
  }

  Future<String> _addressFromHttp(double lat, double lng) async {
    try {
      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      final Response<dynamic> response = await dio.get<dynamic>(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: <String, dynamic>{
          'latitude': lat,
          'longitude': lng,
          'localityLanguage': 'es',
        },
      );

      final Object? data = response.data;
      if (data is! Map) {
        return '';
      }

      final Map<String, dynamic> json = Map<String, dynamic>.from(data);
      return _joinAddressParts(<String?>[
        json['locality']?.toString(),
        json['city']?.toString(),
        json['principalSubdivision']?.toString(),
        json['countryName']?.toString(),
      ]);
    } catch (e) {
      debugPrint('ERROR OBTENIENDO DIRECCIÓN HTTP: $e');
      return '';
    }
  }

  String _joinAddressParts(List<String?> values) {
    final List<String> parts = <String>[];
    for (final String? value in values) {
      final String trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty || parts.contains(trimmed)) {
        continue;
      }
      parts.add(trimmed);
    }
    return parts.join(', ');
  }

  void _applyPickedLocation({
    required double lat,
    required double lng,
    required String address,
  }) {
    _latController.text = lat.toString();
    _lngController.text = lng.toString();
    if (address.trim().isNotEmpty) {
      _addressController.text = address.trim();
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      final hasPermission = await _checkLocationPermission();

      if (!hasPermission) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      final address = await _getAddressFromCoordinates(lat, lng);

      if (!mounted) return;

      setState(() {
        _applyPickedLocation(lat: lat, lng: lng, address: address);
      });

      if (address.isEmpty) {
        _showMessage(
          'Ubicación obtenida. Escribe la dirección del trabajo.',
        );
      }
    } catch (e) {
      debugPrint('ERROR OBTENIENDO UBICACIÓN: $e');

      if (mounted) {
        _showMessage('No se pudo obtener la ubicación actual.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // MAPA
  // ============================================================

  Future<void> _selectLocationFromMap() async {
    LatLng initialPosition;

    final currentLat = double.tryParse(_latController.text);

    final currentLng = double.tryParse(_lngController.text);

    if (currentLat != null && currentLng != null) {
      initialPosition = LatLng(currentLat, currentLng);
    } else {
      try {
        final hasPermission = await _checkLocationPermission();

        if (hasPermission) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          initialPosition = LatLng(position.latitude, position.longitude);
        } else {
          initialPosition = const LatLng(18.4861, -69.9312);
        }
      } catch (_) {
        initialPosition = const LatLng(18.4861, -69.9312);
      }
    }

    if (!mounted) return;

    final selectedLocation = await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _MapLocationPicker(initialPosition: initialPosition);
      },
    );

    if (selectedLocation == null || !mounted) {
      return;
    }

    setState(() {
      _loadingLocation = true;
    });

    try {
      final lat = selectedLocation.latitude;
      final lng = selectedLocation.longitude;

      final address = await _getAddressFromCoordinates(lat, lng);

      if (!mounted) return;

      setState(() {
        _applyPickedLocation(lat: lat, lng: lng, address: address);
      });

      if (address.isEmpty) {
        _showMessage(
          'Ubicación seleccionada. Escribe la dirección del trabajo.',
        );
      }
    } catch (e) {
      debugPrint('ERROR PROCESANDO UBICACIÓN: $e');

      if (mounted) {
        _showMessage('No se pudo procesar la ubicación seleccionada.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    try {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar el SnackBar: $e');
    }
  }

  // ============================================================
  // FECHA
  // ============================================================

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _updateQuestionType(int index, String type) {
    setState(() {
      _questions[index].type = type;
      if (!_typeSupportsOptions(type)) {
        for (final TextEditingController ctrl
            in _questions[index].optionControllers) {
          ctrl.dispose();
        }
        _questions[index].optionControllers.clear();
      } else {
        while (_questions[index].optionControllers.length < 2) {
          _questions[index].optionControllers.add(TextEditingController());
        }
      }
    });
  }

  void _updateQuestionRequired(int index, bool required) {
    setState(() {
      _questions[index].required = required;
    });
  }

  // Add option to a question
  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex].optionControllers.add(TextEditingController());
    });
  }

  // Remove option from a question
  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex].optionControllers[optionIndex].dispose();
      _questions[questionIndex].optionControllers.removeAt(optionIndex);
    });
  }

  String? _validateAdditionalQuestions() {
    for (final q in _questions) {
      if (!q.isValid) {
        return 'La pregunta "${q.labelController.text}" no es válida. Asegúrate de que el label esté completo y, si es de selección, al menos dos opciones.';
      }
    }
    return null;
  }

  // ============================================================
  // PREGUNTAS ADICIONALES
  // ============================================================

  void _addQuestion() {
    setState(() {
      _questions.add(_OfferQuestionForm());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Widget _buildQuestionCard(int index, {required bool enabled}) {
    final _OfferQuestionForm question = _questions[index];
    final String typeLabel =
        _questionTypeLabels[question.type] ?? question.type;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              PopupMenuButton<String>(
                enabled: enabled,
                onSelected: (String type) => _updateQuestionType(index, type),
                itemBuilder: (BuildContext context) {
                  return _questionTypeLabels.entries.map((
                    MapEntry<String, String> entry,
                  ) {
                    return PopupMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: AppTypography.medium,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Eliminar pregunta',
                onPressed: enabled ? () => _removeQuestion(index) : null,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: question.labelController,
            enabled: enabled,
            textCapitalization: TextCapitalization.sentences,
            decoration: _figmaDecoration().copyWith(
              hintText: 'Escribe la pregunta para el candidato...',
            ),
          ),
          if (_typeSupportsOptions(question.type)) ...<Widget>[
            const SizedBox(height: 12),
            ...List<Widget>.generate(question.optionControllers.length, (
              int optIndex,
            ) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        controller: question.optionControllers[optIndex],
                        enabled: enabled,
                        decoration: _figmaDecoration().copyWith(
                          hintText: 'Opción ${optIndex + 1}',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: enabled &&
                              question.optionControllers.length > 2
                          ? () => _removeOption(index, optIndex)
                          : null,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: enabled ? () => _addOption(index) : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar opción'),
            ),
          ],
          const SizedBox(height: 4),
          const Divider(height: 1, color: AppColors.border),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Obligatoria',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.regular,
              ),
            ),
            value: question.required,
            activeThumbColor: AppColors.primary,
            onChanged: enabled
                ? (bool value) => _updateQuestionRequired(index, value)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _showPaymentFailedDialog(String message) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pago rechazado'),
          content: Text(message),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPublishSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x990F172A),
      builder: (BuildContext dialogContext) {
        return _PublishSuccessDialog(
          onViewPublications: () {
            Navigator.of(dialogContext).pop();
            if (!context.mounted) {
              return;
            }
            context.goNamed(
              AppRouteNames.activityHub,
              queryParameters: const <String, String>{'tab': 'offers'},
            );
          },
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Future<_PaymentConfirmationResult?> _showCardPaymentDialog() {
    return showModalBottomSheet<_PaymentConfirmationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x61000000),
      builder: (BuildContext sheetContext) {
        return const _CardPaymentDialog();
      },
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (context.read<CreateOfferViewModel>().isSubmitting ||
        context.read<MakePaymentViewModel>().isSubmitting ||
        _publishing ||
        _publishedSuccessfully) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('La descripción es obligatoria.');
      return;
    }

    if (_latController.text.trim().isEmpty ||
        _lngController.text.trim().isEmpty) {
      _showMessage('Selecciona una ubicación.');
      return;
    }

    if (_deadline == null) {
      _showMessage('Selecciona la fecha límite.');
      return;
    }

    if (_photo == null || _photoUrl == null || _photoUrl!.isEmpty) {
      _showMessage('Selecciona y espera a que se suba la foto.');
      return;
    }

    if (_uploadingPhoto) {
      _showMessage('Espera a que termine de subir la imagen.');
      return;
    }

    final String? customFieldError = _validateCustomFields();
    if (customFieldError != null) {
      _showMessage(customFieldError);
      return;
    }

    final String? questionError = _validateAdditionalQuestions();
    if (questionError != null) {
      _showMessage(questionError);
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('El salario del trabajo debe ser válido.');
      return;
    }

    final String currency = _currencyController.text.trim();
    if (currency.isEmpty) {
      _showMessage('Indica la moneda del salario.');
      return;
    }

    final List<OfferQuestion> questions = _questions
        .where((q) => q.labelController.text.trim().isNotEmpty)
        .map((q) => q.toOfferQuestion())
        .toList();

    final Map<String, dynamic> customAnswers = _buildCustomAnswers();

    final _PaymentConfirmationResult? confirmation =
        await _showCardPaymentDialog();
    if (!mounted) {
      return;
    }
    if (confirmation == null) {
      return;
    }

    setState(() {
      _publishing = true;
    });

    final CreateOfferViewModel createOfferViewModel = context
        .read<CreateOfferViewModel>();
    final MakePaymentViewModel paymentViewModel = context
        .read<MakePaymentViewModel>();

    try {
      final bool paymentOk = await paymentViewModel.pay(
        cardNumber: confirmation.cardNumber,
        cvv: confirmation.cvv,
        expMonth: confirmation.expMonth,
        expYear: confirmation.expYear,
        cardholder: confirmation.cardholder,
      );

      if (!mounted) {
        return;
      }

      if (!paymentOk) {
        await _showPaymentFailedDialog(
          paymentViewModel.errorMessage ??
              'El pago fue rechazado. Verifica los datos de la tarjeta '
                  'o utiliza otra tarjeta.',
        );
        return;
      }

      final payment = paymentViewModel.payment;

      if (payment == null || payment.id.isEmpty) {
        _showMessage('El pago fue realizado, pero no se recibió su ID');
        return;
      }

      final bool offerOk = await createOfferViewModel.submit(
        jobTypeKey: _jobTypeKey!,
        contractType: _contractType!,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        photo: _photoUrl,
        paymentId: payment.id,
        lat: double.parse(_latController.text.trim()),
        lng: double.parse(_lngController.text.trim()),
        amount: amount,
        currency: currency,
        deadline: _deadline!,
        customAnswers: customAnswers,
        questions: questions,
      );

      if (!mounted) {
        return;
      }

      if (!offerOk) {
        _showMessage(
          createOfferViewModel.errorMessage ??
              'El pago se realizó, pero no se pudo publicar la oferta',
        );
        return;
      }

      await createOfferViewModel.verifyCreatedOfferInMyOffers();

      if (!mounted) {
        return;
      }

      setState(() {
        _publishedSuccessfully = true;
      });

      try {
        context.read<ExploreOffersViewModel>().load();
      } catch (error) {
        debugPrint('No se pudo refrescar explorar ofertas: $error');
      }

      await _showPublishSuccessDialog();
    } finally {
      if (mounted) {
        setState(() {
          _publishing = false;
        });
      }
    }
  }

  // ============================================================
  // PASOS DEL ASISTENTE
  // ============================================================

  static const List<String> _monthNames = <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  InputDecoration _figmaDecoration({IconData? prefixIcon, IconData? suffixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 18),
      suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 16),
      contentPadding: const EdgeInsets.all(12),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: AppTypography.medium,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  String _deadlineLongLabel(DateTime date) {
    return '${date.day} de ${_monthNames[date.month - 1]}, ${date.year}';
  }

  String _contractReviewLabel(String? contractType) {
    switch ((contractType ?? '').toLowerCase()) {
      case 'temporal':
        return 'Temporal';
      case 'fijo':
        return 'Fijo';
      case 'horas':
        return 'Por horas';
      default:
        return contractType ?? '';
    }
  }

  String _salaryReviewLabel() {
    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null) {
      return 'A convenir';
    }

    final String digits = amount.round().abs().toString();
    final StringBuffer grouped = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(digits[i]);
    }

    final String currency = _currencyController.text.trim().toUpperCase();
    if (currency == 'USD' || currency == 'US\$') {
      return 'US\$$grouped';
    }
    return 'RD\$$grouped';
  }

  String _questionsReviewLabel() {
    final int count = _questions
        .where(
          (_OfferQuestionForm question) =>
              question.labelController.text.trim().isNotEmpty,
        )
        .length;
    if (count == 0) {
      return 'Sin preguntas de filtro';
    }
    if (count == 1) {
      return '1 pregunta de filtro agregada';
    }
    return '$count preguntas de filtro agregadas';
  }

  bool get _hasMapLocation {
    return _latController.text.trim().isNotEmpty &&
        _lngController.text.trim().isNotEmpty;
  }

  String _customFieldReviewText(CustomField field) {
    switch (field.type) {
      case 'select':
        final String? selected = _customSelectValues[field.key];
        if (selected == null || selected.isEmpty) {
          return 'Sin seleccionar';
        }
        return selected;
      case 'check':
        return _customCheckValues[field.key] == true ? 'Sí' : 'No';
      case 'date':
        final DateTime? date = _customDates[field.key];
        if (date == null) {
          return 'Sin fecha';
        }
        return CustomFieldDate.toDisplay(date);
      default:
        final String raw = _customTextControllers[field.key]?.text.trim() ?? '';
        return raw.isEmpty ? 'Sin completar' : raw;
    }
  }

  String _questionReviewLine(_OfferQuestionForm question) {
    final String typeLabel =
        _questionTypeLabels[question.type] ?? question.type;
    final String requiredLabel = question.required ? ' · Obligatoria' : '';
    final String options = _typeSupportsOptions(question.type)
        ? question.optionControllers
              .map((TextEditingController c) => c.text.trim())
              .where((String o) => o.isNotEmpty)
              .join(', ')
        : '';
    final String optionsSuffix = options.isEmpty ? '' : ' ($options)';
    return '${question.labelController.text.trim()} · $typeLabel$requiredLabel$optionsSuffix';
  }

  bool _validateStep1() {
    if (_jobTypeKey == null || _jobTypeKey!.isEmpty) {
      _showMessage('Selecciona un tipo de trabajo');
      return false;
    }
    if (_contractType == null || _contractType!.isEmpty) {
      _showMessage('Selecciona un tipo de contrato');
      return false;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('El salario del trabajo debe ser válido.');
      return false;
    }
    if (_currencyController.text.trim().isEmpty) {
      _showMessage('Indica la moneda del salario.');
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _showMessage('Indica la dirección del trabajo');
      return false;
    }
    if (_latController.text.trim().isEmpty ||
        _lngController.text.trim().isEmpty) {
      _showMessage('Selecciona una ubicación.');
      return false;
    }
    if (_deadline == null) {
      _showMessage('Selecciona la fecha límite.');
      return false;
    }

    final String? customFieldError = _validateCustomFields();
    if (customFieldError != null) {
      _showMessage(customFieldError);
      return false;
    }

    return true;
  }

  bool _validateStep2() {
    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('La descripción es obligatoria.');
      return false;
    }
    if (_photo == null || _photoUrl == null || _photoUrl!.isEmpty) {
      _showMessage('Selecciona y espera a que se suba la foto.');
      return false;
    }
    if (_uploadingPhoto) {
      _showMessage('Espera a que termine de subir la imagen.');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    final String? questionError = _validateAdditionalQuestions();
    if (questionError != null) {
      _showMessage(questionError);
      return false;
    }
    return true;
  }

  void _goNext() {
    final bool ok = switch (_currentStep) {
      0 => _formKey.currentState?.validate() == true && _validateStep1(),
      1 => _validateStep2(),
      2 => _validateStep3(),
      _ => true,
    };

    if (!ok) {
      return;
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep += 1;
        if (_currentStep > _farthestStep) {
          _farthestStep = _currentStep;
        }
      });
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step > _farthestStep || step == _currentStep) {
      return;
    }
    setState(() {
      _currentStep = step;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final createOfferViewModel = context.watch<CreateOfferViewModel>();

    final paymentViewModel = context.watch<MakePaymentViewModel>();

    final isLoading =
        createOfferViewModel.isSubmitting ||
        paymentViewModel.isSubmitting ||
        _loadingLocation ||
        _uploadingPhoto ||
        _publishing;

    return ScaffoldMessenger(
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: PublishStepper(
                  currentStep: _currentStep,
                  reachableStep: _farthestStep,
                  onStepSelected: _goToStep,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: _buildStepChildren(
                    isLoading: isLoading,
                    createOfferViewModel: createOfferViewModel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(
        selected: AppBottomNavTab.publish,
      ),
    ),
    );
  }

  List<Widget> _buildStepChildren({
    required bool isLoading,
    required CreateOfferViewModel createOfferViewModel,
  }) {
    return switch (_currentStep) {
      0 => _buildStep1(isLoading: isLoading),
      1 => _buildStep2(isLoading: isLoading),
      2 => _buildStep3(isLoading: isLoading),
      _ => _buildStep4(
        isLoading: isLoading,
        createOfferViewModel: createOfferViewModel,
      ),
    };
  }

  List<Widget> _buildStep1({required bool isLoading}) {
    return <Widget>[
      const Text(
        'Información básica',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: AppTypography.bold,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Completa los datos de cabecera para tu oferta de empleo.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: AppTypography.regular,
        ),
      ),
      const SizedBox(height: 20),
      if (_loadingJobTypes)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (_jobTypesError != null)
        Column(
          children: <Widget>[
            Text(
              _jobTypesError!,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadJobTypes,
              child: const Text('Reintentar'),
            ),
          ],
        )
      else
        _labeledField(
          label: 'Tipo de empleo',
          child: DropdownButtonFormField<String>(
            initialValue: _jobTypeKey,
            isExpanded: true,
            decoration: _figmaDecoration(),
            hint: const Text('Selecciona un tipo de empleo'),
            items: _jobTypes
                .where((JobType jobType) => jobType.key.isNotEmpty)
                .map(
                  (JobType jobType) => DropdownMenuItem<String>(
                    value: jobType.key,
                    child: Text(jobType.label),
                  ),
                )
                .toList(),
            onChanged: isLoading ? null : _onJobTypeChanged,
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona un tipo de trabajo';
              }
              return null;
            },
          ),
        ),
      const SizedBox(height: 14),
      _labeledField(
        label: 'Tipo de contrato',
        child: DropdownButtonFormField<String>(
          initialValue: _contractType,
          isExpanded: true,
          decoration: _figmaDecoration(),
          hint: const Text('Selecciona un tipo de contrato'),
          items: const <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
              value: 'temporal',
              child: Text('Temporal (Por proyecto)'),
            ),
            DropdownMenuItem<String>(value: 'fijo', child: Text('Fijo')),
            DropdownMenuItem<String>(
              value: 'horas',
              child: Text('Por horas'),
            ),
          ],
          onChanged: isLoading
              ? null
              : (String? value) {
                  setState(() {
                    _contractType = value;
                  });
                },
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return 'Selecciona un tipo de contrato';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _labeledField(
              label: 'Salario',
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _figmaDecoration(),
                validator: (String? value) {
                  final double? amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Salario inválido';
                  }
                  return null;
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _labeledField(
              label: 'Moneda',
              child: DropdownButtonFormField<String>(
                initialValue: _currencyController.text.trim().isEmpty
                    ? 'DOP'
                    : _currencyController.text.trim(),
                isExpanded: true,
                decoration: _figmaDecoration(),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'DOP',
                    child: Text('RD\$ (Pesos)'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'USD',
                    child: Text('US\$ (Dólares)'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (String? value) {
                        setState(() {
                          _currencyController.text = value ?? 'DOP';
                        });
                      },
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _labeledField(
        label: 'Dirección',
        child: TextFormField(
          controller: _addressController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _figmaDecoration(prefixIcon: Icons.map_outlined),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Indica la dirección del trabajo';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 14),
      _labeledField(
        label: 'Ubicación',
        child: Column(
          children: <Widget>[
            InputDecorator(
              decoration: _figmaDecoration(
                prefixIcon: Icons.location_on_outlined,
              ),
              child: Text(
                _hasMapLocation
                    ? 'Ubicación marcada en el mapa'
                    : 'Aún no hay un punto en el mapa',
                style: TextStyle(
                  color: _hasMapLocation
                      ? AppColors.text
                      : Theme.of(context).hintColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _useCurrentLocation,
                    icon: _loadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Mi ubicación'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _selectLocationFromMap,
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Seleccionar mapa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _labeledField(
        label: 'Fecha límite',
        child: InkWell(
          onTap: isLoading ? null : _pickDeadline,
          child: InputDecorator(
            decoration: _figmaDecoration(
              prefixIcon: Icons.calendar_today_outlined,
            ),
            child: Text(
              _deadline == null
                  ? 'Selecciona una fecha'
                  : _deadlineLongLabel(_deadline!),
              style: TextStyle(
                color: _deadline == null
                    ? Theme.of(context).hintColor
                    : AppColors.text,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _buildCustomFieldsSection(enabled: !isLoading),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: isLoading ? null : _goNext,
        child: const Text('Siguiente'),
      ),
    ];
  }

  List<Widget> _buildStep2({required bool isLoading}) {
    final bool hasPhoto = _photo != null || _photoBytes != null;

    return <Widget>[
      const Text(
        'Detalles de la oferta',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: AppTypography.bold,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Describe las tareas y sube una fotografía para atraer mejores candidatos.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: AppTypography.regular,
        ),
      ),
      const SizedBox(height: 20),
      _labeledField(
        label: 'Descripción del empleo',
        child: TextFormField(
          controller: _descriptionController,
          minLines: 5,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: _figmaDecoration().copyWith(
            hintText: 'Describe las tareas, horario y requisitos del puesto...',
            alignLabelWithHint: true,
          ),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Requerido';
            }
            return null;
          },
        ),
      ),
      const SizedBox(height: 20),
      _labeledField(
        label: 'Fotografía de la oferta',
        child: hasPhoto
            ? _PhotoFilledCard(
                fileName: _photo ?? 'imagen.jpg',
                bytes: _photoBytes,
                uploading: _uploadingPhoto,
                enabled: !isLoading,
                onChange: _pickImage,
                onRemove: _removePhoto,
              )
            : _PhotoDropzone(
                uploading: _uploadingPhoto,
                enabled: !isLoading,
                onTap: _pickImage,
              ),
      ),
      const SizedBox(height: 20),
      _buildStepNavRow(
        isLoading: isLoading,
        onNext: _goNext,
      ),
    ];
  }

  Widget _buildStepNavRow({
    required bool isLoading,
    required VoidCallback onNext,
    String nextLabel = 'Siguiente',
  }) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 110,
          child: OutlinedButton(
            onPressed: isLoading ? null : _goBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Anterior'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isLoading ? null : onNext,
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildStep3({required bool isLoading}) {
    return <Widget>[
      const Text(
        'Preguntas para candidatos',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: AppTypography.bold,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Puedes agregar preguntas opcionales para conocer mejor a quienes apliquen.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          height: 1.4,
          fontWeight: AppTypography.regular,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : _addQuestion,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Agregar pregunta'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      if (_questions.isNotEmpty) ...<Widget>[
        const SizedBox(height: 12),
        ..._questions.asMap().entries.map(
          (MapEntry<int, _OfferQuestionForm> entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuestionCard(entry.key, enabled: !isLoading),
            );
          },
        ),
      ],
      const SizedBox(height: 8),
      _buildStepNavRow(isLoading: isLoading, onNext: _goNext),
    ];
  }

  List<Widget> _buildStep4({
    required bool isLoading,
    required CreateOfferViewModel createOfferViewModel,
  }) {
    const Color payGreen = Color(0xFF16A34A);
    final String jobTypeLabel = _selectedJobType?.label ?? _jobTypeKey ?? '';
    final String description = _descriptionController.text.trim().isEmpty
        ? 'Sin descripción'
        : _descriptionController.text.trim();

    return <Widget>[
      const Text(
        'Revisar oferta',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: AppTypography.bold,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Confirma los detalles de tu publicación antes de proceder al pago.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: AppTypography.regular,
        ),
      ),
      const SizedBox(height: 20),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_photoBytes != null) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 140,
                  child: Image.memory(
                    _photoBytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const ColoredBox(
                        color: AppColors.border,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.text,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      jobTypeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _contractReviewLabel(_contractType),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            const Text(
              'Descripción',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.4,
                fontWeight: AppTypography.regular,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            _ReviewDetailRow(
              icon: Icons.location_on_outlined,
              label: _addressController.text.trim().isEmpty
                  ? 'Sin dirección'
                  : _addressController.text.trim(),
            ),
            const SizedBox(height: 8),
            _ReviewDetailRow(
              icon: Icons.map_outlined,
              label: _hasMapLocation
                  ? 'Ubicación marcada en el mapa'
                  : 'Sin punto en el mapa',
            ),
            const SizedBox(height: 8),
            _ReviewDetailRow(
              icon: Icons.calendar_today_outlined,
              label: _deadline == null
                  ? 'Sin fecha límite'
                  : _deadlineLongLabel(_deadline!),
            ),
            if (_selectedJobType != null &&
                _selectedJobType!.customFields.isNotEmpty) ...<Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.border),
              ),
              const Text(
                'Campos personalizados',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: AppTypography.medium,
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedJobType!.customFields.map(
                (CustomField field) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReviewDetailRow(
                    icon: Icons.tune_outlined,
                    label: '${field.label}: ${_customFieldReviewText(field)}',
                  ),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            const Text(
              'Preguntas para candidatos',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 8),
            if (_questions
                .where(
                  (_OfferQuestionForm q) =>
                      q.labelController.text.trim().isNotEmpty,
                )
                .isEmpty)
              _ReviewDetailRow(
                icon: Icons.help_outline,
                label: _questionsReviewLabel(),
              )
            else
              ..._questions
                  .where(
                    (_OfferQuestionForm q) =>
                        q.labelController.text.trim().isNotEmpty,
                  )
                  .map(
                    (_OfferQuestionForm question) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ReviewDetailRow(
                        icon: Icons.help_outline,
                        label: _questionReviewLine(question),
                        maxLines: 3,
                      ),
                    ),
                  ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),
            const Text(
              'Pago ofrecido',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: AppTypography.medium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _salaryReviewLabel(),
              style: const TextStyle(
                color: payGreen,
                fontSize: 20,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.08),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'TARIFA DE PUBLICACIÓN',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'US\$1.00',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 32,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Esta tarifa es necesaria para publicar la oferta de empleo y mantenerla activa por 30 días.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
                fontWeight: AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
      if (createOfferViewModel.status == CreateOfferStatus.error &&
          createOfferViewModel.errorMessage != null) ...<Widget>[
        const SizedBox(height: 12),
        Text(
          createOfferViewModel.errorMessage!,
          style: const TextStyle(color: AppColors.error),
        ),
      ],
      const SizedBox(height: 20),
      if (isLoading)
        const Center(child: CircularProgressIndicator())
      else ...<Widget>[
        FilledButton(
          onPressed: _publishedSuccessfully ? null : _submit,
          child: Text(
            _publishedSuccessfully
                ? 'Oferta publicada'
                : 'Continuar al pago',
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Anterior'),
          ),
        ),
      ],
    ];
  }

}

class _ReviewDetailRow extends StatelessWidget {
  const _ReviewDetailRow({
    required this.icon,
    required this.label,
    this.maxLines = 2,
  });

  final IconData icon;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.text),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: AppTypography.regular,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoDropzone extends StatelessWidget {
  const _PhotoDropzone({
    required this.uploading,
    required this.enabled,
    required this.onTap,
  });

  final bool uploading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: enabled && !uploading ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: const _DashedRRectPainter(
            color: AppColors.text,
            radius: 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: <Widget>[
                  if (uploading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.image_outlined,
                      size: 24,
                      color: AppColors.text,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    uploading ? 'Subiendo imagen...' : 'Agregar fotografía',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: AppTypography.medium,
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

class _PhotoFilledCard extends StatelessWidget {
  const _PhotoFilledCard({
    required this.fileName,
    required this.bytes,
    required this.uploading,
    required this.enabled,
    required this.onChange,
    required this.onRemove,
  });

  final String fileName;
  final Uint8List? bytes;
  final bool uploading;
  final bool enabled;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 60,
              height: 60,
              child: bytes == null
                  ? const ColoredBox(
                      color: AppColors.border,
                      child: Icon(Icons.image_outlined, color: AppColors.text),
                    )
                  : Image.memory(
                      bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return const ColoredBox(
                          color: AppColors.border,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.text,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                const SizedBox(height: 4),
                if (uploading)
                  const Text(
                    'Subiendo imagen...',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: AppTypography.medium,
                    ),
                  )
                else
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: enabled ? onChange : null,
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: enabled ? onRemove : null,
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final ui.Path path = ui.Path()..addRRect(rrect);
    const double dash = 6;
    const double gap = 4;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

// ================================================================
// DIÁLOGO DE ÉXITO AL PUBLICAR
// ================================================================

class _PublishSuccessDialog extends StatelessWidget {
  const _PublishSuccessDialog({
    required this.onViewPublications,
    required this.onClose,
  });

  final VoidCallback onViewPublications;
  final VoidCallback onClose;

  static const Color _successGreen = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: _successGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oferta publicada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: AppTypography.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El pago fue aprobado y tu oferta ya está disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                height: 1.5,
                fontWeight: AppTypography.regular,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onViewPublications,
                child: const Text('Ver mis publicaciones'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.text,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: AppTypography.medium,
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// RESULTADO DEL MODAL DE CONFIRMACIÓN DE PAGO
// ================================================================

class _PaymentConfirmationResult {
  const _PaymentConfirmationResult({
    required this.cardNumber,
    required this.cvv,
    required this.expMonth,
    required this.expYear,
    this.cardholder,
  });

  final String cardNumber;
  final String cvv;
  final int expMonth;
  final int expYear;
  final String? cardholder;
}

class _CardPaymentDialog extends StatefulWidget {
  const _CardPaymentDialog();

  @override
  State<_CardPaymentDialog> createState() => _CardPaymentDialogState();
}

class _TestCard {
  const _TestCard({
    required this.label,
    required this.number,
    required this.cvv,
    required this.expMonth,
    required this.expYear,
  });

  final String label;
  final String number;
  final String cvv;
  final int expMonth;
  final int expYear;
}

const List<_TestCard> _testCards = <_TestCard>[
  _TestCard(
    label: 'Prueba aprobada — 4242 4242 4242 4242',
    number: '4242424242424242',
    cvv: '123',
    expMonth: 12,
    expYear: 2030,
  ),
  _TestCard(
    label: 'Prueba rechazada — 4000 0000 0000 0002',
    number: '4000000000000002',
    cvv: '123',
    expMonth: 12,
    expYear: 2030,
  ),
];

class _CardPaymentDialogState extends State<_CardPaymentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cardholderController = TextEditingController();
  final TextEditingController _expMonthController = TextEditingController();
  final TextEditingController _expYearController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  _TestCard? _selectedCard;

  @override
  void dispose() {
    _cardholderController.dispose();
    _expMonthController.dispose();
    _expYearController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _applyTestCard(_TestCard? card) {
    setState(() {
      _selectedCard = card;
      if (card == null) {
        _expMonthController.clear();
        _expYearController.clear();
        _cvvController.clear();
        return;
      }

      _expMonthController.text = card.expMonth.toString().padLeft(2, '0');
      _expYearController.text = card.expYear.toString();
      _cvvController.text = card.cvv;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final _TestCard selectedCard = _selectedCard!;
    Navigator.of(context).pop(
      _PaymentConfirmationResult(
        cardNumber: selectedCard.number,
        cvv: selectedCard.cvv,
        expMonth: selectedCard.expMonth,
        expYear: selectedCard.expYear,
        cardholder: _cardholderController.text.trim(),
      ),
    );
  }

  InputDecoration _sheetDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.all(12),
    );
  }

  Widget _sheetField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: AppTypography.medium,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color secureGreen = Color(0xFF16A34A);

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
            child: Form(
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
                          'Realizar pago',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: secureGreen.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.lock_outline,
                              size: 12,
                              color: secureGreen,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Seguro',
                              style: TextStyle(
                                color: secureGreen,
                                fontSize: 11,
                                fontWeight: AppTypography.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Tarifa de publicación',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: AppTypography.regular,
                            ),
                          ),
                        ),
                        Text(
                          'US\$1.00',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sheetField(
                    label: 'Número de tarjeta',
                    child: DropdownButtonFormField<_TestCard>(
                      initialValue: _selectedCard,
                      isExpanded: true,
                      decoration: _sheetDecoration(
                        prefixIcon: const Icon(
                          Icons.credit_card_outlined,
                          size: 18,
                        ),
                      ),
                      hint: const Text('Selecciona una tarjeta de prueba'),
                      items: _testCards.map((_TestCard card) {
                        return DropdownMenuItem<_TestCard>(
                          value: card,
                          child: Text(
                            card.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _applyTestCard,
                      validator: (_TestCard? value) {
                        if (value == null) {
                          return 'Selecciona una tarjeta de prueba';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sheetField(
                    label: 'Nombre del titular',
                    child: TextFormField(
                      controller: _cardholderController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _sheetDecoration().copyWith(
                        hintText: 'JUAN PEREZ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _sheetField(
                          label: 'MM',
                          child: TextFormField(
                            controller: _expMonthController,
                            readOnly: true,
                            decoration: _sheetDecoration().copyWith(
                              hintText: 'MM',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sheetField(
                          label: 'YYYY',
                          child: TextFormField(
                            controller: _expYearController,
                            readOnly: true,
                            decoration: _sheetDecoration().copyWith(
                              hintText: 'YYYY',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _sheetField(
                          label: 'CVV',
                          child: TextFormField(
                            controller: _cvvController,
                            readOnly: true,
                            obscureText: true,
                            decoration: _sheetDecoration().copyWith(
                              hintText: '123',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Pagar US\$1.00 y publicar'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancelar'),
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

// ================================================================
// PREGUNTAS ADICIONALES DE LA OFERTA
// ================================================================

/// Etiquetas legibles para cada valor de OfferQuestionType
/// (definido en data/models/offer_question.dart).
const Map<String, String> _questionTypeLabels = {
  OfferQuestionType.text: 'Texto libre',
  OfferQuestionType.date: 'Fecha',
  OfferQuestionType.select: 'Selección múltiple',
  OfferQuestionType.check: 'Casilla de verificación',
};

bool _typeSupportsOptions(String type) => type == OfferQuestionType.select;

class _OfferQuestionForm {
  final TextEditingController labelController = TextEditingController();
  String type = OfferQuestionType.text;
  bool required = false;
  List<TextEditingController> optionControllers = [];

  void dispose() {
    labelController.dispose();
    for (final controller in optionControllers) {
      controller.dispose();
    }
  }

  bool get isValid {
    if (labelController.text.trim().isEmpty) return false;

    if (_typeSupportsOptions(type)) {
      final validOptions = optionControllers
          .map((c) => c.text.trim())
          .where((o) => o.isNotEmpty)
          .length;
      if (validOptions < 2) return false;
    }

    return true;
  }

  OfferQuestion toOfferQuestion() {
    return OfferQuestion(
      label: labelController.text.trim(),
      type: type,
      required: required,
      options: _typeSupportsOptions(type)
          ? optionControllers
                .map((c) => c.text.trim())
                .where((o) => o.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

// ================================================================
// SELECTOR DE UBICACIÓN EN MAPA - OPENSTREETMAP
// ================================================================

class _MapLocationPicker extends StatefulWidget {
  final LatLng initialPosition;

  const _MapLocationPicker({required this.initialPosition});

  @override
  State<_MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<_MapLocationPicker> {
  late LatLng _selectedPosition;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    _selectedPosition = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seleccionar ubicación',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialPosition,
                initialZoom: 16,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPosition = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'do.edu.itla.ocupa2',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedPosition);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Usar esta ubicación'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

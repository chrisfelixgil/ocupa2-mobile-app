import 'dart:typed_data';

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
import 'package:ocupa2/features/job_posting/data/custom_field_date.dart';

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

  String _formatJobType(String key) {
    return key.replaceAll('_', ' ');
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 16),
        const Text(
          'Datos adicionales del tipo de trabajo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...jobType.customFields.map(
          (CustomField field) => Padding(
            key: ValueKey<String>('${jobType.key}-${field.key}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCustomFieldControl(field, enabled: enabled),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFieldControl(CustomField field, {required bool enabled}) {
    final String label = field.required ? '${field.label} *' : field.label;

    switch (field.type) {
      case 'number':
        return TextFormField(
          controller: _customTextControllers[field.key],
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );
      case 'date':
        final DateTime? selected = _customDates[field.key];
        return InkWell(
          onTap: enabled ? () => _pickCustomDate(field) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
            child: Text(
              selected == null
                  ? 'Selecciona una fecha'
                  : CustomFieldDate.toDisplay(selected),
              style: TextStyle(
                color: selected == null ? Theme.of(context).hintColor : null,
              ),
            ),
          ),
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _customSelectValues[field.key],
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
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
        return TextFormField(
          controller: _customTextControllers[field.key],
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        );
    }
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Future<void> _pickImage() async {
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
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  // Update type of a question and clear options if not applicable
  void _updateQuestionType(int index, String type) {
    setState(() {
      _questions[index].type = type;
      if (!_typeSupportsOptions(type)) {
        for (var ctrl in _questions[index].optionControllers) {
          ctrl.dispose();
        }
        _questions[index].optionControllers.clear();
      }
    });
  }

  // Update required flag
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

  // Update option text
  void _updateOption(int questionIndex, int optionIndex, String value) {
    setState(() {
      _questions[questionIndex].optionControllers[optionIndex].text = value;
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

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pregunta ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
            TextFormField(
              controller: question.labelController,
              decoration: const InputDecoration(
                labelText: 'Texto de la pregunta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: question.type,
              decoration: const InputDecoration(
                labelText: 'Tipo de respuesta',
                border: OutlineInputBorder(),
              ),
              items: _questionTypeLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  question.type = value;
                });
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('¿Es obligatoria?'),
              value: question.required,
              onChanged: (value) {
                setState(() {
                  question.required = value;
                });
              },
            ),
            if (_typeSupportsOptions(question.type)) ...[
              const SizedBox(height: 4),
              const Text(
                'Opciones',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...List.generate(question.optionControllers.length, (optIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: question.optionControllers[optIndex],
                          decoration: InputDecoration(
                            labelText: 'Opción ${optIndex + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeOption(index, optIndex),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addOption(index),
                icon: const Icon(Icons.add),
                label: const Text('Agregar opción'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MODAL DE CONFIRMACIÓN DE PAGO
  // ============================================================

  Future<bool> _confirmPublicationFee() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Costo de publicación'),
          content: const Text(
            'Publicar esta oferta tiene un costo de US\$1.00.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continuar al pago'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _showPublishSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Oferta publicada correctamente'),
          content: const Text(
            'El pago de US\$1.00 fue aprobado y tu oferta ya fue publicada.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (!context.mounted) {
                  return;
                }
                context.goNamed(AppRouteNames.jobPostingMyOffers);
              },
              child: const Text('Ver mis publicaciones'),
            ),
          ],
        );
      },
    );
  }

  Future<_PaymentConfirmationResult?> _showCardPaymentDialog() {
    return showDialog<_PaymentConfirmationResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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

    final bool continueToPayment = await _confirmPublicationFee();
    if (!mounted) {
      return;
    }
    if (!continueToPayment) {
      return;
    }

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
        _showMessage(
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

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar oferta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ==================================================
              // TIPO DE TRABAJO
              // ==================================================
              if (_loadingJobTypes)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_jobTypesError != null)
                Column(
                  children: [
                    Text(
                      _jobTypesError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadJobTypes,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _jobTypeKey,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de trabajo',
                    border: OutlineInputBorder(),
                  ),
                  items: _jobTypes
                      .where((jobType) => jobType.key.isNotEmpty)
                      .map(
                        (jobType) => DropdownMenuItem<String>(
                          value: jobType.key,
                          child: Text(_formatJobType(jobType.key)),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading ? null : _onJobTypeChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona un tipo de trabajo';
                    }

                    return null;
                  },
                ),

              _buildCustomFieldsSection(enabled: !isLoading),

              const SizedBox(height: 12),

              // ==================================================
              // TIPO DE CONTRATO
              // ==================================================
              DropdownButtonFormField<String>(
                initialValue: _contractType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de contrato',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'temporal', child: Text('Temporal')),
                  DropdownMenuItem(value: 'fijo', child: Text('Fijo')),
                  DropdownMenuItem(value: 'horas', child: Text('Por horas')),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _contractType = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona un tipo de contrato';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // DESCRIPCIÓN
              // ==================================================
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requerido';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ==================================================
              // UBICACIÓN
              // ==================================================
              const Text(
                'Ubicación del trabajo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _addressController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  hintText: 'Calle, sector o ciudad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Indica la dirección del trabajo';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _useCurrentLocation,
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Mi ubicación'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _selectLocationFromMap,
                      icon: const Icon(Icons.map),
                      label: const Text('Seleccionar mapa'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // LATITUD / LONGITUD
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // MONTO
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Salario del trabajo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(
                        labelText: 'Moneda del salario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FOTO
              // ==================================================
              const Text(
                'Foto del trabajo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              if (_photoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _photoBytes!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image, size: 60),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickImage,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library),
                  label: Text(
                    _uploadingPhoto
                        ? 'Subiendo imagen...'
                        : _photo == null
                        ? 'Seleccionar foto'
                        : 'Cambiar foto',
                  ),
                ),
              ),

              if (_photoUrl != null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Imagen subida correctamente',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                ),

              if (_photo == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'La foto es obligatoria',
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),

              // ==================================================
              // FECHA
              // ==================================================
              InkWell(
                onTap: isLoading ? null : _pickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha límite',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  child: Text(
                    _deadline == null
                        ? 'Selecciona una fecha'
                        : CustomFieldDate.toDisplay(_deadline!),
                    style: TextStyle(
                      color: _deadline == null
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PREGUNTAS ADICIONALES
              // ==================================================
              const Text(
                'Preguntas adicionales (opcional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrega preguntas que el postulante deberá responder al aplicar.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),

              ..._questions.asMap().entries.map(
                (e) => _buildQuestionCard(e.key),
              ),

              OutlinedButton.icon(
                onPressed: isLoading ? null : _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Agregar pregunta'),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // ERROR
              // ==================================================
              if (createOfferViewModel.status == CreateOfferStatus.error &&
                  createOfferViewModel.errorMessage != null)
                Text(
                  createOfferViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 12),

              // ==================================================
              // BOTÓN PUBLICAR
              // ==================================================
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _publishedSuccessfully ? null : _submit,
                    child: Text(
                      _publishedSuccessfully
                          ? 'Oferta publicada'
                          : 'Publicar oferta',
                    ),
                  ),
                ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pago de publicación'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Costo: US\$1.00',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_TestCard>(
                value: _selectedCard,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Selecciona una tarjeta de prueba'),
                items: _testCards.map((_TestCard card) {
                  return DropdownMenuItem<_TestCard>(
                    value: card,
                    child: Text(card.label, overflow: TextOverflow.ellipsis),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _cardholderController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _expMonthController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _expYearController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      readOnly: true,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Pagar US\$1.00')),
      ],
    );
  }
}

// ================================================================
// PREGUNTAS ADICIONALES DE LA OFERTA
// ================================================================

/// Etiquetas legibles para cada valor de OfferQuestionType
/// (definido en data/models/offer_question.dart).
const Map<String, String> _questionTypeLabels = {
  OfferQuestionType.text: 'Texto',
  OfferQuestionType.date: 'Fecha',
  OfferQuestionType.select: 'Selección',
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

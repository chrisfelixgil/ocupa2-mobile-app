import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../catalog/data/models/job_type.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../payments/presentation/viewmodels/make_payment_view_model.dart';
import '../../../job_search/presentation/viewmodels/explore_offers_view_model.dart';
import '../../data/models/offer_question.dart';
import '../viewmodels/create_offer_status.dart';
import '../viewmodels/create_offer_view_model.dart';
import 'package:ocupa2/features/job_posting/data/services/upload_service.dart';

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

  final List<_OfferQuestionDraft> _questions = <_OfferQuestionDraft>[];

  String? _jobTypeKey;
  String? _contractType;

  /// Ruta local de la imagen seleccionada.
  String? _photo;

  /// URL pública devuelta por el endpoint de subida.
  String? _photoUrl;

  DateTime? _deadline;

  List<JobType> _jobTypes = [];
  bool _loadingJobTypes = true;
  String? _jobTypesError;

  bool _loadingLocation = false;
  bool _uploadingPhoto = false;

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
        _photo = image.path;
        _photoUrl = null;
        _uploadingPhoto = true;
      });

      final uploadService = context.read<UploadService>();
      final uploadedUrl = await uploadService.uploadImage(image.path);

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
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showMessage(
        'Activa la ubicación de tu dispositivo.',
      );
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showMessage(
        'Se necesita permiso para acceder a tu ubicación.',
      );
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

  Future<String> _getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      if (placemarks.isEmpty) {
        return '';
      }

      final place = placemarks.first;

      final parts = <String>[
        if (place.street != null &&
            place.street!.trim().isNotEmpty)
          place.street!.trim(),

        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty)
          place.subLocality!.trim(),

        if (place.locality != null &&
            place.locality!.trim().isNotEmpty)
          place.locality!.trim(),

        if (place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea!.trim(),
      ];

      return parts.join(', ');
    } catch (e) {
      debugPrint(
        'ERROR OBTENIENDO DIRECCIÓN: $e',
      );

      return '';
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_loadingLocation) return;

    setState(() {
      _loadingLocation = true;
    });

    try {
      final hasPermission =
          await _checkLocationPermission();

      if (!hasPermission) {
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      final address =
          await _getAddressFromCoordinates(
        lat,
        lng,
      );

      if (!mounted) return;

      setState(() {
        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        _addressController.text = address;
      });

      if (address.isEmpty) {
        _showMessage(
          'Ubicación obtenida, pero no se pudo determinar la dirección.',
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR OBTENIENDO UBICACIÓN: $e',
      );

      if (mounted) {
        _showMessage(
          'No se pudo obtener la ubicación actual.',
        );
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

    final currentLat =
        double.tryParse(_latController.text);

    final currentLng =
        double.tryParse(_lngController.text);

    if (currentLat != null && currentLng != null) {
      initialPosition = LatLng(
        currentLat,
        currentLng,
      );
    } else {
      try {
        final hasPermission =
            await _checkLocationPermission();

        if (hasPermission) {
          final position =
              await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          initialPosition = LatLng(
            position.latitude,
            position.longitude,
          );
        } else {
          initialPosition = const LatLng(
            18.4861,
            -69.9312,
          );
        }
      } catch (_) {
        initialPosition = const LatLng(
          18.4861,
          -69.9312,
        );
      }
    }

    if (!mounted) return;

    final selectedLocation =
        await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _MapLocationPicker(
          initialPosition: initialPosition,
        );
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

      final address =
          await _getAddressFromCoordinates(
        lat,
        lng,
      );

      if (!mounted) return;

      setState(() {
        _latController.text = lat.toString();
        _lngController.text = lng.toString();
        _addressController.text = address;
      });

      if (address.isEmpty) {
        _showMessage(
          'Ubicación seleccionada, pero no se pudo obtener la dirección.',
        );
      }
    } catch (e) {
      debugPrint(
        'ERROR PROCESANDO UBICACIÓN: $e',
      );

      if (mounted) {
        _showMessage(
          'No se pudo procesar la ubicación seleccionada.',
        );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // FECHA
  // ============================================================

  Future<void> _pickDeadline() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(
        const Duration(days: 7),
      ),
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _addQuestion() {
    setState(() {
      _questions.add(
        const _OfferQuestionDraft(
          label: '',
          type: OfferQuestionType.text,
          required: false,
          options: <String>[],
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _updateQuestionLabel(int index, String value) {
    setState(() {
      _questions[index] = _questions[index].copyWith(label: value);
    });
  }

  void _updateQuestionType(int index, String value) {
    setState(() {
      _questions[index] = _questions[index].copyWith(
        type: value,
        options: value == OfferQuestionType.select
            ? (_questions[index].options.isEmpty ? const <String>[''] : _questions[index].options)
            : const <String>[],
      );
    });
  }

  void _updateQuestionRequired(int index, bool value) {
    setState(() {
      _questions[index] = _questions[index].copyWith(required: value);
    });
  }

  void _addOption(int index) {
    setState(() {
      _questions[index] = _questions[index].copyWith(
        options: <String>[..._questions[index].options, ''],
      );
    });
  }

  void _updateOption(int questionIndex, int optionIndex, String value) {
    setState(() {
      final List<String> updatedOptions = [..._questions[questionIndex].options];
      updatedOptions[optionIndex] = value;
      _questions[questionIndex] = _questions[questionIndex].copyWith(
        options: updatedOptions,
      );
    });
  }

  void _removeOption(int questionIndex, int optionIndex) {
    setState(() {
      final List<String> updatedOptions = [..._questions[questionIndex].options];
      if (optionIndex < updatedOptions.length) {
        updatedOptions.removeAt(optionIndex);
      }
      _questions[questionIndex] = _questions[questionIndex].copyWith(
        options: updatedOptions,
      );
    });
  }

  String? _validateAdditionalQuestions() {
    for (final _OfferQuestionDraft draft in _questions) {
      final String label = draft.label.trim();
      if (label.isEmpty) {
        continue;
      }

      if (draft.type == OfferQuestionType.select) {
        final List<String> validOptions = draft.options
            .map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList();

        if (validOptions.length < 2) {
          return 'La pregunta "$label" de tipo selección necesita al menos 2 opciones.';
        }
      }
    }

    return null;
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latController.text.trim().isEmpty ||
        _lngController.text.trim().isEmpty) {
      _showMessage(
        'Selecciona una ubicación.',
      );
      return;
    }

    if (_deadline == null) {
      _showMessage(
        'Selecciona la fecha límite.',
      );
      return;
    }

    if (_photo == null ||
        _photoUrl == null ||
        _photoUrl!.isEmpty) {
      _showMessage(
        'Selecciona y espera a que se suba la foto.',
      );
      return;
    }

    if (_uploadingPhoto) {
      _showMessage(
        'Espera a que termine de subir la imagen.',
      );
      return;
    }

    final String? questionError = _validateAdditionalQuestions();
    if (questionError != null) {
      _showMessage(questionError);
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim(),
    );

    if (amount == null || amount <= 0) {
      _showMessage(
        'El monto debe ser válido.',
      );
      return;
    }

    final currency =
        _currencyController.text.trim();

    final List<OfferQuestion> questions = _questions
        .where((draft) => draft.label.trim().isNotEmpty)
        .map((draft) {
          final String normalizedType = draft.type == OfferQuestionType.boolean
              ? OfferQuestionType.check
              : draft.type;
          final List<String> options = normalizedType == OfferQuestionType.select
              ? draft.options
                  .map((option) => option.trim())
                  .where((option) => option.isNotEmpty)
                  .toList()
              : const <String>[];

          return OfferQuestion(
            label: draft.label.trim(),
            type: normalizedType,
            required: draft.required,
            options: options,
          );
        })
        .toList();

    final createOfferViewModel =
        context.read<CreateOfferViewModel>();

    final paymentViewModel =
        context.read<MakePaymentViewModel>();

    final paymentOk =
        await paymentViewModel.pay(
      amount: amount,
      currency: currency,
      cardNumber: '4242424242424242',
      cvv: '123',
      expMonth: 12,
      expYear: 2030,
      cardholder: 'Proveedor',
    );

    if (!mounted) return;

    if (!paymentOk) {
      _showMessage(
        paymentViewModel.errorMessage ??
            'No se pudo realizar el pago',
      );
      return;
    }

    final payment =
        paymentViewModel.payment;

    if (payment == null ||
        payment.id.isEmpty) {
      _showMessage(
        'El pago fue realizado, pero no se recibió su ID',
      );
      return;
    }

    final offerOk =
        await createOfferViewModel.submit(
      jobTypeKey: _jobTypeKey!,
      contractType: _contractType!,
      description:
          _descriptionController.text.trim(),
      address:
          _addressController.text.trim(),

      // Se envía la URL pública, no la ruta local.
      photo: _photoUrl,

      paymentId: payment.id,
      lat: double.parse(
        _latController.text.trim(),
      ),
      lng: double.parse(
        _lngController.text.trim(),
      ),
      amount: amount,
      currency: currency,
      deadline: _deadline!,
      questions: questions,
    );

    if (!mounted) return;

    if (offerOk) {
      context.read<ExploreOffersViewModel>().load();

      _showMessage(
        'Pago realizado y oferta publicada correctamente',
      );

      Navigator.of(context).pop();
    } else {
      _showMessage(
        createOfferViewModel.errorMessage ??
            'El pago se realizó, pero no se pudo publicar la oferta',
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final createOfferViewModel =
        context.watch<CreateOfferViewModel>();

    final paymentViewModel =
        context.watch<MakePaymentViewModel>();

    final isLoading =
        createOfferViewModel.isSubmitting ||
        paymentViewModel.isSubmitting ||
        _loadingLocation ||
        _uploadingPhoto;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar oferta'),
      ),
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
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadJobTypes,
                      child: const Text(
                        'Reintentar',
                      ),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _jobTypeKey,
                  decoration:
                      const InputDecoration(
                    labelText: 'Tipo de trabajo',
                    border: OutlineInputBorder(),
                  ),
                  items: _jobTypes
                      .where(
                        (jobType) =>
                            jobType.key.isNotEmpty,
                      )
                      .map(
                        (jobType) =>
                            DropdownMenuItem<String>(
                          value: jobType.key,
                          child: Text(
                            _formatJobType(
                              jobType.key,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _jobTypeKey = value;
                          });
                        },
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty) {
                      return 'Selecciona un tipo de trabajo';
                    }

                    return null;
                  },
                ),

              const SizedBox(height: 12),

              // ==================================================
              // TIPO DE CONTRATO
              // ==================================================

              DropdownButtonFormField<String>(
                initialValue: _contractType,
                decoration:
                    const InputDecoration(
                  labelText: 'Tipo de contrato',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'temporal',
                    child: Text('Temporal'),
                  ),
                  DropdownMenuItem(
                    value: 'fijo',
                    child: Text('Fijo'),
                  ),
                  DropdownMenuItem(
                    value: 'horas',
                    child: Text('Por horas'),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _contractType = value;
                        });
                      },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
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
                controller:
                    _descriptionController,
                maxLines: 4,
                decoration:
                    const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller:
                    _addressController,
                readOnly: true,
                decoration:
                    const InputDecoration(
                  labelText: 'Dirección',
                  hintText:
                      'Selecciona una ubicación',
                  border: OutlineInputBorder(),
                  prefixIcon:
                      Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Selecciona una ubicación';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : _useCurrentLocation,
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                            ),
                      label: const Text(
                        'Mi ubicación',
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : _selectLocationFromMap,
                      icon: const Icon(
                        Icons.map,
                      ),
                      label: const Text(
                        'Seleccionar mapa',
                      ),
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
                      controller:
                          _latController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        labelText: 'Latitud',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller:
                          _lngController,
                      readOnly: true,
                      decoration:
                          const InputDecoration(
                        labelText: 'Longitud',
                        border:
                            OutlineInputBorder(),
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
                      controller:
                          _amountController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText: 'Monto',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller:
                          _currencyController,
                      decoration:
                          const InputDecoration(
                        labelText: 'Moneda',
                        border:
                            OutlineInputBorder(),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              if (_photo != null)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Image.file(
                    File(_photo!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        alignment:
                            Alignment.center,
                        decoration:
                            BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons.image,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      isLoading ? null : _pickImage,
                  icon: _uploadingPhoto
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.photo_library,
                        ),
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
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Imagen subida correctamente',
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_photo == null)
                const Padding(
                  padding:
                      EdgeInsets.only(top: 4),
                  child: Text(
                    'La foto es obligatoria',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ==================================================
              // FECHA
              // ==================================================

              ListTile(
                contentPadding:
                    EdgeInsets.zero,
                title: Text(
                  _deadline == null
                      ? 'Selecciona fecha límite'
                      : 'Fecha límite: '
                          '${_deadline!.toLocal()}'
                              .split(' ')
                              .first,
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                ),
                onTap: isLoading
                    ? null
                    : _pickDeadline,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PREGUNTAS ADICIONALES
              // ==================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Preguntas adicionales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_questions.isEmpty)
                const Text(
                  'Sin preguntas extras. Puedes dejarla vacía y el aplicante solo enviará un comentario.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._questions.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final _OfferQuestionDraft draft = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                initialValue: draft.label,
                                decoration: const InputDecoration(
                                  labelText: 'Pregunta',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _updateQuestionLabel(index, value),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeQuestion(index),
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Eliminar pregunta',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: draft.type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            border: OutlineInputBorder(),
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: OfferQuestionType.text,
                              child: Text('Texto corto'),
                            ),
                            DropdownMenuItem<String>(
                              value: OfferQuestionType.date,
                              child: Text('Fecha'),
                            ),
                            DropdownMenuItem<String>(
                              value: OfferQuestionType.select,
                              child: Text('Selección'),
                            ),
                            DropdownMenuItem<String>(
                              value: OfferQuestionType.check,
                              child: Text('Casilla / sí o no'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value != null) {
                              _updateQuestionType(index, value);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Obligatoria'),
                          value: draft.required,
                          onChanged: (value) => _updateQuestionRequired(index, value),
                        ),
                        if (draft.type == OfferQuestionType.select) ...<Widget>[
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Opciones',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _addOption(index),
                                icon: const Icon(Icons.add),
                                label: const Text('Opción'),
                              ),
                            ],
                          ),
                          ...draft.options.asMap().entries.map((optionEntry) {
                            final int optionIndex = optionEntry.key;
                            final String option = optionEntry.value;
                            return Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    initialValue: option,
                                    decoration: InputDecoration(
                                      labelText: 'Opción ${optionIndex + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => _updateOption(index, optionIndex, value),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeOption(index, optionIndex),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // ==================================================
              // ERROR
              // ==================================================

              if (createOfferViewModel
                          .status ==
                      CreateOfferStatus.error &&
                  createOfferViewModel
                          .errorMessage !=
                      null)
                Text(
                  createOfferViewModel
                      .errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),

              const SizedBox(height: 12),

              // ==================================================
              // BOTÓN PUBLICAR
              // ==================================================

              if (isLoading)
                const Center(
                  child:
                      CircularProgressIndicator(),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text(
                      'Pagar y publicar oferta',
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
// SELECTOR DE UBICACIÓN EN MAPA - OPENSTREETMAP
// ================================================================

class _OfferQuestionDraft {
  const _OfferQuestionDraft({
    required this.label,
    required this.type,
    required this.required,
    required this.options,
  });

  final String label;
  final String type;
  final bool required;
  final List<String> options;

  _OfferQuestionDraft copyWith({
    String? label,
    String? type,
    bool? required,
    List<String>? options,
  }) {
    return _OfferQuestionDraft(
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
    );
  }
}

class _MapLocationPicker extends StatefulWidget {
  final LatLng initialPosition;

  const _MapLocationPicker({
    required this.initialPosition,
  });

  @override
  State<_MapLocationPicker> createState() =>
      _MapLocationPickerState();
}

class _MapLocationPickerState
    extends State<_MapLocationPicker> {
  late LatLng _selectedPosition;

  final MapController _mapController =
      MapController();

  @override
  void initState() {
    super.initState();

    _selectedPosition =
        widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height *
              0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seleccionar ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: FlutterMap(
              mapController:
                  _mapController,
              options: MapOptions(
                initialCenter:
                    widget.initialPosition,
                initialZoom: 16,

                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPosition =
                        point;
                  });
                },
              ),

              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'do.edu.itla.ocupa2',
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          _selectedPosition,
                      width: 50,
                      height: 50,
                      alignment:
                          Alignment.topCenter,
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
              padding:
                  const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(
                      _selectedPosition,
                    );
                  },
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text(
                    'Usar esta ubicación',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
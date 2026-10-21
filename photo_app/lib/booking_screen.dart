import 'package:Picon/api_service.dart';
import 'package:Picon/models/booking.dart';
import 'package:Picon/utils/app_error.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _commentsController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  final List<String> _services = [
    'Shooting Photo Basique',
    'Forfait Événementiel',
    'Forfait Mariage',
    "Photos d'identité",
    'Tirage Photos',
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  BookingType _typeForService(String title) {
    switch (title) {
      case 'Forfait Événementiel':
      case 'Forfait Mariage':
        return BookingType.event;
      case "Photos d'identité":
        return BookingType.portrait;
      case 'Tirage Photos':
        return BookingType.other;
      default:
        return BookingType.photoSession;
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null || _selectedDate == null || _selectedTime == null) {
      return;
    }
    if (ApiService.userId == null) {
      await showAppError(context, AppError.session());
      return;
    }

    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final booking = Booking.fromId(
      title: _selectedService!,
      description: _commentsController.text,
      userId: ApiService.userId!,
      startTime: scheduledTime,
      endTime: scheduledTime.add(const Duration(hours: 1)),
      type: _typeForService(_selectedService!),
      amount: 0.0,
    );

    try {
      final created = await ApiService.createBooking(booking);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation #${created.id} enregistrée.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) await showAppError(context, e);
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: piconBar('Faire une réservation'),
      body: Stack(
        children: [
          const GeometricBackground(),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Form(
                key: _formKey,
                child: PiconCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedService,
                        isExpanded: true,
                        decoration: piconField('Type de service'),
                        items: _services.map((String service) {
                          return DropdownMenuItem<String>(value: service, child: Text(service));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedService = newValue),
                        validator: (value) => value == null ? 'Veuillez choisir un service' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: piconField(
                          'Date de la séance',
                          icon: Icons.calendar_today,
                          hint: 'Sélectionnez une date',
                        ),
                        onTap: _selectDate,
                        validator: (value) => _selectedDate == null ? 'Veuillez choisir une date' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        decoration: piconField(
                          'Heure de la séance',
                          icon: Icons.access_time,
                          hint: 'Sélectionnez une heure',
                        ),
                        onTap: _selectTime,
                        validator: (value) => _selectedTime == null ? 'Veuillez choisir une heure' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _commentsController,
                        decoration: piconField('Commentaires additionnels (facultatif)'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      PiconButton(
                        label: 'Confirmer la réservation',
                        onPressed: _submitBooking,
                      ),
                    ],
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

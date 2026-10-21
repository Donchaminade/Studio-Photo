import 'package:flutter/material.dart';
import 'package:photo_app/utils/geometric_background.dart';
import 'package:photo_app/widgets/picon_ui.dart';

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

  void _submitBooking() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation envoyée! Nous vous contacterons bientôt.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
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

import 'package:Picon/api_service.dart';
import 'package:Picon/models/booking.dart';
import 'package:Picon/utils/app_error.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/widgets/app_error_feedback.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:Picon/utils/colors.dart';
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
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) await showAppError(context, e);
    }
  }

  static const Map<String, IconData> _serviceIcons = {
    'Shooting Photo Basique': Icons.photo_camera_rounded,
    'Forfait Événementiel': Icons.celebration_rounded,
    'Forfait Mariage': Icons.favorite_rounded,
    "Photos d'identité": Icons.badge_rounded,
    'Tirage Photos': Icons.print_rounded,
  };

  @override
  void dispose() {
    _commentsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Widget _serviceTile(String service) {
    final selected = _selectedService == service;
    return TapScale(
      onTap: () => setState(() => _selectedService = service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? 1.6 : 1),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(_serviceIcons[service] ?? Icons.photo_camera_rounded,
                color: selected ? Colors.white : AppColors.primary, size: 22),
            const Spacer(),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
            ),
          ]),
          const SizedBox(height: 10),
          Text(service,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: selected ? Colors.white : AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _pickTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: piconField(label, icon: icon, hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PiconHeroScaffold(
      title: 'Réserver une séance',
      subtitle: 'Choisissez un service, une date et une heure.',
      icon: Icons.event_available_rounded,
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Reveal(
            child: PiconCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const PiconSectionHeader(icon: Icons.camera_rounded, title: 'Type de service'),
                LayoutBuilder(builder: (context, c) {
                  final w = (c.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _services.map((sv) => SizedBox(width: w, child: _serviceTile(sv))).toList(),
                  );
                }),
                FormField<String>(
                  validator: (_) => _selectedService == null ? 'Veuillez choisir un service' : null,
                  builder: (state) => state.hasError
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(state.errorText!, style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 1,
            child: PiconCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const PiconSectionHeader(icon: Icons.schedule_rounded, title: 'Date et heure'),
                _pickTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date de la séance',
                  controller: _dateController,
                  hint: 'Sélectionnez une date',
                  onTap: _selectDate,
                  validator: (value) => _selectedDate == null ? 'Veuillez choisir une date' : null,
                ),
                const SizedBox(height: 12),
                _pickTile(
                  icon: Icons.access_time_rounded,
                  label: 'Heure de la séance',
                  controller: _timeController,
                  hint: 'Sélectionnez une heure',
                  onTap: _selectTime,
                  validator: (value) => _selectedTime == null ? 'Veuillez choisir une heure' : null,
                ),
                const SizedBox(height: 8),
                const Text('Durée prévue : 1 heure. Le studio confirme votre créneau.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            index: 2,
            child: PiconCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const PiconSectionHeader(icon: Icons.notes_rounded, title: 'Commentaires'),
                TextFormField(
                  controller: _commentsController,
                  decoration: piconField('Commentaires additionnels (facultatif)'),
                  maxLines: 4,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          PiconButton(
            label: 'Confirmer la réservation',
            icon: Icons.check_circle_outline_rounded,
            onPressed: _submitBooking,
          ),
        ]),
      ),
    );
  }

  // Ancienne mise en page (v2), conservée.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
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

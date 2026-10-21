import 'dart:ui';

import 'package:Picon/api_service.dart';
import 'package:Picon/payment_selection_screen.dart';
import 'package:Picon/services/sim_info_service.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/utils/geometric_background.dart';
import 'package:Picon/utils/mobile_operator_utils.dart';
import 'package:Picon/widgets/picon_premium.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class PaymentCustomerInfoScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> orderDetails;
  final double totalAmount;
  final bool isExpress;

  const PaymentCustomerInfoScreen({
    super.key,
    required this.orderDetails,
    required this.totalAmount,
    required this.isExpress,
  });

  @override
  State<PaymentCustomerInfoScreen> createState() =>
      _PaymentCustomerInfoScreenState();
}

class _PaymentCustomerInfoScreenState extends State<PaymentCustomerInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _address;
  String _country = 'TG';
  List<SimCardInfo> _detectedSims = [];

  @override
  void initState() {
    super.initState();
    final fullName = (ApiService.userName ?? '').trim();
    final parts = fullName.split(' ');
    _firstName =
        TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _lastName = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');
    _email = TextEditingController(text: ApiService.userEmail ?? '');
    _phone = TextEditingController(text: '');
    _address = TextEditingController(text: '');
    _prefillPaymentPhone();
  }

  Future<void> _prefillPaymentPhone() async {
    final suggested = await SimInfoService.suggestLocalPhone(country: _country);
    final sims = await SimInfoService.getSimCards();
    if (!mounted) return;
    setState(() {
      _detectedSims = sims;
      if (suggested != null && _phone.text.trim().isEmpty) {
        _phone.text = suggested;
      }
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionScreen(
          orderDetails: widget.orderDetails,
          totalAmount: widget.totalAmount,
          isExpress: widget.isExpress,
          customerFirstname: _firstName.text.trim(),
          customerLastname: _lastName.text.trim(),
          customerEmail: _email.text.trim(),
          customerPhone: _normalizePhone(_phone.text),
          customerCountry: _country,
          deliveryAddress: _address.text.trim(),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Iterable<String>? autofill,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          autofillHints: autofill,
          decoration: piconField(label, icon: icon, hint: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final photos = widget.orderDetails.length;
    final op = _phone.text.isNotEmpty
        ? MobileOperatorUtils.operatorLabel(MobileOperatorUtils.detectOperator(_phone.text, country: _country))
        : null;
    return PiconHeroScaffold(
      title: 'Vos informations',
      subtitle: 'Vérifiez vos coordonnées avant le paiement.',
      icon: Icons.person_pin_circle_rounded,
      step: 1,
      bottomBar: PiconPayBar(
        amountLabel: '$photos photo${photos > 1 ? 's' : ''}${widget.isExpress ? ' • Xpress' : ''}',
        amount: '${widget.totalAmount.toStringAsFixed(0)} FCFA',
        action: SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _continue,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Reveal(
              child: PiconCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const PiconSectionHeader(icon: Icons.badge_rounded, title: 'Identité'),
                  _field(
                    label: 'Prénom',
                    icon: Icons.person_rounded,
                    controller: _firstName,
                    textInputAction: TextInputAction.next,
                    autofill: const [AutofillHints.givenName],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  _field(
                    label: 'Nom (optionnel)',
                    icon: Icons.person_outline_rounded,
                    controller: _lastName,
                    textInputAction: TextInputAction.next,
                    autofill: const [AutofillHints.familyName],
                  ),
                  _field(
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofill: const [AutofillHints.email],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Reveal(
              index: 1,
              child: PiconCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  PiconSectionHeader(
                    icon: Icons.local_shipping_rounded,
                    title: 'Livraison',
                    trailing: widget.isExpress
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Xpress',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                          )
                        : null,
                  ),
                  _field(
                    label: 'Adresse de livraison complète',
                    icon: Icons.home_rounded,
                    controller: _address,
                    textInputAction: TextInputAction.next,
                    hint: 'Quartier, Rue, Maison...',
                    autofill: const [AutofillHints.fullStreetAddress],
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Reveal(
              index: 2,
              child: PiconCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  PiconSectionHeader(
                    icon: Icons.phone_iphone_rounded,
                    title: 'Mobile Money',
                    trailing: op == null
                        ? null
                        : Text(op, style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumberNational],
                      validator: (v) => _validatePhone(v, _country),
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                      decoration: piconField('Téléphone (Mobile Money)', hint: 'Détecté automatiquement — modifiable')
                          .copyWith(
                        prefixIcon: CountryCodePicker(
                          onChanged: (countryCode) => setState(() => _country = countryCode.code ?? 'TG'),
                          initialSelection: 'TG',
                          favorite: const ['+228', '+229', '+225', '+227', '+221'],
                          countryFilter: const ['BJ', 'TG', 'CI', 'NE', 'SN'],
                          textStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  if (_detectedSims.isNotEmpty) ...[
                    const Text('Lignes sur cet appareil',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _detectedSims.map((sim) {
                        final selected = _phone.text.trim() == sim.localDigits;
                        return ChoiceChip(
                          label: Text(sim.label),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
                          onSelected: (_) => setState(() => _phone.text = sim.localDigits),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_phoneHintByCountry(_country),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Flexible(
                child: Text('Vos données servent uniquement à cette commande.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // Ancienne mise en page (v2), conservée.
  // ignore: unused_element
  Widget _legacyBuild(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infos du client'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: GeometricBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Vérifiez vos informations avant le paiement.',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Carte résumé montant ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryDark, AppColors.primary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total à payer',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    '${widget.orderDetails.length} photo${widget.orderDetails.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${widget.totalAmount.toStringAsFixed(0)} FCFA',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildField(
                          label: 'Prénom',
                          controller: _firstName,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requis' : null,
                        ),
                        _buildField(
                          label: 'Nom (optionnel)',
                          controller: _lastName,
                          textInputAction: TextInputAction.next,
                        ),
                        _buildField(
                          label: 'Email',
                          controller: _email,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requis' : null,
                        ),
                        _buildField(
                          label: 'Adresse de livraison complète',
                          controller: _address,
                          textInputAction: TextInputAction.next,
                          hint: 'Quartier, Rue, Maison...',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Requis' : null,
                        ),
                        _buildField(
                          label: 'Téléphone (Mobile Money)',
                          controller: _phone,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.phone,
                          hint: 'Détecté automatiquement — modifiable',
                          prefix: CountryCodePicker(
                            onChanged: (countryCode) {
                              setState(() {
                                _country = countryCode.code ?? 'TG';
                              });
                            },
                            initialSelection: 'TG',
                            favorite: const [
                              '+228',
                              '+229',
                              '+225',
                              '+227',
                              '+221'
                            ],
                            countryFilter: const ['BJ', 'TG', 'CI', 'NE', 'SN'],
                            textStyle: TextStyle(
                                color: AppColors.textPrimary.withOpacity(0.9)),
                          ),
                          validator: (v) => _validatePhone(v, _country),
                        ),
                        if (_detectedSims.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Lignes sur cet appareil (appuyez pour choisir)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary.withOpacity(0.85),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _detectedSims.map((sim) {
                                final selected =
                                    _phone.text.trim() == sim.localDigits;
                                return ActionChip(
                                  label: Text(
                                    sim.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  backgroundColor: selected
                                      ? AppColors.primary.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.35),
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.grey.withOpacity(0.4),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _phone.text = sim.localDigits;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ] else if (_phone.text.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Opérateur : ${MobileOperatorUtils.operatorLabel(MobileOperatorUtils.detectOperator(_phone.text, country: _country))}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _phoneHintByCountry(_country),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _continue,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                'Continuer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Widget? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        decoration: _glassyInputDecoration(
          label,
          hint: hint,
          prefix: prefix,
        ),
      ),
    );
  }

  String _normalizePhone(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String? _validatePhone(String? input, String country) {
    if (input == null || input.trim().isEmpty) return 'Requis';
    final digits = _normalizePhone(input);
    if (country == 'BJ' || country == 'TG' || country == 'NE') {
      if (digits.length != 8) return 'Numéro: 8 chiffres';
      return null;
    }
    if (country == 'CI') {
      if (digits.length != 10) return 'Numéro: 10 chiffres';
      return null;
    }
    if (country == 'SN') {
      if (digits.length != 9) return 'Numéro: 9 chiffres';
      return null;
    }
    return null;
  }

  String _phoneHintByCountry(String country) {
    switch (country) {
      case 'BJ':
        return 'Bénin: 8 chiffres (ex: 9XXXXXXX ou 6XXXXXXX)';
      case 'TG':
        return 'Togo : 8 chiffres — Yas 90–93 ou 70–73 · Moov 96–99 ou 78–79';
      case 'CI':
        return 'Côte d’Ivoire: 10 chiffres (ex: 01XXXXXXXX, 05XXXXXXXX, 07XXXXXXXX)';
      case 'NE':
        return 'Niger: 8 chiffres (ex: 9XXXXXXX)';
      case 'SN':
        return 'Sénégal: 9 chiffres (ex: 7XXXXXXXX)';
      default:
        return '';
    }
  }

  InputDecoration _glassyInputDecoration(String label,
      {String? hint, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.3),
      labelStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}

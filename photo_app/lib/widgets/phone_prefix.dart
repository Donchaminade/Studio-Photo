import 'package:Picon/utils/africa_countries.dart';
import 'package:Picon/utils/colors.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

class AfricanPhonePrefix extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String initialSelection;

  const AfricanPhonePrefix({
    super.key,
    this.onChanged,
    this.initialSelection = 'TG',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: CountryCodePicker(
        onChanged: (code) {
          final dial = code.dialCode;
          if (dial != null && dial.isNotEmpty) {
            onChanged?.call(dial);
          }
        },
        initialSelection: initialSelection,
        favorite: kFavoriteDialCodes,
        countryFilter: kAfricanIsoCodes,
        padding: EdgeInsets.zero,
        flagWidth: 22,
        textStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        dialogTextStyle: const TextStyle(color: AppColors.textPrimary),
        searchStyle: const TextStyle(color: AppColors.textPrimary),
        dialogBackgroundColor: Colors.white,
      ),
    );
  }
}

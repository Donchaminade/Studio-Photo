import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:photo_app/utils/africa_countries.dart';
import 'package:photo_app/utils/colors.dart';

class AfricanPhonePrefix extends StatelessWidget {
  const AfricanPhonePrefix({super.key});

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
        onChanged: (_) {},
        initialSelection: 'TG',
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

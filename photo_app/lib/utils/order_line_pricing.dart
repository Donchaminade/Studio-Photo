/// Calcul du prix d'une ligne commande (tirage + cadre optionnel).
class OrderLinePricing {
  OrderLinePricing._();

  static bool offersFrame(double? framePrice) =>
      framePrice != null && framePrice > 0;

  static double unitTotal({
    required double printPrice,
    required double? framePrice,
    required bool withFrame,
  }) {
    final frame = withFrame && offersFrame(framePrice) ? framePrice! : 0.0;
    return printPrice + frame;
  }

  static double lineTotal(
    Map<String, dynamic> details,
    Map<String, double> printPrices,
    Map<String, double?> framePrices,
  ) {
    final size = details['size'] as String? ?? '';
    final qty = details['quantity'] as int? ?? 1;
    final withFrame = details['withFrame'] == true;
    return unitTotal(
          printPrice: printPrices[size] ?? 0,
          framePrice: framePrices[size],
          withFrame: withFrame,
        ) *
        qty;
  }
}

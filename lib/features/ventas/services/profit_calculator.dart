import '../domain/profit_distribution.dart';

class ProfitCalculator {
  const ProfitCalculator();

  ProfitDistribution calculate({
    required int revenueCents,
    required int costCents,
  }) {
    if (revenueCents < 0 || costCents < 0) {
      throw ArgumentError('Los importes no pueden ser negativos.');
    }

    final profit = revenueCents - costCents;

    // Las p\u00e9rdidas no generan utilidades distribuibles.
    if (profit <= 0) {
      return ProfitDistribution(
        revenueCents: revenueCents,
        costCents: costCents,
        profitCents: profit,
        reinvestmentCents: 0,
        distributableCents: 0,
        joelCents: 0,
        paulCents: 0,
      );
    }

    // El centavo impar se conserva en Izumi.
    final distributable = profit ~/ 2;
    final reinvestment = profit - distributable;

    // Redondeo a centavos: Paul recibe el 35%.
    final paul = (distributable * 35) ~/ 100;
    final joel = distributable - paul;

    return ProfitDistribution(
      revenueCents: revenueCents,
      costCents: costCents,
      profitCents: profit,
      reinvestmentCents: reinvestment,
      distributableCents: distributable,
      joelCents: joel,
      paulCents: paul,
    );
  }
}

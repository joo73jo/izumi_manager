import 'package:flutter_test/flutter_test.dart';
import 'package:izumi_manager/features/ventas/services/profit_calculator.dart';

void main() {
  const calculator = ProfitCalculator();

  test('Distribuye correctamente una ganancia de 12 USD', () {
    final result = calculator.calculate(revenueCents: 2000, costCents: 800);

    expect(result.profitCents, 1200);
    expect(result.reinvestmentCents, 600);
    expect(result.distributableCents, 600);
    expect(result.joelCents, 390);
    expect(result.paulCents, 210);
  });

  test('No distribuye ganancias cuando existe perdida', () {
    final result = calculator.calculate(revenueCents: 500, costCents: 800);

    expect(result.profitCents, -300);
    expect(result.reinvestmentCents, 0);
    expect(result.distributableCents, 0);
    expect(result.joelCents, 0);
    expect(result.paulCents, 0);
  });

  test('Conserva todos los centavos', () {
    final result = calculator.calculate(revenueCents: 1001, costCents: 0);

    expect(
      result.reinvestmentCents + result.distributableCents,
      result.profitCents,
    );

    expect(result.joelCents + result.paulCents, result.distributableCents);
  });
}

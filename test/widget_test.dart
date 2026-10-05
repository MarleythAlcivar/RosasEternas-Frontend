import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rosas_eternas/shop_app.dart';
import 'package:rosas_eternas/shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('una sesión válida abre las vistas protegidas', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = ShopState();
    await state.initialize();
    await state.register('Ana Flores', 'ana@ejemplo.ec', 'Clave2026');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const ShopApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Arreglos destacados'), findsOneWidget);
  });

  testWidgets('el formulario muestra una validación comprensible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = ShopState();
    await state.initialize();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: state, child: const ShopApp()),
    );

    await tester.enterText(find.byType(TextFormField).first, 'correo-invalido');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    expect(find.text('Ingresa un correo con formato válido.'), findsOneWidget);
  });
}

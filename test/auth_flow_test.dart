import 'package:flutter_test/flutter_test.dart';
import 'package:rosas_eternas/shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rechaza credenciales incorrectas y permite una cuenta registrada', () async {
    final state = ShopState();
    await state.initialize();

    await state.register('Ana Flores', 'ana@ejemplo.ec', 'Clave2026');
    await state.logout();

    expect(
      await state.login('ana@ejemplo.ec', 'incorrecta'),
      'Correo o contraseña incorrectos.',
    );
    expect(state.authenticated, isFalse);

    expect(await state.login('ana@ejemplo.ec', 'Clave2026'), isNull);
    expect(state.authenticated, isTrue);
    expect(state.userName, 'Ana Flores');
    expect(state.role, 'cliente');
  });

  test(
    'registra un usuario, conserva su sesión y bloquea duplicados',
    () async {
      final state = ShopState();
      await state.initialize();

      expect(
        await state.register('Ana Flores', 'ana@ejemplo.ec', 'Clave2026'),
        isNull,
      );
      expect(state.authenticated, isTrue);
      expect(state.userName, 'Ana Flores');
      await state.logout();
      expect(state.authenticated, isFalse);
      expect(await state.login('ana@ejemplo.ec', 'Clave2026'), isNull);
      expect(
        await state.register('Otra Ana', 'ana@ejemplo.ec', 'Otra2026'),
        'Ya existe una cuenta con este correo.',
      );
    },
  );
}

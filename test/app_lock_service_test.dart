import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/services/app_lock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppLockService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = AppLockService(prefsProvider: SharedPreferences.getInstance);
  });

  group('AppLockService', () {
    test('sin PIN configurado, el bloqueo esta deshabilitado', () async {
      expect(await service.isEnabled(), isFalse);
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('setPin habilita el bloqueo y verifyPin acepta el PIN correcto', () async {
      await service.setPin('1234');
      expect(await service.isEnabled(), isTrue);
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('0000'), isFalse);
    });

    test('el PIN no se guarda en claro', () async {
      await service.setPin('1234');
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        expect(prefs.getString(key), isNot(contains('1234')));
      }
    });

    test('disable elimina el PIN', () async {
      await service.setPin('1234');
      await service.disable();
      expect(await service.isEnabled(), isFalse);
      expect(await service.verifyPin('1234'), isFalse);
    });

    test('isValidPinFormat exige 4 digitos numericos', () {
      expect(AppLockService.isValidPinFormat('1234'), isTrue);
      expect(AppLockService.isValidPinFormat('123'), isFalse);
      expect(AppLockService.isValidPinFormat('12345'), isFalse);
      expect(AppLockService.isValidPinFormat('12a4'), isFalse);
    });
  });
}

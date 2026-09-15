import 'package:flutter_test/flutter_test.dart';
import 'package:khatha/core/blocs/auth/auth_cubit.dart';
import 'package:khatha/data/models/user_model.dart';
import 'package:khatha/core/utils/money.dart';

void main() {
  group('Auth State Architecture', () {
    test('Authenticated state exists and holds user regardless of KYC', () {
      const userWithKyc = UserModel(
        id: '1', phone: '1234567890', isEmailVerified: true, 
        firstName: 'Test', lastName: 'User', backendKycComplete: true
      );
      const userNoKyc = UserModel(
        id: '2', phone: '0987654321', isEmailVerified: true, 
        firstName: '', lastName: '', backendKycComplete: false
      );

      final state1 = Authenticated(user: userWithKyc);
      final state2 = Authenticated(user: userNoKyc);

      expect(state1.user, userWithKyc);
      expect(state2.user, userNoKyc);
      expect(state1.runtimeType, state2.runtimeType);
    });
  });

  group('MoneyUtils Contract', () {
    test('parseRupeesToPaise strictly validates and converts', () {
      expect(MoneyUtils.parseRupeesToPaise('100'), 10000);
      expect(MoneyUtils.parseRupeesToPaise('100.50'), 10050);
      expect(MoneyUtils.parseRupeesToPaise('100.5'), 10050);
      
      expect(() => MoneyUtils.parseRupeesToPaise('100.505'), throwsFormatException);
      expect(() => MoneyUtils.parseRupeesToPaise(''), throwsFormatException);
      expect(() => MoneyUtils.parseRupeesToPaise('abc'), throwsFormatException);
    });
  });
}

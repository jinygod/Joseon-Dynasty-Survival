import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/economy/supabase_economy_repository.dart';

void main() {
  test('verification accepts only explicit accepted and boolean duplicate', () {
    expect(
      PurchaseVerificationResult.parse({'accepted': true, 'duplicate': false}),
      const PurchaseVerificationResult(accepted: true, duplicate: false),
    );
    expect(
      PurchaseVerificationResult.parse({'accepted': true, 'duplicate': true}),
      const PurchaseVerificationResult(accepted: true, duplicate: true),
    );
    for (final malformed in <Object?>[
      null,
      {},
      {'accepted': false, 'duplicate': false},
      {'accepted': true},
      {'accepted': true, 'duplicate': 'false'},
      {'accepted': true, 'duplicate': false, 'wallet': {}},
    ]) {
      expect(
        () => PurchaseVerificationResult.parse(malformed),
        throwsA(isA<PurchaseRejectedException>()),
      );
    }
  });

  test('wallet parser rejects fractional and negative numeric values', () {
    expect(
      SupabaseEconomyRepository.parseWallet({
        'royal_jade': 10,
        'royal_jade_debt': 0,
        'version': 2,
      }).balance,
      10,
    );
    for (final row in [
      {'royal_jade': 1.5, 'royal_jade_debt': 0, 'version': 1},
      {'royal_jade': 1, 'royal_jade_debt': -1, 'version': 1},
      {'royal_jade': 1, 'royal_jade_debt': 0, 'version': 1.2},
    ]) {
      expect(
        () => SupabaseEconomyRepository.parseWallet(row),
        throwsA(anyOf(isA<FormatException>(), isA<ArgumentError>())),
      );
    }
  });
}

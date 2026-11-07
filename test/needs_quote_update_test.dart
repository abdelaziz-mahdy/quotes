import 'package:flutter_test/flutter_test.dart';
import 'package:quotes/engine.dart';

void main() {
  test('updates when the server has more quotes than ever synced', () {
    expect(needsQuoteUpdate(100, 120, null), isTrue);
    expect(needsQuoteUpdate(100, 120, 110), isTrue);
  });

  test('skips when that server count was already fully synced', () {
    // Server duplicates: 120 rows on the server dedupe to 118 locally.
    expect(needsQuoteUpdate(118, 120, 120), isFalse);
  });

  test('skips when the device is up to date', () {
    expect(needsQuoteUpdate(120, 120, null), isFalse);
    expect(needsQuoteUpdate(130, 120, null), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:quotes/engine.dart';

void main() {
  test('parses backend rows into unfavorited quotes', () {
    final quotes = quotesFromJson(
      '[{"author": "Socrates", "quote": "Know thyself.", "topic": "Wisdom"},'
      ' {"author": "Seneca", "quote": "Luck is preparation.", "topic": "Luck"}]',
    );

    expect(quotes, hasLength(2));
    expect(quotes.first.quote, 'Know thyself.');
    expect(quotes.first.author, 'Socrates');
    expect(quotes.first.topic, 'Wisdom');
    expect(quotes.every((q) => q.favorite == 0 && q.selected == 0), isTrue);
  });

  test('returns an empty list for an empty array', () {
    expect(quotesFromJson('[]'), isEmpty);
  });
}

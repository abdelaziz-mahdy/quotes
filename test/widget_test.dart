import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quotes/engine.dart';
import 'package:quotes/main.dart';
import 'package:quotes/models/quote.dart';

import 'fake_processor.dart';

void main() {
  testWidgets('home lists topics and opens a topic', (tester) async {
    final processor = FakeProcessor(
      topics: ['Wisdom'],
      quotes: [Quote('Know thyself.', 'Socrates', 'Wisdom', 0)],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<Processor>.value(
        value: processor,
        child: const MaterialApp(home: MyHomePage(title: 'Quotes Topics')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quotes Topics'), findsOneWidget);
    expect(find.text('Wisdom'), findsOneWidget);

    await tester.tap(find.text('Wisdom'));
    await tester.pumpAndSettle();

    expect(find.text('Wisdom Quotes'), findsOneWidget);
    expect(find.text('Know thyself.'), findsOneWidget);
    expect(find.text('Socrates'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quotes/engine.dart';
import 'package:quotes/models/quote.dart';
import 'package:quotes/screens/photos_view.dart';

import 'fake_processor.dart';

Future<void> openWisdom(WidgetTester tester) async {
  final processor = FakeProcessor(
    quotes: [
      Quote('Know thyself.', 'Socrates', 'Wisdom', 0),
      Quote('Less is more.', 'Mies', 'Wisdom', 0),
    ],
  );
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ChangeNotifierProvider<Processor>.value(
      value: processor,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('home')),
      ),
    ),
  );
  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => const PhotosList('Wisdom')),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('close button clears the selection', (tester) async {
    await openWisdom(tester);
    await tester.longPress(find.text('Know thyself.'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: 1'), findsNothing);
    expect(find.text('Wisdom Quotes'), findsOneWidget);

    // Selection mode is really off: a plain tap no longer selects.
    await tester.tap(find.text('Less is more.'));
    await tester.pumpAndSettle();
    expect(find.text('Wisdom Quotes'), findsOneWidget);
  });

  testWidgets('back clears the selection before leaving', (tester) async {
    await openWisdom(tester);
    await tester.longPress(find.text('Know thyself.'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: 1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Wisdom Quotes'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('one Back leaves after a reload dropped the selection',
      (tester) async {
    await openWisdom(tester);
    await tester.longPress(find.text('Know thyself.'));
    await tester.pumpAndSettle();
    expect(find.text('Selected: 1'), findsOneWidget);

    (Provider.of<Processor>(tester.element(find.byType(PhotosList)),
            listen: false) as FakeProcessor)
        .reloadFromDb();
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quotes/engine.dart';
import 'package:quotes/models/quote.dart';
import 'package:quotes/screens/photos_view.dart';

import 'fake_processor.dart';

void main() {
  testWidgets('a long author name wraps and keeps the favorite button', (
    tester,
  ) async {
    // Pixel 9 logical size; the longest author in the backend is 41 chars.
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final processor = FakeProcessor(
      quotes: [
        Quote(
          'Good humor is the health of the soul, sadness is its poison.',
          'Philip Stanhope, 4th Earl of Chesterfield',
          'Humor',
          1,
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<Processor>.value(
        value: processor,
        child: const MaterialApp(home: PhotosList('Favorite')),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final heart = find.byIcon(Icons.favorite);
    expect(heart, findsOneWidget);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(tester.getRect(heart).right, lessThanOrEqualTo(screen.width));
  });
}

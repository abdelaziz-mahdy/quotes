import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotes/snack_bars.dart';

void main() {
  testWidgets('download snackbar shows message, bar and percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(downloading(50, 1)),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Updating quotes'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.5);
    expect(tester.takeException(), isNull);
  });
}

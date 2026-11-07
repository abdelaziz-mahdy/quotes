import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotes/engine.dart';

void main() {
  test('first load returns every topic', () {
    final order = stableTopicOrder([], ['A', 'B', 'C'], Random(1));
    expect(order.toSet(), {'A', 'B', 'C'});
    expect(order, hasLength(3));
  });

  test('refresh keeps on-screen order and appends new topics', () {
    final order = stableTopicOrder(
      ['C', 'A', 'B'],
      ['A', 'B', 'C', 'D', 'E'],
      Random(1),
    );
    expect(order.take(3), ['C', 'A', 'B']);
    expect(order.skip(3).toSet(), {'D', 'E'});
  });

  test('topics gone from the database are dropped', () {
    expect(stableTopicOrder(['C', 'A', 'B'], ['A', 'C']), ['C', 'A']);
  });
}

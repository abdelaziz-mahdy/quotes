import 'package:quotes/engine.dart';
import 'package:quotes/models/quote.dart';

/// A [Processor] that never touches the network or SQLite, so screens can be
/// pumped in widget tests with known data.
class FakeProcessor extends Processor {
  FakeProcessor({List<String>? topics, List<Quote>? quotes})
      : _topics = topics ?? const [],
        _quotes = quotes ?? const [];

  final List<String> _topics;
  final List<Quote> _quotes;

  /// The real methods always await the database before notifying; yield once
  /// so listeners are never notified synchronously from a widget's initState.
  Future<void> _yield() => Future<void>.delayed(Duration.zero);

  @override
  Future<void> checkNewDatabaseVersion() async {}

  @override
  Future<void> rowsCount() async {
    dbRowCount = _quotes.length + 1;
  }

  @override
  Future<void> serverQuotesCount() async {
    serverCount = dbRowCount;
  }

  @override
  Future<void> getLocalDBTopics() async {
    await _yield();
    topics = List.of(_topics);
    notifyListeners();
  }

  @override
  Future<void> getLocalDBQuotes(String topic) async {
    await _yield();
    dbQuotes = _quotes.where((q) => q.topic == topic).toList();
    notifyListeners();
  }

  @override
  Future<void> getFavorites() async {
    await _yield();
    dbQuotes = _quotes.where((q) => q.favorite == 1).toList();
    notifyListeners();
  }

  @override
  Future<void> updateDB(List<Quote> list) async {}

  /// Like the real SQLite reads: replaces [dbQuotes] with fresh, unselected
  /// Quote objects for the same rows.
  void reloadFromDb() {
    dbQuotes = [
      for (final q in dbQuotes) Quote(q.quote, q.author, q.topic, q.favorite),
    ];
    notifyListeners();
  }
}

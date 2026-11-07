import 'package:flutter_test/flutter_test.dart';
import 'package:quotes/engine.dart';
import 'package:quotes/models/quote.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Processor processor;
  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        // Same schema as Processor.createDB.
        onCreate: (db, _) => db.execute(
          'CREATE TABLE quotes(quote TEXT,author TEXT,topic TEXT,'
          'favorite INTEGER,PRIMARY KEY (quote,author,topic))',
        ),
      ),
    );
    processor = Processor()..database = Future.value(db);
  });

  tearDown(() => db.close());

  test('a download never resets a favorite or duplicates its row', () async {
    await db.insert(
      'quotes',
      Quote('Know thyself.', 'Socrates', 'Wisdom', 1).toMap(),
    );

    // The server always sends favorite = 0.
    await processor.insertNewQuotes([
      Quote('Know thyself.', 'Socrates', 'Wisdom', 0),
      Quote('Less is more.', 'Mies', 'Wisdom', 0),
    ]);

    final rows = await db.query('quotes', orderBy: 'quote');
    expect(rows, hasLength(2));
    expect(rows.first['quote'], 'Know thyself.');
    expect(rows.first['favorite'], 1);
    expect(rows.last['favorite'], 0);
  });
}

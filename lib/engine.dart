import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart';
import 'package:quotes/models/quote.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'snack_bars.dart';

class Processor extends ChangeNotifier {
  // String url = "http://127.0.0.1:5000";
  String url = "https://my-qoutes-app-123456.nw.r.appspot.com";

  var jsonResponse = [];
  List<String> topics = [];
  List<Quote> responses = [];
  List<Quote> dbQuotes = [];
  List<Quote> oldDbQuotes = [];
  int testCount = 0;
  int dbRowCount = 0;
  int serverCount = 0;
  int dbVersion = 2;
  List<int> state = [0, 25, 50, 75, 100];
  void jsonToEncoded(var response) {
    for (int i = 0; i < response.length; i++) {
      Quote note = Quote(
          response[i]['quote'], response[i]['author'], response[i]['topic'], 0);
      responses.add(note);
    }
  }

  void jsonToEncodedTopics(var response) {
    for (int i = 0; i < response.length; i++) {
      topics.add(response[i]['topic']);
    }
    print(topics);
  }

  void jsonToCount(var response) {
    print(response);
    serverCount = int.parse(response);
  }

  int numSelected(List<Quote> list) {
    int selected = 0;
    for (int i = 0; i < list.length; i++) {
      if (list[i].selected == 1) {
        selected++;
      }
    }
    return selected;
  }

  bool selectedExist(List<Quote> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].selected == 1) {
        print(true);
        return true;
      }
    }
    print(false);
    return false;
  }

  void selected(List<Quote> list, int index) {
    list[index].toggleSelected();
    notifyListeners();
  }

  void clearSelection(List<Quote> list) {
    for (final quote in list) {
      quote.selected = 0;
    }
    notifyListeners();
  }

  void toggleFavoriteUpdateDb(List<Quote> list, int index) {
    list[index].toggleFavorite();
    updateDB(dbQuotes);
    notifyListeners();
  }

  void shareSelected(List<Quote> list) {
    List<Quote> toShare = [];
    for (var element in list) {
      if (element.selected == 1) {
        element.selected = 0;
        toShare.add(element);
      }
    }
    String stringToShare = "";
    for (var element in toShare) {
      stringToShare = "${'''${'''${stringToShare}Quote: ${element.quote}'''}\n
Author: ${element.author}'''}\n\n";
    }
    SharePlus.instance.share(ShareParams(text: stringToShare));
    notifyListeners();
  }

  Uri getUrlForRoute(String route) {
    return Uri.parse(url + route);
  }

  /// Downloads [route] and parses it into quotes. Kept in a local list on
  /// purpose: the screens read [dbQuotes], and the background download must
  /// never replace or clear the list a screen is showing. Throws on a non-200
  /// response so the home screen's onStart shows its Retry snackbar.
  Future<List<Quote>> _fetchQuotes(String route) async {
    final uri = getUrlForRoute(route);
    final http.Response response = await http.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
          "Request failed with status: ${response.statusCode}.", uri);
    }
    // The full response is ~8.8 MB / 44k quotes: parse it on a background
    // isolate so the progress snackbar keeps animating.
    return compute(quotesFromJson, response.body);
  }

  /// Adds server quotes the device doesn't have yet. Every column except
  /// `favorite` is part of the primary key, so ignoring conflicts keeps the
  /// user's favorites exactly as they are, including ones toggled while the
  /// download was running.
  @visibleForTesting
  Future<void> insertNewQuotes(List<Quote> quotes) async {
    final Database db = await database;
    final batch = db.batch();
    for (final quote in quotes) {
      batch.insert(tableName, quote.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  // Server count at the last completed full download, kept next to the DB.
  // Rows are inserted with ConflictAlgorithm.ignore, so duplicate rows on the
  // server keep the local count below the server's forever; without this the
  // full download would rerun on every launch.
  Future<File> _syncMarker() async =>
      File(join(await getDatabasesPath(), 'last_synced_server_count'));

  Future<int?> lastSyncedServerCount() async {
    try {
      final file = await _syncMarker();
      if (!await file.exists()) return null;
      return int.tryParse((await file.readAsString()).trim());
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _recordSyncedServerCount(int count) async {
    await (await _syncMarker()).writeAsString('$count');
  }

  Future<void> checkNewDatabaseVersion() async {
    int oldversion = 999;
    bool exists;
    exists = await checkIfDatabaseExists();
    try {
      if (exists) {
        await initDB();
        final Database db = await database;
        print(oldversion);
        oldversion = await db.getVersion();
        print(oldversion);
      }
    } catch (_) {}
    if (oldversion < dbVersion && oldversion != 0) {
      print("Reading old Database");
      await readDB();
      print("deleting old Database");
      await deleteDataBase();
      print("creating new Database");
      await createDB();
      print("updating new Database");
      await updateDB(dbQuotes);
    } else {
      print("Database is at last version");
    }
  }

  Future<void> deleteDataBase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, databaseName);
    var db = await openDatabase(path);
    db.close();
    //delete the old database so you can copy the new one
    await deleteDatabase(path);
  }

  Future<void> getQuotesDb() async {
    http.Response response = await http.get(getUrlForRoute("/see_db"));

    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      jsonToEncoded(jsonResponse);
      //      jsonResponse[0]["author"]; = author name
      //      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    print("all items got retrieved");
    dbQuotes = responses;
    notifyListeners();
  }

  //try to retrieve all and do the proccesing in the mobile phone
  //save the qoutes it got from server to DB
  Future<void> saveQuotesResponse() async {
    // Get a reference to the database.
    final Database db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    testCount = 0;
    print("\n\n\n\n\n\n\ninserting to Qoutes DB");
    responses.forEach((element) async {
      testCount++;
      print(testCount);
      await db.insert(
        tableName,
        element.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    notifyListeners();
  }

  Future<void> getTopicQuotes(String topic) async {
    http.Response response =
        await http.get(getUrlForRoute("/GetQuotesByTopicFromDB/?topic=$topic"));

    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      jsonToEncoded(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    notifyListeners();
  }

  void clearOld() {
    responses.clear();
    dbQuotes.clear();
    jsonResponse.clear();
  }

  Future<void> getTopics() async {
    if (jsonResponse.isEmpty) {
      http.Response response = await http.get(getUrlForRoute("/getdbtopics"));

      if (response.statusCode == 200) {
        jsonResponse = convert.jsonDecode(response.body);

        jsonResponse.shuffle();
        jsonToEncodedTopics(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
      } else {
        print("Request failed with status: ${response.statusCode}.");
      }
    }
    notifyListeners();
  }

  Future<void> downloadAndInsertToDb(
      GlobalKey<ScaffoldState> scaffold, int snackText) async {
    //snack text =0 text ==downloading(first time)
    //snack text =1 text ==updating
    await createDB();
    ScaffoldMessenger.of(scaffold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scaffold.currentContext!)
        .showSnackBar(downloading(null, snackText));
    final quotes = await _fetchQuotes("/see_saved_online");
    ScaffoldMessenger.of(scaffold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scaffold.currentContext!)
        .showSnackBar(downloading(state[2], snackText));
    await insertNewQuotes(quotes);
    await _recordSyncedServerCount(
        serverCount > 0 ? serverCount : quotes.length);
    ScaffoldMessenger.of(scaffold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scaffold.currentContext!)
        .showSnackBar(downloading(state[4], snackText));
    await getLocalDBTopics();
    ScaffoldMessenger.of(scaffold.currentContext!).removeCurrentSnackBar();
  }

  Future<void> downloadPreviewAndInsertToDb(
      GlobalKey<ScaffoldState> scafold) async {
    await createDB();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!)
        .showSnackBar(downloading(null, 2));
    final quotes = await _fetchQuotes("/see_saved_online_preview");
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!)
        .showSnackBar(downloading(state[3], 2));
    await insertNewQuotes(quotes);
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!)
        .showSnackBar(downloading(state[4], 2));
    await getLocalDBTopics();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
  }

  //database values
  String databaseName = "quotes_database.db";
  String tableName = "quotes";
  late Future<Database> database;
  //create the DB+Get refrence for it

  Future<void> createDB() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), databaseName),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.

        return db.execute(
          "CREATE TABLE quotes(quote TEXT,author TEXT,topic TEXT,favorite INTEGER,PRIMARY KEY (quote,author,topic))",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: dbVersion,
    );
  }

  Future<void> initDB() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), databaseName),
    );
  }

  Future<bool> checkIfDatabaseExists() async {
    return databaseFactory
        .databaseExists(join(await getDatabasesPath(), databaseName));
  }

  Future<void> deleteDBChoices(Quote response) async {
    final db = await database;
    List<String> values = [];
    values.add(response.quote);
    values.add(response.author);
    values.add(response.topic);
    await db.delete(tableName,
        // Use a `where` clause to delete a specific dog.
        where: "quote = ? AND author = ? AND topic = ?",
        // Pass the Dog's id as a whereArg to prevent SQL injection.
        whereArgs: values);

    notifyListeners();
  }

  Future<void> getTopicsFromDB() async {
    final db = await database;
    jsonToEncodedTopics(
        await db.rawQuery('SELECT * DISTINCT topic FROM quotes;'));
    notifyListeners();
  }

  Future<void> updateDB(List<Quote> list) async {
    // Get a reference to the database.
    final Database db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    print("\n\n\n\n\n\n\ninserting to DB");

    var batch = db.batch();
    list.forEach((element) async {
      batch.insert(tableName, element.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      //await db.insert(TableName,element.toMap(), conflictAlgorithm: ConflictAlgorithm.replace,);
    });
    print("batch.commit is excuting");
    await batch.commit(noResult: true);
    print("Done");
  }

  Future<void> readDB() async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    // Convert the List<Map<String, dynamic> into a List<Note>.

    dbQuotes = List.generate(maps.length, (i) {
      return Quote(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    dbQuotes.shuffle();
    oldDbQuotes = dbQuotes;
    notifyListeners();
  }

  Future<void> getLocalDBTopics() async {
    await createDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT DISTINCT topic FROM quotes''');
    topics = stableTopicOrder(
        topics, [for (final row in maps) row['topic'] as String]);
    notifyListeners();
  }

  Future<void> vacuum() async {
    await createDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''VACUUM''');
    notifyListeners();
  }

  Future<void> getLocalDBQuotes(String topic) async {
    await createDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT * FROM quotes where topic = ?''', [topic]);
    dbQuotes = List.generate(maps.length, (i) {
      return Quote(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    dbQuotes.shuffle();
    notifyListeners();
  }

  Future<void> getFavorites() async {
    await createDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT * FROM quotes where favorite = ?''', [1]);
    dbQuotes = List.generate(maps.length, (i) {
      return Quote(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    dbQuotes.shuffle();
    notifyListeners();
  }

  Future<void> rowsCount() async {
    // Get a reference to the database.
    await createDB();
    Database db = await database;
    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    dbRowCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM quotes')) ??
        0;
    print(dbRowCount);
  }

  Future<void> serverQuotesCount() async {
    http.Response response =
        await http.get(getUrlForRoute("/see_saved_online_count"));

    //print(response.body);
    if (response.statusCode == 200) {
      jsonToCount(response.body);
      //jsonResponse = convert.jsonDecode(response.body);
      //JsonToCount(jsonResponse);

//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }
}

/// Parses the backend's JSON array of `{quote, author, topic}` objects.
List<Quote> quotesFromJson(String body) {
  final List<dynamic> rows = convert.jsonDecode(body);
  return [
    for (final row in rows)
      Quote(row['quote'] as String, row['author'] as String,
          row['topic'] as String, 0),
  ];
}

/// Keeps the topics already on screen where they are and appends new ones in
/// random order. The grid is still shuffled on each launch, but a refresh
/// after a download no longer moves the chip under the user's finger.
List<String> stableTopicOrder(List<String> current, List<String> fresh,
    [Random? random]) {
  final freshSet = fresh.toSet();
  final kept = [
    for (final t in current)
      if (freshSet.contains(t)) t
  ];
  final keptSet = kept.toSet();
  final added = [
    for (final t in fresh)
      if (!keptSet.contains(t)) t
  ]..shuffle(random);
  return [...kept, ...added];
}

/// Whether to run the full update download: the server has more quotes than
/// the device, and that server count isn't the one already fully synced.
bool needsQuoteUpdate(int localCount, int serverCount, int? lastSynced) =>
    localCount < serverCount && serverCount != lastSynced;

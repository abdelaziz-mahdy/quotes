import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:path/path.dart';
import 'package:share/share.dart';
import 'package:sqflite/sqflite.dart';
import 'snackbars.dart';

class ResponseDecoded {
  String quote = "";
  String author = "";
  String topic = "";
  int Selected = 0;
  int Favorite = 0;

  ResponseDecoded(this.quote, this.author, this.topic, this.Favorite);
  void toggleSelected() {
    Selected++;
    Selected = Selected % 2;
    print(Selected);
  }

  void toggleFavorite() {
    Favorite++;
    Favorite = Favorite % 2;
    print(Favorite);
  }

  Map<String, dynamic> toMap() {
    return {
      'quote': quote,
      'author': author,
      'topic': topic,
      'favorite': Favorite,
    };
  }
}

class searchengine extends ChangeNotifier {
  //use your domain here as the url

  /*
  json responses should look like this 
[
{
"author": "Benjamin Franklin",
"quote": "Marriage is the most natural state of man, and... the state in which you will find solid happiness.",
"topic": "Anniversary"
}, 
{
"author": "George Bernard Shaw", 
"quote": "Marriage is an alliance entered into by a man who can't sleep with the window shut, and a woman who can't sleep with the window open.", 
"topic": "Anniversary"
}, 
{
"author": "H. L. Mencken",
"quote": "Strike an average between what a woman thinks of her husband a month before she marries him and what she thinks of him a year afterward, and you will have the truth about him.", 
"topic": "Anniversary"
}
]
  */
  // String url = "http://127.0.0.1:5000";
  String url = "https://my-qoutes-app-123456.nw.r.appspot.com";

  var jsonResponse = [];
  List<String> topics = [];
  List<ResponseDecoded> responses = [];
  List<ResponseDecoded> DB_quotes = [];
  List<ResponseDecoded> Old_DB_quotes = [];
  int test_count = 0;
  int DB_Row_count = 0;
  int ServerCount = 0;
  int DB_version = 2;
  List<int> state = [0, 25, 50, 75, 100];
  void JsonToEncoded(var response) {
    for (int i = 0; i < response.length; i++) {
      ResponseDecoded note = ResponseDecoded(
          response[i]['quote'], response[i]['author'], response[i]['topic'], 0);
      responses.add(note);
    }
  }

  void JsonToEncodedTopics(var response) {
    for (int i = 0; i < response.length; i++) {
      topics.add(response[i]['topic']);
    }
    print(topics);
  }

  void JsonToCount(var response) {
    print(response);
    ServerCount = int.parse(response);
  }

  int NumSelected(var List) {
    int selected = 0;
    for (int i = 0; i < List.length; i++) {
      if (List[i].Selected == 1) {
        selected++;
      }
    }
    return selected;
  }

  bool SelectedExist(var List) {
    for (int i = 0; i < List.length; i++) {
      if (List[i].Selected == 1) {
        print(true);
        return true;
      }
    }
    print(false);
    return false;
  }

  void Selected(var List, int index) {
    List[index].toggleSelected();
    notifyListeners();
  }

  void toggleFavorite_update_db(var List, int index) {
    List[index].toggleFavorite();
    UpdateDB(DB_quotes);
    notifyListeners();
  }

  void ShareSelected(var List) {
    var ToShare = [];
    List.forEach((element) {
      if (element.Selected == 1) {
        element.Selected = 0;
        ToShare.add(element);
      }
    });
    String ToShareString = "";
    ToShare.forEach((element) {
      ToShareString = ToShareString +
          '''
Quote: ''' +
          element.quote +
          '''\n
Author: ''' +
          element.author +
          "\n\n";
    });
    Share.share(ToShareString);
    notifyListeners();
  }

  Uri getUrlForRoute(String route) {
    return Uri.parse(url + route);
  }

  Future<void> getQuotes() async {
    http.Response response =
        await http.get(getUrlForRoute("/see_saved_online"));
    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      JsonToEncoded(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    print("all items got retrieved");
    DB_quotes = responses;
    notifyListeners();
  }

  Future<void> getPreviewQuotes() async {
    http.Response response =
        await http.get(getUrlForRoute("/see_saved_online_preview"));

    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      JsonToEncoded(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    print("all items got retrieved");
    DB_quotes = responses;
    notifyListeners();
  }

  Future<void> CheckNewDatabaseVersion() async {
    int oldversion = 999;
    bool exists;
    exists = await CheckIfDatabaseExists();
    try {
      if (exists) {
        await InitDB();
        final Database db = await database;
        print(oldversion);
        oldversion = await db.getVersion();
        print(oldversion);
      }
    } catch (_) {}
    if (oldversion < DB_version && oldversion != 0) {
      print("Reading old Database");
      await ReadDB();
      print("deleting old Database");
      await DeleteDataBase();
      print("creating new Database");
      await CreateDB();
      print("updating new Database");
      await UpdateDB(DB_quotes);
    } else {
      print("Database is at last version");
    }
  }

  Future<void> DeleteDataBase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, DatabaseName);
    var db = await openDatabase(path);
    db.close();
    //delete the old database so you can copy the new one
    await deleteDatabase(path);
  }

  Future<void> getQuotes_db() async {
    http.Response response = await http.get(getUrlForRoute("/see_db"));

    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      JsonToEncoded(jsonResponse);
      //      jsonResponse[0]["author"]; = author name
      //      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    print("all items got retrieved");
    DB_quotes = responses;
    notifyListeners();
  }

  //try to retrive all and do the proccesing in the mobile phone
  //save the qoutes it got from server to DB
  Future<void> SaveQoutesResponse() async {
    // Get a reference to the database.
    final Database db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    test_count = 0;
    print("\n\n\n\n\n\n\ninserting to Qoutes DB");
    responses.forEach((element) async {
      test_count++;
      print(test_count);
      await db.insert(
        TableName,
        element.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    notifyListeners();
  }

  Future<void> GetTopicQuotes(String topic) async {
    http.Response response = await http
        .get(getUrlForRoute("/GetQuotesByTopicFromDB/?topic=" + topic));

    print(response.body);
    if (response.statusCode == 200) {
      jsonResponse = convert.jsonDecode(response.body);
      print(jsonResponse);
      jsonResponse.shuffle();
      JsonToEncoded(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
    notifyListeners();
  }

  void clearold() {
    responses.clear();
    DB_quotes.clear();
    jsonResponse.clear();
  }

  Future<void> getTopics() async {
    if (jsonResponse.length == 0) {
      http.Response response = await http.get(getUrlForRoute("/getdbtopics"));

      if (response.statusCode == 200) {
        jsonResponse = convert.jsonDecode(response.body);

        jsonResponse.shuffle();
        JsonToEncodedTopics(jsonResponse);
//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
      } else {
        print("Request failed with status: ${response.statusCode}.");
      }
    }
    notifyListeners();
  }

  Future<void> download_and_insert_to_db(
      GlobalKey<ScaffoldState> scafold, int snacktext) async {
    //snack text =0 text ==downloading(first time)
    //snack text =1 text ==updating
    await CreateDB();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[0], snacktext));
    await ReadDB();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[1], snacktext));
    //await getQuotes_db();
    await getQuotes();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[2], snacktext));
    await UpdateDB(DB_quotes);
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[3], snacktext));
    await UpdateDB(Old_DB_quotes);
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[4], snacktext));
    await GetLocalDBTopics();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
  }

  Future<void> download_preview_and_insert_to_db(
      GlobalKey<ScaffoldState> scafold) async {
    await CreateDB();
  ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
  ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[0], 2));



    //await getQuotes_db();
    await getPreviewQuotes();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[3], 2));

    
    await UpdateDB(DB_quotes);
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
    ScaffoldMessenger.of(scafold.currentContext!).showSnackBar(downloading(state[4], 2));
    await GetLocalDBTopics();
    ScaffoldMessenger.of(scafold.currentContext!).removeCurrentSnackBar();
  }

  //database values
  String DatabaseName = "quotes_database.db";
  String TableName = "quotes";
  late Future<Database> database;
  //create the DB+Get refrence for it

  Future<void> CreateDB() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), DatabaseName),
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.

        return db.execute(
          "CREATE TABLE quotes(quote TEXT,author TEXT,topic TEXT,favorite INTEGER,PRIMARY KEY (quote,author,topic))",
        );
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: DB_version,
    );
  }

  Future<void> InitDB() async {
    database = openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(await getDatabasesPath(), DatabaseName),
    );
  }

  Future<bool> CheckIfDatabaseExists() async {
    return databaseFactory
        .databaseExists(join(await getDatabasesPath(), DatabaseName));
  }

  Future<void> deleteDBChoices(ResponseDecoded response) async {
    final db = await database;
    List<String> values = [];
    values.add(response.quote);
    values.add(response.author);
    values.add(response.topic);
    await db.delete(TableName,
        // Use a `where` clause to delete a specific dog.
        where: "quote = ? AND author = ? AND topic = ?",
        // Pass the Dog's id as a whereArg to prevent SQL injection.
        whereArgs: values);

    notifyListeners();
  }

  Future<void> GetTopicsFromDB() async {
    final db = await database;
    JsonToEncodedTopics(
        await db.rawQuery('SELECT * DISTINCT topic FROM quotes;'));
    notifyListeners();
  }

  Future<void> UpdateDB(var list) async {
    // Get a reference to the database.
    final Database db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    print("\n\n\n\n\n\n\ninserting to DB");

    var batch = db.batch();
    list.forEach((element) async {
      batch.insert(TableName, element.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      //await db.insert(TableName,element.toMap(), conflictAlgorithm: ConflictAlgorithm.replace,);
    });
    print("batch.commit is excuting");
    await batch.commit(noResult: true);
    print("Done");
  }

  Future<void> ReadDB() async {
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    final List<Map<String, dynamic>> maps = await db.query(TableName);

    // Convert the List<Map<String, dynamic> into a List<Note>.

    DB_quotes = List.generate(maps.length, (i) {
      return ResponseDecoded(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    DB_quotes.shuffle();
    Old_DB_quotes = DB_quotes;
    notifyListeners();
  }

  Future<void> GetLocalDBTopics() async {
    await CreateDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT DISTINCT topic FROM quotes''');
    topics = List.generate(maps.length, (i) {
      return maps[i]['topic'];
    });
    topics.shuffle();
    notifyListeners();
  }

  Future<void> Vaccum() async {
    await CreateDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps = await db.rawQuery('''VACUUM''');
    notifyListeners();
  }

  Future<void> GetLocalDBQoutes(String topic) async {
    await CreateDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT * FROM quotes where topic = ?''', [topic]);
    DB_quotes = List.generate(maps.length, (i) {
      return ResponseDecoded(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    DB_quotes.shuffle();
    notifyListeners();
  }

  Future<void> GetFavorites() async {
    await CreateDB();
    // Get a reference to the database.
    final Database db = await database;

    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    final List<Map<String, dynamic>> maps =
        await db.rawQuery('''SELECT * FROM quotes where favorite = ?''', [1]);
    DB_quotes = List.generate(maps.length, (i) {
      return ResponseDecoded(
        maps[i]['quote'],
        maps[i]['author'],
        maps[i]['topic'],
        maps[i]['favorite'],
      );
    });
    DB_quotes.shuffle();
    notifyListeners();
  }

  Future<void> RowsCount() async {
    // Get a reference to the database.
    await CreateDB();
    Database db = await database;
    // Query the table for all The Notes.
    // Convert the List<Map<String, dynamic> into a List<Note>.
    DB_Row_count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM quotes')) ??
        0;
    print(DB_Row_count);
  }

  Future<void> ServerQoutesCount() async {
    http.Response response =
        await http.get(getUrlForRoute("/see_saved_online_count"));

    //print(response.body);
    if (response.statusCode == 200) {
      JsonToCount(response.body);
      //jsonResponse = convert.jsonDecode(response.body);
      //JsonToCount(jsonResponse);

//      jsonResponse[0]["author"]; = author name
//      jsonResponse[0]["quote"]; = quotes text
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }
}

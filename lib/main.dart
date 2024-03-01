import 'package:flutter/material.dart';
import 'package:quotes/screens/photos_view.dart';
import 'package:provider/provider.dart';
import 'engine.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<searchengine>(
      create: (context) => searchengine(),
      child: MaterialApp(
        darkTheme: ThemeData.dark(),
        theme: ThemeData.light(),
        themeMode: ThemeMode.system,
        home: MyHomePage(
          title: "Quotes Topics",
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int col = 3;
  var topics = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    onStart();
    super.initState();
  }

  void onStart() async {
    await Provider.of<searchengine>(context, listen: false)
        .CheckNewDatabaseVersion(); //check for any changes in the database"to be able to add funcnalioty"
    await Provider.of<searchengine>(context, listen: false)
        .RowsCount(); //check local DB rows
    if (Provider.of<searchengine>(context, listen: false).DB_Row_count == 0) {
      //if the local DB has 0 rows
      print("Downloading preview Qoutes");
      await Provider.of<searchengine>(context, listen: false)
          .download_preview_and_insert_to_db(
              _scaffoldKey); //download a preview for the user
      print("Downloading Qoutes");
      await Provider.of<searchengine>(context, listen: false)
          .download_and_insert_to_db(
              _scaffoldKey, 0); //0 is downloading first time text
    } else {
      print("Reading DB");
      Provider.of<searchengine>(context, listen: false).GetLocalDBTopics();
      await Provider.of<searchengine>(context, listen: false)
          .ServerQoutesCount(); //get the server quotes count
      //if the local DB has rows less than than the server ones
      if (Provider.of<searchengine>(context, listen: false).DB_Row_count <
          Provider.of<searchengine>(context, listen: false).ServerCount) {
        print("updating DB");
        await Provider.of<searchengine>(context, listen: false)
            .download_and_insert_to_db(_scaffoldKey, 1); //1 is updating text
      }
    }
    //if(topics.length==0){Provider.of<searchengine>(context, listen: false).getTopics();topics=Provider.of<searchengine>(context, listen: false).topics;} //push to next screen
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 30,
              ),
              onPressed: () {
                Provider.of<searchengine>(context, listen: false).clearold();
                Navigator.of(context).push(_createRoute("Favorite"));
              })
        ],
      ),
      body:
          Consumer<searchengine>(builder: (context, searchengine data, child) {
        return data.topics.length != 0
            ? SingleChildScrollView(
                child: TopicCards(data, context),
              )
            : Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.black,
                ),
              );
      }),
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
    );
  }

  Wrap TopicCards(searchengine data, BuildContext context) {
    return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: data.topics.map<Widget>((document) {
          return Material(
            child: InkWell(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                splashColor: Colors.blue,
                highlightColor: Colors.blue,
                onTap: () {
                  Provider.of<searchengine>(context, listen: false).clearold();
                  //Navigator.push(context, MaterialPageRoute(builder: (context)=>  PhotosList(document)));
                  Navigator.of(context).push(_createRoute(document));
                },
                child: DataCard(document)),
          );
        }).toList());
  }

  Route _createRoute(var document) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          PhotosList(document),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(1, 0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class DataCard extends StatelessWidget {
  var topic;
  DataCard(this.topic);

  @override
  Widget build(BuildContext context) {
    //print(data);
    return Card(
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
        padding: EdgeInsets.all(15),
        child: Text(
          topic,
          style: TextStyle(fontSize: 15),
          maxLines: 1,
        ),
      ),
    );
  }
}

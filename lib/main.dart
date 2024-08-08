import 'package:flutter/material.dart';
import 'package:quotes/screens/photos_view.dart';
import 'package:provider/provider.dart';
import 'engine.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Processor>(
      create: (context) => Processor(),
      child: MaterialApp(
        darkTheme: ThemeData.dark(),
        theme: ThemeData.light(),
        themeMode: ThemeMode.system,
        home: const MyHomePage(
          title: "Quotes Topics",
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
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
    await Provider.of<Processor>(context, listen: false)
        .checkNewDatabaseVersion(); //check for any changes in the database"to be able to add funcnalioty"
    await Provider.of<Processor>(context, listen: false)
        .rowsCount(); //check local DB rows
    if (Provider.of<Processor>(context, listen: false).dbRowCount == 0) {
      //if the local DB has 0 rows
      print("Downloading preview Qoutes");
      await Provider.of<Processor>(context, listen: false)
          .downloadPreviewAndInsertToDb(
              _scaffoldKey); //download a preview for the user
      print("Downloading Qoutes");
      await Provider.of<Processor>(context, listen: false)
          .downloadAndInsertToDb(
              _scaffoldKey, 0); //0 is downloading first time text
    } else {
      print("Reading DB");
      Provider.of<Processor>(context, listen: false).getLocalDBTopics();
      await Provider.of<Processor>(context, listen: false)
          .serverQuotesCount(); //get the server quotes count
      //if the local DB has rows less than than the server ones
      if (Provider.of<Processor>(context, listen: false).dbRowCount <
          Provider.of<Processor>(context, listen: false).serverCount) {
        print("updating DB");
        await Provider.of<Processor>(context, listen: false)
            .downloadAndInsertToDb(_scaffoldKey, 1); //1 is updating text
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
              icon: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 30,
              ),
              onPressed: () {
                Provider.of<Processor>(context, listen: false).clearOld();
                Navigator.of(context).push(_createRoute("Favorite"));
              })
        ],
      ),
      body: Consumer<Processor>(builder: (context, Processor data, child) {
        return data.topics.isNotEmpty
            ? SingleChildScrollView(
                child: TopicCards(data, context),
              )
            : const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.black,
                ),
              );
      }),
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
    );
  }

  Wrap TopicCards(Processor data, BuildContext context) {
    return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: data.topics.map<Widget>((document) {
          return Material(
            child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                splashColor: Colors.blue,
                highlightColor: Colors.blue,
                onTap: () {
                  Provider.of<Processor>(context, listen: false).clearOld();
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
        var begin = const Offset(1, 0);
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
  DataCard(this.topic, {super.key});

  @override
  Widget build(BuildContext context) {
    //print(data);
    return Card(
      child: Ink(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(15),
          ),
        ),
        padding: const EdgeInsets.all(15),
        child: Text(
          topic,
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
        ),
      ),
    );
  }
}

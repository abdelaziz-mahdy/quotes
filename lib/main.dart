import 'package:flutter/material.dart';
import 'package:quotes/screens/PhotosView.dart';
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
        create: (context)=> searchengine(),
      child: MaterialApp(
        darkTheme: ThemeData.dark(),
        theme: ThemeData.light(),
        home: MyHomePage(
          title: "Quotes Topics",
        ),

      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    int col=3;
    var topics=[];

  @override
  Widget build(BuildContext context) {
    if(topics.length==0){Provider.of<searchengine>(context, listen: false).getTopics();
    topics=Provider.of<searchengine>(context, listen: false).topics;}
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<searchengine>(
      builder: (context,searchengine data,child) {
        return SingleChildScrollView(
          child: Wrap(
              spacing: 8.0, // gap between adjacent chips
              runSpacing: 4.0, // gap between lines

       children:topics.map<Widget>((document) {
           return GestureDetector(onTap: (){
             Provider.of<searchengine>(context, listen: false).clearold();
             Provider.of<searchengine>(context, listen: false).GetTopicQuotes(document);

           Navigator.push(context, MaterialPageRoute(builder: (context)=>  PhotosList(document)));
           },
               child: DataCard(document));
       }).toList()

          ),
        );

        }
      ),
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.

      );

  }
}
class DataCard extends StatelessWidget {
  var topic;
  DataCard(this.topic);

  @override
  Widget build(BuildContext context) {
    //print(data);
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,

          borderRadius: BorderRadius.all(
              Radius.circular(10),
          ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 1.0,
            spreadRadius: 0.0,
            offset: Offset(0, 0), // shadow direction: bottom right
          )
        ],
      ),
      padding: EdgeInsets.all(15),
      margin:EdgeInsets.all(5),

      child: Text(
        topic,
        style: TextStyle(fontSize: 15),
        maxLines: 1,
      ),
    );
  }
}


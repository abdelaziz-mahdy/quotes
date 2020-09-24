import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine.dart';
class PhotosList extends StatefulWidget {
  String APPTitle;


  PhotosList(this.APPTitle);

  @override
  _PhotosListState createState() => _PhotosListState(APPTitle);
}

class _PhotosListState extends State<PhotosList> {
  bool ontapselect=false;
  String APPTitle;

  _PhotosListState(this.APPTitle);

  @override
  Widget build(BuildContext context) {
    //Provider.of<searchengine>(context,listen: false).getQuotes();

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: Provider.of<searchengine>(context,listen: false).SelectedExist()==true?SelectedAppBar(context):NormalAppBar(),


      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      body: Consumer<searchengine>(
          builder: (context,searchengine data,child) {
            return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: data.responses.length,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                      onTap:  (){
                        if(ontapselect==true){setState(() {
                          Provider.of<searchengine>(context,listen: false).Selected(index);
                        });}
                      },
                      onLongPress: (){
                        setState(() {
                          Provider.of<searchengine>(context,listen: false).Selected(index);
                          ontapselect=true;
                        });
                      },

                      child: DataCard(data.responses[index])
                  );
                }
            );
          }
      ),
    );
  }

  PreferredSize NormalAppBar() {
    if(Provider.of<searchengine>(context,listen: false).NumSelected()==0){ontapselect=false;}
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text(APPTitle+" Quotes" ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  PreferredSize SelectedAppBar(BuildContext context) {
    int selected=Provider.of<searchengine>(context,listen: false).NumSelected();
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text("Selected :"+selected.toString()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(icon:Icon(Icons.share),
              onPressed: (){
                setState(() {
                  Provider.of<searchengine>(context, listen: false).ShareSelected();
                  ontapselect=false;
                });
              })
        ],
      ),

    );
  }
}

class DataCard extends StatelessWidget {
  var data;
  DataCard(this.data);

  @override
  Widget build(BuildContext context) {
    //print(data);
    return Container(
        decoration: BoxDecoration(
            color: data.Selected==0?Theme.of(context).cardColor:Colors.blueGrey,

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
      margin: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5,),
          Text(
            data.quote ?? 'default value',
            style: TextStyle(fontSize: 18),
            maxLines: 10,
          ),
          SizedBox(height: 10,),
          Text(
            data.author ?? 'default value',
            style: TextStyle(fontSize: 18),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),

    );
  }
}



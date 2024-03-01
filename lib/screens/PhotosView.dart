import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine.dart';

class PhotosList extends StatefulWidget {
  String APPTitle;

  PhotosList(this.APPTitle);

  @override
  _PhotosListState createState() => _PhotosListState(APPTitle);
}

class _PhotosListState extends State<PhotosList> with TickerProviderStateMixin {
  bool ontapselect = false;
  String APPTitle;

  _PhotosListState(this.APPTitle);
  //animation values
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    if (APPTitle == "Favorite") {
      Provider.of<searchengine>(context, listen: false).GetFavorites();
    } else {
      Provider.of<searchengine>(context, listen: false)
          .GetLocalDBQoutes(APPTitle);
    }
    super.initState();
    //Provider.of<searchengine>(context,listen: false).GetTopicQuotes(APPTitle);
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
      backgroundColor: Colors.black,
      appBar: Provider.of<searchengine>(context, listen: false).SelectedExist(
                  Provider.of<searchengine>(context, listen: false)
                      .DB_quotes) ==
              true
          ? SelectedAppBar(context)
          : NormalAppBar(),

      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      body:
          Consumer<searchengine>(builder: (context, searchengine data, child) {
        return data.DB_quotes.length != 0
            ? ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(),
                itemCount: data.DB_quotes.length,
                itemBuilder: (BuildContext context, int index) {
                  _controller.forward();
                  return FadeTransition(
                      opacity: _animation,
                      child: BuildQoutesCards(context, data, index));
                })
            : data.DB_quotes.length == 0 && APPTitle == "Favorite"
                ? ListView.separated(
                    padding: const EdgeInsets.all(8),
                    separatorBuilder: (BuildContext context, int index) =>
                        Divider(),
                    itemCount: 1,
                    itemBuilder: (BuildContext context, int index) {
                      _controller.forward();
                      return FadeTransition(
                          opacity: _animation, child: ADDFavorite(context));
                    })
                : Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.black,
                    ),
                  );
      }),
    );
  }

  Material BuildQoutesCards(
      BuildContext context, searchengine data, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
          splashColor: Colors.blue,
          highlightColor: Colors.blue,
          onTap: () {
            if (ontapselect == true) {
              setState(() {
                Provider.of<searchengine>(context, listen: false)
                    .Selected(data.DB_quotes, index);
              });
            }
          },
          onLongPress: () {
            setState(() {
              Provider.of<searchengine>(context, listen: false)
                  .Selected(data.DB_quotes, index);
              ontapselect = true;
            });
          },
          //DataCard(data.DB_quotes[index])
          child: DataCard(data, context, index)),
    );
  }

  Ink DataCard(searchengine data, BuildContext context, int index) {
    return Ink(
      decoration: BoxDecoration(
        color: data.DB_quotes[index].Selected == 0
            ? Theme.of(context).cardColor
            : Colors.blueGrey,
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 3.0,
            spreadRadius: 1.0,
          )
        ],
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 5,
          ),
          Text(
            data.DB_quotes[index].quote ?? 'default value',
            style: TextStyle(fontSize: 18),
            maxLines: 10,
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.DB_quotes[index].author ?? 'default value',
                style: TextStyle(fontSize: 18),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      data.toggleFavorite_update_db(data.DB_quotes, index);
                    });
                  },
                  icon: Icon(
                    data.DB_quotes[index].Favorite == 0
                        ? Icons.favorite_border
                        : Icons.favorite,
                    color:
                        data.DB_quotes[index].Favorite == 1 ? Colors.red : null,
                  ))
            ],
          ),
        ],
      ),
    );
  }

  Ink ADDFavorite(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 3.0,
            spreadRadius: 1.0,
          )
        ],
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 5,
          ),
          Text(
            'Please Add Some Favorite quotes to display here',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  PreferredSize NormalAppBar() {
    if (Provider.of<searchengine>(context, listen: false).NumSelected(
            Provider.of<searchengine>(context, listen: false).DB_quotes) ==
        0) {
      ontapselect = false;
    }
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text(APPTitle + " Quotes"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  PreferredSize SelectedAppBar(BuildContext context) {
    int selected = Provider.of<searchengine>(context, listen: false)
        .NumSelected(
            Provider.of<searchengine>(context, listen: false).DB_quotes);
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text("Selected :" + selected.toString()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                setState(() {
                  Provider.of<searchengine>(context, listen: false)
                      .ShareSelected(
                          Provider.of<searchengine>(context, listen: false)
                              .DB_quotes);
                  ontapselect = false;
                });
              })
        ],
      ),
    );
  }
}

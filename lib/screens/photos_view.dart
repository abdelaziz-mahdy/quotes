import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine.dart';

class PhotosList extends StatefulWidget {
  final String appTitle;

  const PhotosList(this.appTitle, {super.key});

  @override
  _PhotosListState createState() => _PhotosListState(appTitle);
}

class _PhotosListState extends State<PhotosList> with TickerProviderStateMixin {
  bool onTapSelect = false;
  String appTitle;

  _PhotosListState(this.appTitle);
  //animation values
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    if (appTitle == "Favorite") {
      Provider.of<Processor>(context, listen: false).getFavorites();
    } else {
      Provider.of<Processor>(context, listen: false).getLocalDBQuotes(appTitle);
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
      appBar: Provider.of<Processor>(context, listen: false).selectedExist(
                  Provider.of<Processor>(context, listen: false).dbQuotes) ==
              true
          ? selectedAppBar(context)
          : NormalAppBar(),

      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      body: Consumer<Processor>(builder: (context, Processor data, child) {
        return data.dbQuotes.isNotEmpty
            ? ListView.separated(
                padding: const EdgeInsets.all(8),
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
                itemCount: data.dbQuotes.length,
                itemBuilder: (BuildContext context, int index) {
                  _controller.forward();
                  return FadeTransition(
                      opacity: _animation,
                      child: buildQuotesCards(context, data, index));
                })
            : data.dbQuotes.isEmpty && appTitle == "Favorite"
                ? ListView.separated(
                    padding: const EdgeInsets.all(8),
                    separatorBuilder: (BuildContext context, int index) =>
                        const Divider(),
                    itemCount: 1,
                    itemBuilder: (BuildContext context, int index) {
                      _controller.forward();
                      return FadeTransition(
                          opacity: _animation, child: ADDFavorite(context));
                    })
                : const Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.black,
                    ),
                  );
      }),
    );
  }

  Material buildQuotesCards(BuildContext context, Processor data, int index) {
    return Material(
      child: InkWell(
          borderRadius: const BorderRadius.all(
            Radius.circular(20),
          ),
          splashColor: Colors.blue,
          highlightColor: Colors.blue,
          onTap: () {
            if (onTapSelect == true) {
              setState(() {
                Provider.of<Processor>(context, listen: false)
                    .selected(data.dbQuotes, index);
              });
            }
          },
          onLongPress: () {
            setState(() {
              Provider.of<Processor>(context, listen: false)
                  .selected(data.dbQuotes, index);
              onTapSelect = true;
            });
          },
          //DataCard(data.DB_quotes[index])
          child: dataCard(data, context, index)),
    );
  }

  Ink dataCard(Processor data, BuildContext context, int index) {
    return Ink(
      decoration: BoxDecoration(
        color: data.dbQuotes[index].selected == 0
            ? Theme.of(context).cardColor
            : Colors.blueGrey,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 5,
          ),
          Text(
            data.dbQuotes[index].quote,
            style: const TextStyle(fontSize: 18),
            maxLines: 10,
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.dbQuotes[index].author,
                style: const TextStyle(fontSize: 18),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              IconButton(
                  onPressed: () {
                    setState(() {
                      data.toggleFavoriteUpdateDb(data.dbQuotes, index);
                    });
                  },
                  icon: Icon(
                    data.dbQuotes[index].favorite == 0
                        ? Icons.favorite_border
                        : Icons.favorite,
                    color:
                        data.dbQuotes[index].favorite == 1 ? Colors.red : null,
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
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 3.0,
            spreadRadius: 1.0,
          )
        ],
      ),
      padding: const EdgeInsets.all(15),
      child: const Column(
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
    if (Provider.of<Processor>(context, listen: false).numSelected(
            Provider.of<Processor>(context, listen: false).dbQuotes) ==
        0) {
      onTapSelect = false;
    }
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text("$appTitle Quotes"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  PreferredSize selectedAppBar(BuildContext context) {
    int selected = Provider.of<Processor>(context, listen: false)
        .numSelected(Provider.of<Processor>(context, listen: false).dbQuotes);
    return PreferredSize(
      preferredSize: const Size(double.infinity, kToolbarHeight),
      child: AppBar(
        title: Text("Selected :$selected"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                setState(() {
                  Provider.of<Processor>(context, listen: false).shareSelected(
                      Provider.of<Processor>(context, listen: false).dbQuotes);
                  onTapSelect = false;
                });
              })
        ],
      ),
    );
  }
}

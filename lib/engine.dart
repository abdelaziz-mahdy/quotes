import 'package:flutter/cupertino.dart';
import 'package:http/http.dart'as http;
import 'dart:convert' as convert;

import 'package:share/share.dart';
class ResponseDecoded{
  String quote="";
  String author="";
  String topic="";
  int Selected=0;

  ResponseDecoded(this.quote, this.author,this.topic);
  void toggleSelected(){
    Selected++;
    Selected=Selected%2;
    print(Selected);
  }
}


class searchengine extends ChangeNotifier{
    var jsonResponse=[];
    List<String> topics=new List<String>();
    List<ResponseDecoded> responses= new List<ResponseDecoded>();
    void JsonToEncoded(var response){

      for(int i=0;i<response.length;i++){
        ResponseDecoded note=ResponseDecoded(response[i]['quote'],response[i]['author'],response[i]['topic']);
        responses.add(note);
      }
    }
    void JsonToEncodedTopics(var response){
      for(int i=0;i<response.length;i++){
        topics.add(response[i]['topic']);
      }
      print(topics);
    }
    int  NumSelected(){
      int selected=0;
      for(int i=0;i<responses.length;i++){
        if(responses[i].Selected==1){
          selected++;
        }}
      return selected;
    }
    bool SelectedExist(){
      for(int i=0;i<responses.length;i++){
        if(responses[i].Selected==1){
          print(true);
          return true;
        }}
      print(false);
      return false;
    }
    void Selected(int index){
      responses[index].toggleSelected();
      notifyListeners();
    }

    void ShareSelected(){
      var ToShare = [];
      responses.forEach((element) {if(element.Selected==1){
        element.Selected=0;
        ToShare.add(element);
      }});
      String ToShareString="";
      ToShare.forEach((element) {ToShareString=ToShareString+'''/n
       Quote: '''+element.quote+'''
       Author: '''+element.author; });
      Share.share(ToShareString);
      notifyListeners();
    }
    Future<void> getQuotes() async {

        String url = "https://my-qoutes-app-123456.nw.r.appspot.com/see_db";
        http.Response response = await http.get(url);
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
    Future<void> GetTopicQuotes(String topic) async {

        String url = "https://my-qoutes-app-123456.nw.r.appspot.com/getquotes/?topic="+topic;
        http.Response response = await http.get(url);
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
      void clearold(){
      responses.clear();
      jsonResponse.clear();
      }
    Future<void> getTopics() async {
      if(jsonResponse.length==0){
        String url = "https://my-qoutes-app-123456.nw.r.appspot.com/gettopics";
        http.Response response = await http.get(url);

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

}

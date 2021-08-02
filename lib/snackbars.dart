
import 'package:flutter/material.dart';


SnackBar downloading(int state,int snacktext){
  //snack text =0 text ==downloading(first time)
  //snack text =1 text ==updating
  //snack text =2 text ==preview
  String SnackBarText="";
  if(snacktext==0){SnackBarText='Downloading quotes so you can use the app offline \n\n\n relax and wait ♥\n';}
  else{
    if(snacktext==1){SnackBarText='Updating qoutes so you can have more quotes to enjoy \n\n\n relax and wait ♥\n';}
  else{
    if(snacktext==2){SnackBarText='Preview is on the way so you can see how the app look like\n';}
  }
  }
  return SnackBar(

    content: Text(SnackBarText+state.toString()+"%",style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.bold),),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.grey,
    duration: const Duration(minutes: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20),
      ),
    ),
  );
}


import 'package:flutter/material.dart';

SnackBar downloading(int state, int snackText) {
  //snack text =0 text ==downloading(first time)
  //snack text =1 text ==updating
  //snack text =2 text ==preview
  String snackBarText;

  switch (snackText) {
    case 0:
      snackBarText =
          'Downloading quotes so you can use the app offline \n\n\n relax and wait ♥\n';
      break;
    case 1:
      snackBarText =
          'Updating quotes so you can have more quotes to enjoy \n\n\n relax and wait ♥\n';
      break;
    case 2:
      snackBarText =
          'Preview is on the way so you can see how the app look like\n';
      break;
    default:
      snackBarText = 'Downloading...';
  }

  return SnackBar(
    content: Text(
      "$snackBarText$state%",
      style: const TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.grey,
    duration: const Duration(minutes: 1),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(20),
      ),
    ),
  );
}

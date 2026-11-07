import 'package:flutter/material.dart';

/// [state] is the percentage done, or null while the size of the remaining
/// work is unknown (the network fetch); the bar then animates instead of
/// sitting at 0%.
SnackBar downloading(int? state, int snackText) {
  //snack text =0 text ==downloading(first time)
  //snack text =1 text ==updating
  //snack text =2 text ==preview
  String snackBarText;

  switch (snackText) {
    case 0:
      snackBarText =
          'Downloading quotes so you can use the app offline.\nRelax and wait ♥';
      break;
    case 1:
      snackBarText =
          'Updating quotes so you can have more quotes to enjoy.\nRelax and wait ♥';
      break;
    case 2:
      snackBarText =
          'Preview is on the way so you can see what the app looks like';
      break;
    default:
      snackBarText = 'Downloading...';
  }

  // Theme colours (inverse surface) instead of white on grey, which was
  // hard to read, and a real progress bar next to the percentage.
  return SnackBar(
    content: Builder(builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snackBarText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: state == null ? null : state / 100,
                  color: scheme.inversePrimary,
                  backgroundColor:
                      scheme.onInverseSurface.withValues(alpha: 0.2),
                ),
              ),
              if (state != null) ...[
                const SizedBox(width: 12),
                Text(
                  "$state%",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ],
      );
    }),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(minutes: 1),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(20),
      ),
    ),
  );
}

SnackBar downloadFailed({required VoidCallback onRetry}) {
  return SnackBar(
    content: const Text(
      "Couldn't connect. Please check your internet connection.",
      style: TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.redAccent,
    // Persist until the user retries or dismisses it.
    duration: const Duration(days: 1),
    action: SnackBarAction(
      label: 'Retry',
      textColor: Colors.white,
      onPressed: onRetry,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(20),
      ),
    ),
  );
}

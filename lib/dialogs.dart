import 'package:flutter/material.dart';

enum ConfirmAction { CANCEL, ACCEPT }

class ShushDialogs {
  Future<String> getNewFileName(BuildContext context) async {
    String newName = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('File Name'),
          content: Row(
            children: <Widget>[
              new Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'File Name', hintText: 'shush',
                  ),
                  onChanged: (onValue) {
                    newName = onValue;
                  },
                ),
              )
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(newName);
              },
            )
          ],
        );
      }
    );
  }

  Future<ConfirmAction> asyncConfirmDialog(BuildContext context, String fileName) async {
    return showDialog<ConfirmAction>(
      context: context,
      barrierDismissible: false, // user must tap button for close dialog!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete recording?'),
          content: Text(
              'This will delete $fileName, confirm?'),
          actions: <Widget>[
            FlatButton(
              child: const Text('NO'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.CANCEL);
              },
            ),
            FlatButton(
              child: const Text('YES'),
              onPressed: () {
                Navigator.of(context).pop(ConfirmAction.ACCEPT);
              },
            )
          ],
        );
      },
    );
  }
}
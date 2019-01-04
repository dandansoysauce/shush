import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shush/recents_list.dart';

class Recents extends StatefulWidget {
  @override
  _RecentsState createState() => _RecentsState();
}

class _RecentsState extends State<Recents> {
  Future<String> get _externalPath async {
    final directory = await getExternalStorageDirectory();

    return directory.path;
  }

  Future<List<FileSystemEntity>> get _fetchFiles async {
    final path = await _externalPath;
    Directory externalShush = Directory('$path/shush');
    return externalShush.listSync();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: _fetchFiles,
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);
        return snapshot.hasData
          ? RecentsList(files: snapshot.data)
          : Center(child: CircularProgressIndicator());
      },
    );
  }
}
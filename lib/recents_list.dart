import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:dragable_flutter_list/dragable_flutter_list.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shush/audio_encrypter.dart';

class RecentsList extends StatelessWidget {
  FlutterSound _flutterSound = new FlutterSound();
  final List<FileSystemEntity> files;
  final formatter = DateFormat('MMMM d y');

  RecentsList({Key key, this.files}) : super(key: key);

  Future<String> get _externalPath async {
    final directory = await getExternalStorageDirectory();

    return directory.path;
  }

  Future<String> get _tempPath async {
    final directory = await getTemporaryDirectory();

    return directory.path;
  }

  void stopPlayer() async {
    try {
      await _flutterSound.stopPlayer();
    } catch (err) {

    }
  }

  void _tappedAudioItem(filename) async {
    final externalPath = await _externalPath;
    final tempPath = await _tempPath;

    File testFile = new File('$externalPath/shush/$filename');
    String encryptedValue = testFile.readAsStringSync();
    final tempAudio = await AudioEncrypter.decryptAudioAndWrite(tempPath, encryptedValue);
    stopPlayer();
    await _flutterSound.startPlayer(tempAudio);
    await _flutterSound.setVolume(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return DragAndDropList(
      files.length,
      itemBuilder: (context, index) {
        String fileName = p.basename(files[index].path);
        String modifiedDate = '';
        if (files[index] is File) {
          modifiedDate = formatter.format((files[index] as File).lastModifiedSync());
        }
        return ListTile(
          title: Text(fileName),
          subtitle: Text(modifiedDate),
          onTap: () {
            _tappedAudioItem(fileName);
          },
        );
      },
      onDragFinish: (before, after) {
        FileSystemEntity data = files[before];
        files.removeAt(before);
        files.insert(after, data);
      },
      canDrag: (index) {
        return index != 3;
      },
      canBeDraggedTo: (one, two) => true,
      dragElevation: 2.0,
    );
  }
}
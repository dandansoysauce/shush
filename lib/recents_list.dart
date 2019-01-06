import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shush/audio_encrypter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shush/dialogs.dart';

class RecentsList extends StatefulWidget {
  final List<File> files;

  RecentsList({Key key, this.files}) : super(key: key);

  @override
  _RecentsListState createState() => _RecentsListState(files: files);
}

class _RecentsListState extends State<RecentsList> with SingleTickerProviderStateMixin {
  final FlutterSound _flutterSound = new FlutterSound();
  final ShushDialogs _shushDialogs = ShushDialogs();
  final List<File> files;
  final formatter = DateFormat('MMMM d y');
  StreamSubscription _playerSubscription;
  AnimationController _animationController;
  Animation<double> _animateIcon;

  bool _isPlaying = false;
  String _playerTxt = '00:00';
  String _duration = '00:00';
  double playerValue = 0.0;
  double durationValue = 0.0;

  _RecentsListState({@required this.files});

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
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this.setState(() {
        this._isPlaying = false;
      });
      resetPlayerTexts();
    } catch (err) {
      print('error: $err');
    }
  }

  void _tappedAudioItem(filename) async {
    if (!_isPlaying) {
      _animationController.forward();
      setPlayerState();
      final externalPath = await _externalPath;
      final tempPath = await _tempPath;

      File testFile = new File('$externalPath/shush/$filename');
      String encryptedValue = testFile.readAsStringSync();
      final tempAudio = await AudioEncrypter.decryptAudioAndWrite(tempPath, encryptedValue);
      stopPlayer();
      await _flutterSound.startPlayer(tempAudio);
      await _flutterSound.setVolume(1.0);

      try {
        _playerSubscription = _flutterSound.onPlayerStateChanged.listen((e) {
          if (e != null) {
            DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
            String txt = DateFormat('mm:ss', 'en_US').format(date);

            DateTime dateDuration = new DateTime.fromMillisecondsSinceEpoch(e.duration.toInt());
            String txtDuration = DateFormat('mm:ss', 'en_US').format(dateDuration);
            setState(() {
              _playerTxt = txt.substring(0, 5);
              _duration = txtDuration;
              playerValue = e.currentPosition.toDouble();
              durationValue = e.duration.toDouble();
            });
          } else {
            resetPlayerTexts();
          }
        });
      } catch (e) {
        print('error $e');
      }
    } else {
      
    }
  }

  void _renameFile(BuildContext context, int index) async {
    String newFileName = await _shushDialogs.getNewFileName(context);
    String shushFolder = p.dirname(files[index].path);
    final file = files[index];
    file.rename('$shushFolder/$newFileName').then((f) {
      setState(() {
        files[index] = f;
      });
    });   
  }

  void _deleteFile(BuildContext context, int index) async {
    final fileName = p.basename(files[index].path);
    final deleteFile = await _shushDialogs.asyncConfirmDialog(context, fileName);
    if (deleteFile == ConfirmAction.ACCEPT) {
      final file = files[index];
      file.delete().then((onvalue) {
        setState(() {
          files.removeAt(index);
        });
      });
    }
  }

  void setPlayerState() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void resetPlayerTexts() {
    setState(() {
      playerValue = 0.0;
      _playerTxt = '00:00';
      _duration = '00:00';
      _isPlaying = false;
    });
  }

  void _pausePlayer() async {
    if (_isPlaying) {
      setPlayerState();
      _animationController.reverse();
      await _flutterSound.pausePlayer();
    } else {
      setPlayerState();
      _animationController.forward();
      await _flutterSound.resumePlayer();
    }
  }

  Widget buildBody(){
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            itemBuilder: (context, index) {
              String fileName = p.basename(files[index].path);
              String modifiedDate = '';
              if (files[index] is File) {
                modifiedDate = formatter.format(files[index].lastModifiedSync());
              }
              return Slidable(
                delegate: SlidableDrawerDelegate(),
                actionExtentRatio: 0.25,
                child: Container(
                  child: ListTile(
                    title: Text(fileName),
                    subtitle: Text(modifiedDate),
                    onTap: () {
                      _tappedAudioItem(fileName);
                    }
                  ),
                ),
                secondaryActions: <Widget>[
                  IconSlideAction(
                    caption: 'Rename',
                    icon: Icons.edit,
                    onTap: () {
                      _renameFile(context, index);
                    },
                  ),
                  IconSlideAction(
                    caption: 'Delete',
                    icon: Icons.delete,
                    onTap: () {
                      _deleteFile(context, index);
                    },
                  )
                ],
              );
            },
            itemCount: files.length,
          ),
        ),
        Container(
          color: Colors.grey,
          height: 60.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0),
                child: Text(_playerTxt),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.play_pause,
                        progress: _animateIcon,
                      ),
                      onPressed: _pausePlayer,
                    ),
                    IconButton(
                      icon: Icon(Icons.stop),
                      onPressed: stopPlayer,
                    ),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.black,
                        inactiveColor: Colors.black,
                        value: playerValue,
                        onChanged: (double val) {
                          _flutterSound.seekToPlayer(val.toInt());
                        },
                        min: 0.0,
                        max: durationValue,
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0),
                child: Text(_duration),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _animationController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 500))
        ..addListener(() {
          setState(() {});
        });
    _animateIcon =
      Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: buildBody()
    );
  }
}
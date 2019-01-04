import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import 'package:shush/audio_encrypter.dart';
import 'package:shush/recents_widget.dart';

void main() => runApp(AppContainer());

class AppContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => new ThemeData(
        primarySwatch: Colors.grey,
        brightness: brightness,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder()
          }
        )
      ),
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: 'Shush',
          home: MyApp(),
          theme: theme
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  static const platform = const MethodChannel('shush_ch');
  FlutterSound _flutterSound = new FlutterSound();
  int _currentIndex = 0;
  Directory tempPath;
  Directory externalPath;
  AnimationController _animationController;
  Animation<Color> _animateColor;
  Animation<Color> _animateColorExpanded;
  StreamSubscription _recorderSubscription;
  String _recorderTxt = '00:00:00';
  bool isRecording = false;

  void initEncrypter() {
    AudioEncrypter.getEncrypter();
  }

  void getPaths() {
    getTemporaryDirectory().then((val) {
      setState(() {
        tempPath = val;
        new Directory('${val.path}/shush').create(recursive: true);
      });
    });

    getExternalStorageDirectory().then((val) {
      setState(() {
        externalPath = val;
      });
    });
  }

  void _onBottomNavigationBarTap(int index) {
    setState(() {
      _currentIndex = index;    
    });
  }

  void _startRecord() async {
    if (!isRecording) {
      _animationController.forward();
      await _flutterSound.startRecorder('${tempPath.path}/sound.mp4');
      _recorderSubscription = _flutterSound.onRecorderStateChanged.listen((e) {
        DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
        String txt = DateFormat('mm:ss:SS', 'en_US').format(date);

        this.setState(() {
          this._recorderTxt = txt.substring(0, 8);
        });
      });
    } else {
      _animationController.reverse();
      _flutterSound.stopRecorder();

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }

      AudioEncrypter.encryptAudioAndWrite(tempPath.path, externalPath.path);
    }
    
    setState(() {
      isRecording = !isRecording;
    });
  }

  Widget getRecordingDisplay(context) {
    if (isRecording) {
      return Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                _recorderTxt,
                style: TextStyle(fontSize: 64.0, fontWeight: FontWeight.bold),
              ),
            )
          ),
          Expanded(
            flex: 3,
            child: SpinKitWave(
              size: 150.0,
              itemBuilder: (context, int index) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.white : Colors.grey,
                  ),
                );
              },
            ),
          )
        ],
      );
    } else {
      return Icon(Icons.hotel, size: 80.0);
    }
  }

  IconData getPlayStopIcon() {
    if (!isRecording) {
      return Icons.play_arrow;
    } else {
      return Icons.stop;
    }
  }

  Widget getRecorderBody() {
    if (_currentIndex == 1) {
      return Recents();
    } else {
      return Container(
        color: _animateColorExpanded.value,
        child: Center(
            child: getRecordingDisplay(context)
        ),
      );
    }
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
    CurvedAnimation _curvedAnimaton = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.easeOut,
      ),
    );
    CurvedAnimation _curvedAnimatonExpanded = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.easeIn,
      ),
    );
    _animateColor = ColorTween(begin: Colors.red, end: Colors.white,).animate(_curvedAnimaton);
    _animateColorExpanded = ColorTween(begin: Colors.white, end: Colors.red).animate(_curvedAnimatonExpanded);
    super.initState();

    getPaths();
    initEncrypter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shush'),
      ),
      body: getRecorderBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), title: Text('Home')),
          BottomNavigationBarItem(icon: Icon(Icons.record_voice_over), title: Text('Recordings'))
        ],
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationBarTap,
        fixedColor: Colors.black87,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _animateColor.value,
        onPressed: () {
          _startRecord();
        },
        child: Icon(getPlayStopIcon())
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
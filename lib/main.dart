import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:encrypt/encrypt.dart';

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
  Directory testPath;
  AnimationController _animationController;
  Animation<Color> _animateColor;
  Animation<Color> _animateColorExpanded;
  StreamSubscription _recorderSubscription;
  String _recorderTxt = '00:00:00';
  bool isRecording = false;
  void getTempPath() async {
    tempPath = await getTemporaryDirectory();
    testPath = await getExternalStorageDirectory();
    await new Directory('${tempPath.path}/shush').create(recursive: true);
  }

  void _onBottomNavigationBarTap(int index) {
    setState(() {
      _currentIndex = index;    
    });
  }

  void _startRecord() async {
    if (!isRecording) {
      _animationController.forward();
      File testFileExists = new File('${tempPath.path}/shush/sound.mp4');
      if (testFileExists.existsSync()) {
        new Directory('${tempPath.path}/shush/sound.mp4').deleteSync(recursive: true);
      }
      await _flutterSound.startRecorder('${tempPath.path}/shush/sound.mp4');
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

      final String res = await platform.invokeMethod('encryptAudio', <String, dynamic>{
        'path': '${tempPath.path}/shush/sound.mp4',
        'data': ''
      });
      print(res);
      final key = 'private!!!!!!!!!private!!!!!!!!!';
      final iv = '8bytesiv';
      final encrypter = new Encrypter(new Salsa20(key, iv));
      final encrypted = encrypter.encrypt(res);
      final decrypted = encrypter.decrypt(encrypted);

      print(decrypted);

      final bool ress = await platform.invokeMethod('createFile', <String, dynamic>{
        'path': '${testPath.path}/shush/sound2.mp4',
        'data': decrypted
      });
      //print(audioString);
      // print(encrypted);
      //print(decrypted);
      // List<int> decryptBytes = base64Decode(audioString);
      // File testSound = new File('${testPath.path}/soundsoundsound.mp4');
      // testSound.writeAsBytesSync(audioBytes);
    }
    
    setState(() {
      isRecording = !isRecording;
    });
  }

  Widget getRecordingDisplay(context) {
    if (isRecording) {
      return Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: Text(
              _recorderTxt,
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SpinKitWave(
              size: 90.0,
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
      return Icon(Icons.hotel, size: 60.0);
    }
  }

  IconData getPlayStopIcon() {
    if (!isRecording) {
      return Icons.play_arrow;
    } else {
      return Icons.stop;
    }
  }

  List<Widget> getRecorderBody(BuildContext context) {
    return <Widget>[
      ListTile(
        title: Text('Recents 1'),
        subtitle: Text('Recorded 01-03-2019'),
        onTap: _tappedRecent,
      ),
      ListTile(
        title: Text('Recents 2'),
        subtitle: Text('Recorded 01-03-2019'),
        onTap: _tappedRecentTwo,
      ),
      ListTile(
        title: Text('Recents 3'),
        subtitle: Text('Recorded 01-03-2019'),
        onTap: _tappedRecentThree,
      ),
      Expanded(
        child: Container(
          color: _animateColorExpanded.value,
          child: Center(
            child: getRecordingDisplay(context)
          ),
        ),
      )
    ];
  }

  void _tappedRecent() async {
    await _flutterSound.startPlayer('${tempPath.path}/shush/sound.mp4');
    await _flutterSound.setVolume(1.0);
  }

  void _tappedRecentTwo() async {
    await _flutterSound.stopPlayer();
  }

  void _tappedRecentThree() async {
    await _flutterSound.startPlayer('${tempPath.path}/shush/soundsoundsound.mp4');
    await _flutterSound.setVolume(1.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void initState() {
    getTempPath();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shush'),
      ),
      body: Column(
        children: getRecorderBody(context),
      ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
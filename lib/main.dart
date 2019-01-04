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
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final secureString = new PlatformStringCryptor();
  Encrypter _encrypter;
  int _currentIndex = 0;
  Directory tempPath;
  Directory externalPath;
  AnimationController _animationController;
  Animation<Color> _animateColor;
  Animation<Color> _animateColorExpanded;
  StreamSubscription _recorderSubscription;
  String _recorderTxt = '00:00:00';
  bool isRecording = false;

  void createShushExternalDirectory(path) {
    new Directory(path).createSync(recursive: true);
  }

  void initEncrypter() async {
    final storage = new FlutterSecureStorage();
    final String ivFromStorage = await storage.read(key: 'ivkey');
    final String keyFromStorage = await storage.read(key: 'salsakey');

    final String iv = ivFromStorage != null ? ivFromStorage : await platform.invokeMethod('generateIv');
    final String key = keyFromStorage != null ? keyFromStorage : await secureString.generateRandomKey();
    _encrypter = new Encrypter(new Salsa20(key, iv));
    print(iv);
    print(key);
    if (ivFromStorage == null) {
      await storage.write(key: 'ivkey', value: iv);
    }

    if (keyFromStorage == null) {
      await storage.write(key: 'salsakey', value: key);
    }
  }

  void getPaths() {
    getTemporaryDirectory().then((val) {
      setState(() {
        tempPath = val;
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
    Directory temporaryDirectory = await getTemporaryDirectory();
    String temporaryPath = temporaryDirectory.path;
    createShushExternalDirectory('$temporaryPath/shush');
    if (!isRecording) {
      _animationController.forward();
      await _flutterSound.startRecorder('$temporaryPath/sound.mp4');
      _recorderSubscription = _flutterSound.onRecorderStateChanged.listen((e) {
        DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
        String txt = DateFormat('mm:ss:SS', 'en_US').format(date);

        this.setState(() {
          this._recorderTxt = txt.substring(0, 8);
        });
      });
    } else {
      Directory externalDirectory = await getExternalStorageDirectory();
      String externalPath = externalDirectory.path;

      _animationController.reverse();
      _flutterSound.stopRecorder();

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }

      final String res = await platform.invokeMethod('fileToByteArray', <String, dynamic>{
        'path': '$temporaryPath/sound.mp4'
      });
      print(res);
      final encrypted = _encrypter.encrypt(res);

      DateTime appendDate = new DateTime.now();
      final pathFileName = '$externalPath/shush/${appendDate.toString()}_recording.shush';
      File testWriteEncryptedValue = new File(pathFileName);
      testWriteEncryptedValue.writeAsString(encrypted);
//      await platform.invokeMethod('createFile', <String, dynamic>{
//        'path': pathFileName,
//        'data': encrypted
//      });
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

  List<Widget> getRecents() {
    List<Widget> recents = [];
    if (externalPath != null) {
      Directory externalShush = Directory('${externalPath.path}/shush');
      var watcher = DirectoryWatcher(externalShush.path);
      watcher.events.listen((event) {
        print(event);
      });
      var filesInFolder = externalShush.listSync();
      for (var shouldBeFile in filesInFolder) {
        if (shouldBeFile is File) {
          String fileName = p.basename(shouldBeFile.path);
          String lastModified = shouldBeFile.lastModifiedSync().toLocal().toString();
          recents.add(ListTile(
            title: Text(fileName),
            subtitle: Text(lastModified),
            onTap: () {
              _tappedAudioItem(fileName);
            },
          ));
        }
      }
    }

    return recents;
  }

  List<Widget> getRecorderBody(BuildContext context) {
    List<Widget> homeBody = [];
    List<Widget> recentWidgets = getRecents();
    homeBody.addAll(recentWidgets);
    homeBody.add(Expanded(
      child: Container(
        color: _animateColorExpanded.value,
        child: Center(
            child: getRecordingDisplay(context)
        ),
      ),
    ));
    return homeBody;
  }

  void _tappedAudioItem(String filename) async {
    File testFile = new File('${externalPath.path}/shush/$filename');
    String encryptedValue = testFile.readAsStringSync();
    String decryptedValue = _encrypter.decrypt(encryptedValue);
    print(decryptedValue);
//    final String res = await platform.invokeMethod('fileToByteArray', <String, dynamic>{
//      'path': '${externalPath.path}/shush/$filename'
//    });
//    String decrypted = _encrypter.decrypt(res);
    final String shushTempFile = '${tempPath.path}/tempshush.mp4';
    await platform.invokeMethod('createFile', <String, dynamic>{
      'path': shushTempFile,
      'data': decryptedValue
    });

    _flutterSound.stopPlayer();
    await _flutterSound.startPlayer(shushTempFile);
    await _flutterSound.setVolume(1.0);
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
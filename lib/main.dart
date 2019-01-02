import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

void main() => runApp(AppContainer());

class AppContainer extends StatelessWidget {
  void getExternalPath() async {
    Directory externalPath = await getExternalStorageDirectory();
    new Directory('${externalPath.path}/shush').create(recursive: true);
  }

  @override
  Widget build(BuildContext context) {
    getExternalPath();
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => new ThemeData(
        primarySwatch: Colors.blue,
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

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Flutter'),
      ),
      body: Center(
        child: Text('Hello World'),
      )
    );
  }
}
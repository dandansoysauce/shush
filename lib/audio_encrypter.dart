import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:intl/intl.dart';

class AudioEncrypter {
  static const _platform = const MethodChannel('shush_ch');
  static final _secureStorage = FlutterSecureStorage();
  static final _secureString = new PlatformStringCryptor();
  static Encrypter _encrypter;

  static void getEncrypter() async {
    
    final String ivFromStorage = await _secureStorage.read(key: 'ivkey');
    final String keyFromStorage = await _secureStorage.read(key: 'salsakey');

    final String iv = ivFromStorage != null ? ivFromStorage : await _platform.invokeMethod('generateIv');
    final String key = keyFromStorage != null ? keyFromStorage : await _secureString.generateRandomKey();
    _encrypter = new Encrypter(new Salsa20(key, iv));
    setKey(key);
    setIv(iv);
  }

  static void encryptAudioAndWrite(String path, String pathToWrite) async {
    final res = await _platform.invokeMethod('fileToByteArray', <String, dynamic>{
      'path': '$path/sound.mp4'
    });
    final encryptedData = _encrypter.encrypt(res);
    writeToFile(pathToWrite, encryptedData);
  }

  static Future<String> decryptAudioAndWrite(String path, String data) async {
    final decryptedValue = _encrypter.decrypt(data);
    final String shushTempFile = '$path/tempshush.mp4';
    await _platform.invokeMethod('createFile', <String, dynamic>{
      'path': shushTempFile,
      'data': decryptedValue
    });

    return shushTempFile;
  }

  static void writeToFile(String path, String encrypted) {
    DateTime appendDate = new DateTime.now();
    var dateFormat = DateFormat('yyyy-MM-dd-s');
    String formatted = dateFormat.format(appendDate);
    final pathFileName = '$path/shush/shush_recording_$formatted';
    File testWriteEncryptedValue = new File(pathFileName);
    testWriteEncryptedValue.writeAsString(encrypted);
  }

  static void setKey(String key) async {
    if (key == null) {
      await _secureStorage.write(key: 'salsakey', value: key);
    }
  }

  static void setIv(String iv) async {
    if (iv == null) {
      await _secureStorage.write(key: 'ivkey', value: iv);
    }
  }
}
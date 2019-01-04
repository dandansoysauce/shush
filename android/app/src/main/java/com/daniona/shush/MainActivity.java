package com.daniona.shush;

import android.os.Bundle;
import android.util.Base64;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.io.*;
import java.security.SecureRandom;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "shush_ch";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
      new MethodCallHandler() {
        @Override
        public void onMethodCall(MethodCall call, Result result) {
          String path = call.argument("path");
          if (call.method.equals("fileToByteArray")) {
            String bytes = fileToByteArray(path);
            result.success(bytes);
          } else if (call.method.equals("createFile")) {
            String data = call.argument("data");
            createFile(path, data);
            result.success(true);
          } else if (call.method.equals("generateIv")) {
            String aesKey = generateIv();
            result.success(aesKey);
          }
        }
      }
    );
  }

  private String generateIv() {
    SecureRandom secureRandom = new SecureRandom();
    String AB = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    StringBuilder sb = new StringBuilder(8);
    for (int i = 0; i < 8; i++) {
      sb.append( AB.charAt(secureRandom.nextInt(AB.length())));
    }

    return sb.toString();
  }

  private String fileToByteArray(String path) {
    File soundFile = new File(path);
    long byteLength = soundFile.length();
    byte[] filecontent = new byte[(int) byteLength];
    try {
      FileInputStream fileInputStream = new FileInputStream(soundFile);
      fileInputStream.read(filecontent, 0, (int) byteLength);
    } catch (Exception e) {
      e.printStackTrace();
    }

    return Base64.encodeToString(filecontent, Base64.DEFAULT);
  }

  private void createFile(String path, String data) {
    File soundFile;
    FileOutputStream fop = null;
    try {
      soundFile = new File(path);
      fop = new FileOutputStream(soundFile);

      if (!soundFile.exists()) {
        soundFile.createNewFile();
      }

      byte[] bytes = Base64.decode(data, Base64.DEFAULT);
      fop.write(bytes);
      fop.flush();
      fop.close();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}

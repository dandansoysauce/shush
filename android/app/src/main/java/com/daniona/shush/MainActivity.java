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
          String data = call.argument("data");
          if (call.method.equals("encryptAudio")) {
            String bytes = encryptAudio(path, data);
            result.success(bytes);
          } else if (call.method.equals("createFile")) {
            createFile(path, data);
            result.success(true);
          }
        }
      }
    );
  }

  private String encryptAudio(String path, String datashit) {
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

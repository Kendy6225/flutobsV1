import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class Flutobs {
  static const MethodChannel _channel = const MethodChannel('flutobs');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> initSDK(
      String key, String secret, String endPoint) async {
    Map map = Map();
    map['appKey'] = key;
    map['appSecret'] = secret;
    map['endPoint'] = endPoint;
    await _channel.invokeMethod("initSDK", map);
  }

  static Future<bool> upload(
    String filePath,
    String bucketName,
    fileName, {
    ValueChanged callback,
  }) async {
    Map map = Map();
    map['filePath'] = filePath;
    map['bucketname'] = bucketName;
    map['objectname'] = fileName;
    _channel.setMethodCallHandler((call) async {
      if (call.method == "progress") {
        if (callback != null) {
          callback(call.arguments);
        }
        print('${call.arguments}');
      }
    });
    return await _channel.invokeMethod("upload", map);
  }
}

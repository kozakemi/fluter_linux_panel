import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class WiFiService {
  static const MethodChannel _channel = MethodChannel('wifi_control');

  static Future<bool> enable(bool enable) async {
    if (kIsWeb) {
      // Web 预览下返回成功，并模拟状态
      return true;
    }
    final bool ok = await _channel.invokeMethod<bool>(
          'enable',
          {'enable': enable},
        ) ??
        false;
    return ok;
  }

  static Future<Map<String, dynamic>> status() async {
    if (kIsWeb) {
      return {
        'enabled': true,
        'ssid': 'ZTE-f6S6uY',
      };
    }
    final Map<dynamic, dynamic> res = await _channel.invokeMethod('status');
    return Map<String, dynamic>.from(res);
  }

  static Future<List<Map<String, dynamic>>> scan() async {
    if (kIsWeb) {
      // 模拟若干热点
      return [
        {'ssid': 'CMCC-tg5f', 'security': 'WPA2', 'signal': '80'},
        {'ssid': 'CMCC-m5kf', 'security': 'WPA2', 'signal': '65'},
        {'ssid': 'Wireless_cn2', 'security': '--', 'signal': '50'},
      ];
    }
    final List<dynamic> res = await _channel.invokeMethod('scan');
    return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<bool> connect(String ssid, String password) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    }
    final Map<dynamic, dynamic> res = await _channel.invokeMethod(
      'connect',
      {
        'ssid': ssid,
        'password': password,
      },
    );
    return (res['ok'] as bool?) ?? false;
  }
}
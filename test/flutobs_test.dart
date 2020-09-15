import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutobs/flutobs.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutobs');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Flutobs.platformVersion, '42');
  });
}

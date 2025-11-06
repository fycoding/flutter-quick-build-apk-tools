import 'dart:convert';
import 'dart:io';

import 'package:cli/cli.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  String sdkPath = r'F:\projects\flutter-quick-build-apk-tools\sdk';
  // await run("java", ["--version"], sdkPath);
  // await run("echo", ["%ANDROID_SDK_ROOT%"], sdkPath);

  // await run("flutter", [
  //   "config",
  //   "--android-sdk",
  //   "$sdkPath\\android",
  // ], sdkPath);
  await run("flutter", ["doctor", "-v"], sdkPath);
}

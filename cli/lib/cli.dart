import 'dart:convert';
import 'dart:io';
import "package:fast_gbk/fast_gbk.dart";

Future<int> run(String command, List<String> args, String sdkPath) async {
  var paths = [
    "$sdkPath/flutter/bin",
    "$sdkPath/java/bin",
    "$sdkPath/android/bin",
    r"C:\Windows\System32",
  ];
  Process process = await Process.start(
    command, // 命令
    args, // 参数
    environment: {
      'PATH': paths.join(";"),
      "ANDROID_SDK_ROOT": "$sdkPath\\android",
      "PUB_HOSTED_URL": "https://pub.flutter-io.cn",
    },
    runInShell: true,
  );

  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
  });

  process.stderr.transform(gbk.decoder).listen((data) {
    print(data);
  });
  // 等待进程结束
  return await process.exitCode;
}

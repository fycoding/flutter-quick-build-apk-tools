import 'dart:convert';
import 'dart:io';
import "package:fast_gbk/fast_gbk.dart";

// 构建apk
Future<void> buildAPK(String src) async {
  run("flutter", ["clean"], pwd: src);
  run("flutter", ["build", "apk"], pwd: src);
}

// 执行命令
Future<int> run(String command, List<String> args, {String? pwd}) async {
  var sdkPath = _getSdkPath();
  var paths = [
    "$sdkPath/flutter/bin",
    "$sdkPath/java/bin",
    "$sdkPath/android/bin",
    r"C:\Windows\System32",
    r"C:\Windows\System32\WindowsPowerShell\v1.0",
  ];
  Process process = await Process.start(
    command, // 命令
    args, // 参数
    environment: {
      'PATH': paths.join(";"),
      "ANDROID_SDK_ROOT": "$sdkPath\\android",
      "JAVA_HOME": "$sdkPath\\java",
      "PUB_HOSTED_URL": "https://pub.flutter-io.cn",
    },
    runInShell: true,
    workingDirectory: pwd,
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

String _getSdkPath() {
  // 从 CLI_SDK_PATH 中读取
  var path = Platform.environment['CLI_SDK_PATH'];
  // 没有的话读取相对目录
  path ??= "${Platform.script.resolve('.').toFilePath()}../../sdk";
  return path;
}

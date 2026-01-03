import 'dart:convert';
import 'dart:io';
import 'package:cli/modify/modify.dart';
import 'package:cli/modify/modify_item1.dart';
import 'package:cli/modify/modify_item2.dart';
import "package:fast_gbk/fast_gbk.dart";

var needModifyFiles = [
  r"android\app\build.gradle",
  r"android\app\src\main\AndroidManifest.xml",
  r"android\app\src\main\AndroidManifest-china.xml",
  r"lib\yk_bb\configuration_sdk.dart",
];
var iconSrcPath = r"android\app\src\main\res\mipmap-hdpi\ic_launcher";
var appPath = r"build\app\outputs\flutter-apk\app-release.apk";

// 构建apk
Future<void> buildAPK(
  String src,
  String? appID,
  String? name,
  String? iconPath,
  String? out,
  String? appOrg, {
  required String type,
}) async {
  final logFile = File(
    '${_getSdkPath()}/../logs/${_getFormattedTimestamp()}.log',
  );

  Modify? modify;
  logFile.parent.createSync(recursive: true);
  // 选择修改器
  modify = getModifyInstance(
    type: type,
    src: src,
    sdkPath: _getSdkPath(),
    appId: appID ?? "",
    name: name ?? "",
    appOrg: appOrg ?? "",
    iconPath: iconPath ?? "",
  );
  // 配置
  _config();
  // 创建备份
  modify.backup();
  // 修改文件
  modify.modify();
  // 清理缓存
  await clean(src);
  // 执行打包命令
  await run(
    "flutter",
    ["build", "apk", "--release"],
    pwd: src,
    onStdOut: (data) {
      logFile.writeAsStringSync('$data\n', mode: FileMode.append);
    },
    onStdErr: (data) {
      logFile.writeAsStringSync('[ERROR] $data\n', mode: FileMode.append);
    },
  );
  copyApk(src, out);
  // 还原备份文件
  modify.restore();
}

Modify getModifyInstance({
  required String type,
  required String src,
  required String sdkPath,
  required String appId,
  required String name,
  required String appOrg,
  required String iconPath,
}) {
  switch (type) {
    case "fultter01":
      return ModifyItem1(
        src: src,
        sdkPath: sdkPath,
        appId: appId,
        name: name,
        appOrg: appOrg,
        iconPath: iconPath,
      );
    case "fultter02":
      return ModifyItem2(
        src: src,
        sdkPath: sdkPath,
        appId: appId,
        name: name,
        appOrg: appOrg,
        iconPath: iconPath,
      );
    default:
      throw Exception("未知的修改类型: $type");
  }
}

// 检查环境
Future<void> doctor() async {
  _config();
  run("flutter", ["doctor", "-v"]);
}

Future<void> license() async {
  run("flutter", ["doctor", "--android-licenses"]);
}

// 清理
Future<void> clean(String src) async {
  print("清理成功");
  await run("flutter", ["clean"], pwd: src);
}

void copyApk(String src, String? targetPath) {
  print(targetPath);
  if (targetPath == null) return;
  final sourceFile = File("$src/$appPath");
  if (sourceFile.existsSync()) {
    sourceFile.copySync("$targetPath/app-release.apk");
  }
}

Future<void> _config() async {
  run("flutter", ["config", "--jdk-dir", _getJavaHome()]);
  run("flutter", ["config", "--list"]);
}

String _getJavaHome() {
  return "${_getSdkPath()}/java";
}

// 执行命令
Future<int> run(
  String command,
  List<String> args, {
  String? pwd,
  Function(String)? onStdOut,
  Function(String)? onStdErr,
}) async {
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
      "JAVA_HOME": _getJavaHome(),
      "PUB_HOSTED_URL": "https://pub.flutter-io.cn",
      "FLUTTER_STORAGE_BASE_URL": "https://storage.flutter-io.cn",
    },
    runInShell: true,
    workingDirectory: pwd,
  );

  process.stdout.transform(utf8.decoder).listen((data) {
    print(data);
    onStdOut?.call(data);
  });

  process.stderr.transform(gbk.decoder).listen((data) {
    print(data);
    onStdErr?.call(data);
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

// 格式化时间戳
String _getFormattedTimestamp() {
  final now = DateTime.now();
  return '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}_${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

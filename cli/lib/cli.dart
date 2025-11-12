import 'dart:convert';
import 'dart:io';
import "package:fast_gbk/fast_gbk.dart";
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

var needModifyFiles = [
  r"android\app\build.gradle",
  r"android\app\src\main\AndroidManifest.xml",
  r"android\app\src\main\AndroidManifest-china.xml",
  r"lib\yk_bb\configuration_sdk.dart",
];
var iconSrcPath = r"android\app\src\main\res\mipmap-hdpi\ic_launcher.png";
var appPath = r"build\app\outputs\flutter-apk\app-release.apk";

// 构建apk
Future<void> buildAPK(
  String src,
  String? appID,
  String? name,
  String? iconPath,
  String? out,
  String? appOrg,
) async {
  final logFile = File(
    '${_getSdkPath()}/../logs/${_getFormattedTimestamp()}.log',
  );
  logFile.parent.createSync(recursive: true);
  // 配置
  _config();
  // 创建备份
  backup(src);
  // 修改文件
  modify(src, appID, name, appOrg);
  // 修改icon
  replaceIcon(src, iconPath);
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
  restore(src);
}

void replaceIcon(String src, String? iconPath) {
  if (iconPath != null) {
    _replaceImage(iconPath, "$src/$iconSrcPath");
  }
}

Future<void> _replaceImage(String imageUrl, String targetImagePath) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      // 解码图片
      final image = img.decodeImage(response.bodyBytes);
      if (image == null) return;

      // 编码为PNG
      final pngBytes = img.encodePng(image);

      // 写入文件
      final file = File(targetImagePath);
      await file.writeAsBytes(pngBytes);
    }
  } catch (e) {
    print('下载或转换图片失败: $e');
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
  run("flutter", ["clean"], pwd: src);
}

// 备份文件
void backup(String src) {
  for (var file in needModifyFiles) {
    _backupFile("$src/$file");
  }
}

// 恢复备份
void restore(String src) {
  for (var file in needModifyFiles) {
    _restoreBackup("$src/$file");
  }
}

// 修改文件
void modify(String src, String? appId, String? name, String? appOrg) {
  if (appId != null) {
    _replaceApplicationId("$src/${needModifyFiles[0]}", appId);
    _replaceApplicationIdForDartSrc(
      "$src/${needModifyFiles[3]}",
      appId,
      name,
      appOrg,
    );
  }
  if (name != null) {
    _replaceAppLabel("$src/${needModifyFiles[1]}", name);
    _replaceAppLabel("$src/${needModifyFiles[2]}", name);
  }
}

void _replaceAppLabel(String filePath, String newLabel) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  final updatedContent = content.replaceAll(
    RegExp(r'android:label="[^"]*"'),
    'android:label="$newLabel"',
  );

  file.writeAsStringSync(updatedContent);
}

void copyApk(String src, String? targetPath) {
  print(targetPath);
  if (targetPath == null) return;
  final sourceFile = File("$src/$appPath");
  if (sourceFile.existsSync()) {
    sourceFile.copySync("$targetPath/app-release.apk");
  }
}

void _replaceApplicationIdForDartSrc(
  String filePath,
  String newApplicationId,
  String? appName,
  String? appOrg,
) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  var updatedContent = content.replaceAll(
    RegExp(r"packageName\s+=\s+'.*?'"),
    'packageName="$newApplicationId"',
  );
  if (appName != null) {
    updatedContent = updatedContent.replaceAll(
      RegExp(r"appName\s+=\s+'.*?'"),
      'packageName="$appName"',
    );
  }
  if (appName != null) {
    updatedContent = updatedContent.replaceAll(
      RegExp(r"appOrganization\s+=\s+'.*?'"),
      'packageName="$appOrg"',
    );
  }

  file.writeAsStringSync(updatedContent);
}

void _replaceApplicationId(String filePath, String newApplicationId) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final content = file.readAsStringSync();
  final updatedContent = content.replaceAll(
    RegExp(r'applicationId\s+".*?"'),
    'applicationId "$newApplicationId"',
  );

  file.writeAsStringSync(updatedContent);
}

// 创建备份文件
void _backupFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final backupFile = File('$filePath.bak');
  backupFile.writeAsBytesSync(file.readAsBytesSync());
}

// 还原备份文件
void _restoreBackup(String filePath) {
  final backupFile = File('$filePath.bak');
  if (!backupFile.existsSync()) return;

  final originalFile = File(filePath);
  if (originalFile.existsSync()) {
    originalFile.deleteSync(); // 删除原文件
  }
  backupFile.renameSync(filePath); // 重命名备份文件为原文件
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

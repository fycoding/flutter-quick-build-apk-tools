import 'dart:io';

import 'package:cli/modify/modify.dart';
import 'package:cli/modify/utils.dart';

class ModifyItem2 extends Modify {
  String src;
  String sdkPath;
  String appId;
  String name;
  String appOrg;
  String iconPath;

  ModifyItem2({
    required this.src,
    required this.sdkPath,
    required this.appId,
    required this.name,
    required this.appOrg,
    required this.iconPath,
  });

  var needModifyFiles = [
    r"android\app\build.gradle", // 签名
    r"android\app\src\main\AndroidManifest.xml", // 包名、应用名
    r"lib\utils\configuration.dart", // 配置文件
  ];
  // icon
  var iconSrcPath = r"android\app\src\main\res\mipmap-hdpi\ic_launcher";

  @override
  void backup() {
    for (var file in needModifyFiles) {
      backupFile("$src/$file");
    }
  }

  @override
  void modify() async {
    var fileKeyProperties = File("$src/android/key.properties");
    if (!fileKeyProperties.existsSync()) {
      File('$sdkPath/key2/key.properties').copy("$src/android/key.properties");
      print("复制key.properties成功");
    } else {
      print("key.properties已存在，跳过");
    }
    // 签名需要
    await replaceFileWithCopyDelete(
      sourcePath: '$sdkPath/key2/build.gradle',
      destinationPath: "$src/${needModifyFiles[0]}",
    );
    _replaceApplicationId("$src/${needModifyFiles[0]}", appId);
    // 替换包名和应用名
    _replaceAppLabel("$src/${needModifyFiles[1]}", name);
    replaceTextByRegExp(
      filePath: "$src/${needModifyFiles[2]}",
      text: "androidId = '$appId'",
      regExp: RegExp(r"(androidId\s+=\s+')(.*?)(')"),
    );
    // 替换ICON
    _replaceIcon(src, iconPath);
  }

  void _replaceApplicationId(String filePath, String newApplicationId) {
    replaceTextByRegExp(
      filePath: filePath,
      text: r'${1}aa.fycoding.com${3}',
      regExp: RegExp(r'(applicationId\s+")(.*?)(")'),
    );
  }

  @override
  void restore() {
    for (var file in needModifyFiles) {
      restoreBackup("$src/$file");
    }
  }

  void _replaceAppLabel(String filePath, String newLabel) {
    replaceTextByRegExp(
      filePath: filePath,
      text: 'android:label="$newLabel"',
      regExp: RegExp(r'(android:label=")(.*?)(")'),
    );
  }

  void _replaceIcon(String src, String? iconPath) {
    if (iconPath != null) {
      replaceImage(iconPath, "$src/$iconSrcPath");
    }
  }
}

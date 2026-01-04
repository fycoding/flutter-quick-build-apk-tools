import 'dart:io';

import 'package:cli/modify/modify.dart';
import 'package:cli/modify/utils.dart';

class ModifyItem1 extends Modify {
  String src;
  String sdkPath;
  String appId;
  String name;
  String appOrg;
  String iconPath;

  var needModifyFiles = [
    r"android\app\build.gradle",
    r"android\app\src\main\AndroidManifest.xml",
    r"android\app\src\main\AndroidManifest-china.xml",
    r"lib\yk_bb\configuration_sdk.dart",
  ];
  var iconSrcPath = r"android\app\src\main\res\mipmap-hdpi\ic_launcher";

  ModifyItem1({
    required this.src,
    required this.sdkPath,
    required this.appId,
    required this.name,
    required this.appOrg,
    required this.iconPath,
  });

  @override
  void backup() {
    for (var file in needModifyFiles) {
      backupFile("$src/$file");
    }
  }

  @override
  void restore() {
    for (var file in needModifyFiles) {
      restoreBackup("$src/$file");
    }
  }

  @override
  Future<void> modify() async {
    var fileKeyProperties = File("$src/android/key.properties");
    if (!fileKeyProperties.existsSync()) {
      File('$sdkPath/key1/key.properties').copy("$src/android/key.properties");
      print("复制key.properties成功");
    } else {
      print("key.properties已存在，跳过");
    }

    // 替换文件
    await replaceFileWithCopyDelete(
      sourcePath: '$sdkPath/key1/build.gradle',
      destinationPath: "$src/${needModifyFiles[0]}",
    );
    // 修改文件
    _replaceApplicationId("$src/${needModifyFiles[0]}", appId);
    _replaceApplicationIdForDartSrc(
      "$src/${needModifyFiles[3]}",
      appId,
      name,
      appOrg,
    );
    _replaceAppLabel("$src/${needModifyFiles[1]}", name);
    _replaceAppLabel("$src/${needModifyFiles[2]}", name);

    replaceIcon(src, iconPath);
  }

  void replaceIcon(String src, String? iconPath) {
    if (iconPath != null) {
      replaceImage(iconPath, "$src/$iconSrcPath");
    }
  }

  void _replaceAppLabel(String filePath, String newLabel) {
    replaceTextByRegExp(
      filePath: filePath,
      text: 'android:label="$newLabel"',
      regExp: RegExp(r'(android:label=")(.*?)(")'),
    );
  }

  void _replaceApplicationId(String filePath, String newApplicationId) {
    replaceTextByRegExp(
      filePath: filePath,
      text: 'applicationId "$newApplicationId"',
      regExp: RegExp(r'(applicationId\s+")(.*?)(")'),
    );
  }

  void _replaceApplicationIdForDartSrc(
    String filePath,
    String newApplicationId,
    String? appName,
    String? appOrg,
  ) {
    replaceTextByRegExp(
      filePath: filePath,
      text: "packageName = '$newApplicationId'",
      regExp: RegExp(r"(packageName\s+=\s+')(.*?)(')"),
    );
    if (appName != null) {
      replaceTextByRegExp(
        filePath: filePath,
        text: "appName = '$appName'",
        regExp: RegExp(r"(appName\s+=\s+')(.*?)(')"),
      );
    }
    if (appOrg != null) {
      replaceTextByRegExp(
        filePath: filePath,
        text: "appOrganization = '$appOrg'",
        regExp: RegExp(r"(appOrganization\s+=\s+')(.*?)(')"),
      );
    }
  }
}

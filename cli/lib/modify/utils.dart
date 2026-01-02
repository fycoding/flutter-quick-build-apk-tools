import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// 备份文件
void backupFile(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  final backupFile = File('$filePath.bak');
  backupFile.writeAsBytesSync(file.readAsBytesSync());
}

void restoreBackup(String filePath) {
  final backupFile = File('$filePath.bak');
  if (!backupFile.existsSync()) return;

  final originalFile = File(filePath);
  if (originalFile.existsSync()) {
    originalFile.deleteSync(); // 删除原文件
  }
  backupFile.renameSync(filePath); // 重命名备份文件为原文件
}

void replaceTextByRegExp({
  required String filePath,
  required String text,
  required RegExp regExp,
}) {
  final file = File(filePath);
  if (!file.existsSync()) return;

  if (text.isEmpty) return;

  final content = file.readAsStringSync();

  String updatedContent;

  if (text.contains(RegExp(r'\$\{?\d+\}?'))) {
    // 使用 replaceAllMapped 处理捕获组引用
    updatedContent = content.replaceAllMapped(regExp, (Match match) {
      String result = text;

      // 替换 ${1}, ${2}, ... 或 $1, $2, ...
      for (int i = 0; i <= match.groupCount; i++) {
        final groupValue = match.group(i) ?? '';
        result = result.replaceAll('\${$i}', groupValue);
        // 使用正则表达式替换 $1, $2, ...
        result = result.replaceAllMapped(
          RegExp(r'\$' + i.toString() + r'(?!\d)'),
          (_) => groupValue,
        );
      }

      return result;
    });
  } else {
    updatedContent = content.replaceAll(regExp, text);
  }

  file.writeAsStringSync(updatedContent);
}

Future<void> replaceImage(String imageUrl, String targetImagePath) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      // 解码图片
      final image = img.decodeImage(response.bodyBytes);
      if (image == null) {
        print("icon下载失败");
        return;
      }
      // 删除
      if (File('$targetImagePath.png').existsSync()) {
        File('$targetImagePath.png').deleteSync();
        print("删除原icon成功");
      }
      if (File('$targetImagePath.jpg').existsSync()) {
        File('$targetImagePath.jpg').deleteSync();
        print("删除原icon成功");
      }
      // 编码为PNG
      final pngBytes = img.encodePng(image);
      // 写入文件
      final file = File('$targetImagePath.png');
      await file.writeAsBytes(pngBytes);
    }
  } catch (e) {
    print('下载或转换图片失败: $e');
  }
}

// 替换文件
Future<void> replaceFileWithCopyDelete({
  required String sourcePath,
  required String destinationPath,
}) async {
  final sourceFile = File(sourcePath);
  final destinationFile = File(destinationPath);

  // 检查源文件是否存在
  if (!await sourceFile.exists()) {
    throw FileSystemException('源文件不存在: $sourcePath');
  }

  // 删除目标文件（如果存在）
  if (await destinationFile.exists()) {
    await destinationFile.delete();
    print('已删除目标文件: $destinationPath');
  }

  // 复制源文件到目标位置
  await sourceFile.copy(destinationPath);
  print('文件已替换: $destinationPath');
}

import 'dart:io';

class Logger {
  static String? _logDirectory;

  /// 记录日志
  static void log(String message) {
    try {
      final logFile = _getLogFile();
      final timestamp = DateTime.now().toString().substring(0, 19);
      final logMessage = '[$timestamp] $message\n';

      logFile.writeAsStringSync(logMessage, mode: FileMode.append);
      print(logMessage.trim()); // 同时在控制台输出
    } catch (e) {
      print('❌ 写入日志失败: $e');
    }
  }

  /// 获取日志文件
  static File _getLogFile() {
    // 初始化日志目录
    _logDirectory ??= _initLogDirectory();

    // 生成日志文件名（年月日）
    final now = DateTime.now();
    final fileName =
        '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}.log';

    return File('$_logDirectory/$fileName');
  }

  /// 初始化日志目录
  static String _initLogDirectory() {
    // 获取当前脚本所在目录
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final logDir = Directory('${scriptDir.path}/logs');

    // 创建日志目录（如果不存在）
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }

    return logDir.path;
  }

  /// 两位数格式化
  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:cli/cli.dart';
import 'package:cli/logger.dart';

class FileScanner {
  Timer? _timer;
  bool _isScanning = false;
  Completer<void>? _currentScanCompleter;

  void start({int intervalSeconds = 60}) {
    var directory = Platform.environment["SCAN_DIRECTORY"];
    if (directory == null || directory.isEmpty) {
      _log('环境变量 SCAN_DIRECTORY 未设置');
      return;
    }
    _log('开始扫描目录: $directory');
    _log('扫描间隔: $intervalSeconds秒');
    _log('按 Ctrl+C 停止\n');

    // 定时扫描
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _scheduleScan(directory);
    });

    // 立即执行一次扫描
    _scheduleScan(directory);
  }

  Future<void> _scheduleScan(String directoryPath) async {
    if (_isScanning) {
      return;
    }

    _isScanning = true;
    _currentScanCompleter = Completer<void>();

    try {
      await _scanDirectory(directoryPath);
      _currentScanCompleter?.complete();
    } catch (e) {
      _currentScanCompleter?.completeError(e);
    } finally {
      _isScanning = false;
      _currentScanCompleter = null;
    }
  }

  Future<void> _scanDirectory(String directoryPath) async {
    _log("目标目录：$directoryPath");
    final directory = Directory(directoryPath);

    if (!directory.existsSync()) {
      _log('目录不存在: $directoryPath');
      return;
    }

    try {
      _log('[${DateTime.now().toString().substring(11, 19)}] 扫描文件...');

      final files = directory.listSync();

      for (var entity in files) {
        if (entity is Directory) {
          final absolutePath = entity.absolute.path;
          await _readConfigFile(absolutePath);
        }
      }
    } catch (e) {
      _log('扫描出错: $e\n');
    }
  }

  void stop() {
    _timer?.cancel();
    _log('扫描器已停止');
  }

  void _log(String msg) {
    print(msg);
    Logger.log(msg);
  }

  Future<void> _readConfigFile(String directoryPath) async {
    final configFile = File('$directoryPath/config.json');
    final apkFile = File('$directoryPath/app-release.apk');

    if (apkFile.existsSync()) {
      _log('已经构建完成，跳过');
      return;
    }

    if (!configFile.existsSync()) {
      _log('config.json 文件不存在');
      return;
    }

    try {
      final content = configFile.readAsStringSync();
      final jsonData = jsonDecode(content);
      if (jsonData['status'] == -1) {
        _log("构建失败，需手动处理，跳过");
        return;
      }
      _log("开始构建apk");
      await buildAPK(
        jsonData["src"],
        jsonData["appid"],
        jsonData["name"],
        jsonData["icon"],
        directoryPath,
      );
      if (!apkFile.existsSync()) {
        _log("构建失败");
        jsonData['status'] = -1;
      } else {
        _log("构建成功");
        jsonData['status'] = 1;
      }
      // 回写
      final updatedContent = jsonEncode(jsonData);
      configFile.writeAsStringSync(updatedContent);
      _log("执行完成");
    } catch (e) {
      _log('读取 config.json 失败: $e');
    }
  }
}

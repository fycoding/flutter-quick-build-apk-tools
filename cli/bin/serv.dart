import 'dart:io';

import 'package:cli/scanner.dart';

void main(List<String> args) {
  // 从参数获取目录，默认为当前目录
  final scanner = FileScanner();

  // 处理退出信号
  ProcessSignal.sigint.watch().listen((_) {
    scanner.stop();
    exit(0);
  });

  // 启动扫描
  scanner.start();
}

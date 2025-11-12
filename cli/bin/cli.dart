import 'package:args/args.dart';
import 'package:cli/cli.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();
  parser
    ..addOption("src", help: "源码目录", valueHelp: "path")
    ..addOption("out", help: "apk输出目录", valueHelp: "path")
    ..addOption("appid", help: "apk applicationId", valueHelp: "string")
    ..addOption("name", help: "apk的名字", valueHelp: "string")
    ..addOption("app-org", help: "apk的组织", valueHelp: "string")
    ..addOption("icon", help: "apk icon路径", valueHelp: "path")
    ..addFlag('doctor', help: "检查环境", defaultsTo: false, negatable: false)
    ..addFlag('license', help: "android证书", defaultsTo: false, negatable: false)
    ..addFlag('clean', help: "清理", defaultsTo: false, negatable: false)
    ..addFlag(
      "help",
      abbr: "h",
      help: "帮助文档",
      defaultsTo: false,
      negatable: false,
    );
  try {
    final argResults = parser.parse(arguments);
    // 处理帮助信息
    if (argResults['help']) {
      print('用法: cli --src=<path> ');
      print(parser.usage);
      return;
    }
    // 检查环境
    if (argResults['license']) {
      license();
      return;
    }
    // 检查环境
    if (argResults['doctor']) {
      doctor();
      return;
    }
    // 清理环境
    if (argResults['clean']) {
      if (argResults['src'] == null) {
        print("必须传入源码目录src");
        return;
      }
      clean(argResults['src']);
      return;
    }
    // 执行打包命令
    if (argResults['src'] != null) {
      buildAPK(
        argResults['src'],
        argResults["appid"],
        argResults["name"],
        argResults["icon"],
        argResults["out"],
        argResults["app-org"],
      );
      return;
    }
    print('用法: cli --src=<path> ');
    print(parser.usage);
  } on FormatException catch (e) {
    print('参数错误: ${e.message}');
    print('使用 --help 查看用法');
  }
}

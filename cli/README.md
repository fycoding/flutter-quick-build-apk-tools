A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`.
# 打包
## 构建命令
dart compile exe bin/cli.dart
## 构建服务
dart compile exe bin/serv.dart


# windows注册服务
## 不是服务程序，需要特殊处理
sc create packing binPath= "D:\package\bin\serv.exe"

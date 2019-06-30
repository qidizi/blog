# mac系统中安装telnet

* 在新版本的系统中，比如10.14.5 (18F132)，是没有telnet工具的，下面是通过源码编译的方式安装这些工具

1. 从网站 `http://www.gnu.org/software/inetutils/` 选择任何下载源，下载最新的版本，比如我没注意下载了inetutils-1.4.0.tar.gz，在make时，提示c文件用法错误无法编译，最后下载inetutils-1.9.4.tar.gz才能编译成功的；
1. 解压，比如`/-/inetutils`
1. 切换进入目录`cd /-/inetutils`
1. 执行`bash ./configure --prefix=/-/inetutils/qidizi/`配置，这个prefix是设定安装目录为这个路径，而不是默认的，执行`bash ./configure --help`可以查看你想改进的选项都有什么
1. 编译`make`
1. 安装 `make install`
1. 使用`/-/inetutils/qidizi/bin/telnet --help`


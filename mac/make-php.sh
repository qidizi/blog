#!/bin/sh
myDir="/-/soft/php";

# exit2fail 上个命令退出值   退出提示[操作失败]   退出码[1]
function exit2fail () {
    if [[ "$1" -ne "0" ]];then
        if [[ -z "$2" ]];then
            echo "操作失败";
        else
            echo "$2";
        fi

        if [[ -z "$3" ]];then 
            exit 1;
        else
            exit $3;
        fi
    fi
}

# 目录不存在就退出，参数1为目录路径
function exit2notDir() {
    if [[ ! -d  "${1}" ]];then
        echo "目录 [${1}] 不存在";
        exit 2;
    fi }


exit2notDir "$myDir"
cd $myDir
echo "清空旧编译"
make clean
echo "配置 ${myDir}"
qidizi="${myDir}/qidizi"
bash configure \
--prefix=${qidizi} \
--with-config-file-path=${qidizi}/etc \
--enable-fpm \
--disable-short-tags  \
--disable-ipv6 \
--enable-bcmath  \
--enable-mbstring \
--enable-zip \
--with-bz2=/-/soft/bzip2/qidizi \
--with-zlib=/-/soft/zlib/qidizi/ \
--enable-mysqlnd \
--with-mysql=mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-mcrypt="${myDir}/../libmcrypt/qidizi" \
--enable-sockets  \
--enable-debug \
--with-mhash \
--with-curl="${myDir}/../curl/qidizi" \
--with-openssl="${myDir}/../openssl/qidizi" \
--with-gd \
--with-png-dir="${myDir}/../libpng/qidizi" \
--enable-gd-native-ttf \
--with-jpeg-dir="${myDir}/../jpeg-6b/qidizi" \
--with-iconv-dir="${myDir}/../libiconv/qidizi" \
--with-freetype-dir="${myDir}/../freetype/qidizi" \
 --enable-shmop \
 --enable-sysvsem --enable-sysvshm --enable-sysvmsg \
--without-iconv 

# 目前iconv还不能编译

exit2fail $?
echo -e "\n\n 配置成功！\n\n"
make
exit2fail $?
echo -e "\n\n 编译成功 \n\n"
make install
exit2fail $?
echo -e "\n\n\n ${myDir} build成功"
echo -e "\n\n 如果需要请通过 ./php/qidizi/bin/pecl install redis 安装redis"

# jpeg-6b 编译时，需要手工创建build目录，和手工copy根src目录的h文件到build.d/include，和手工复制到*.a到build.d/lib

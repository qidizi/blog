#!/bin/sh

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
    fi
}


    
#有些系统默认不安装realpath命令,这里自己实现,shell的function返回字符中只能echo,然后调用时通过re=$(realPath 'kkk')来获得
function realPath() {
    if [[ -z $1 ]];then
        return 1;
    fi

    #得到当前文件的绝对路径,()会fork一个subshell,所以,cd并不会影响parentShell的pwd
    realPath="$(cd `dirname ${1}`; pwd)/$(basename ${1})";
    echo ${realPath};
    return 0;
}


exit2fail $? "第1个参数指定要编译源代码的configure"
src=$(realPath $1)
# 删除第一个参数
shift

if [[ ! -f "$src" ]];then
    echo "请使用绝对路径在第一个参数指定configure，当前的指定 【${src}】 无效"
    exit 1
fi


dir=$(dirname $src)
cd $dir
echo "尝试清理..."
make clean
echo "尝试配置..."
bash $src --prefix="${dir}/qidizi" $@
exit2fail $? "配置失败"
echo "尝试编译..."
make
exit2fail $? "编译失败"
echo "尝试安装..."
make install
exit2fail $? "安装失败"
echo "全部操作成功"

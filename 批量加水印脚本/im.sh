#!/bin/bash

# 批量对指定目录下图片(不支持子目录)调整大小,添加水印
# 操作方法:运行本脚本,把待处理目录拖入后回车即可
# 脚本仅支持类unix环境,window可以安装bash环境来使用

# ----config-----
# 主流2K分辨率为2560x1440
# 若某边超出这个值,就会进行缩小
max_width=2560
max_height=1440
#----config-----

#有些系统默认不安装realpath命令,这里自己实现,shell的function返回字符中只能echo,然后调用时通过re=$(realPath 'kkk')来获得
function realPath() {
    #得到当前文件的绝对路径,()会fork一个subshell,所以,cd并不会影响parentShell的pwd
    realPath=$(cd `dirname "${1}"`; pwd)
    name=$(basename "${1}");
    realPath="${realPath}/${name}"
    realPath="${realPath//\/\//\/}";
    realPath="${realPath//\/.\//\/}";
    echo "${realPath}"
    return 0;
}

sh_path=$(realPath "$0")
sh_dir=$(dirname "${sh_path}")

if [[ "${sh_path//*\"*/}" = "" || "${sh_path//*\'*/}" = "" ]];then
    echo "本脚本路径不允许出现单(双)引号"
    exit
fi

sys=$(uname -s)

# 如果是mac os
if [[ "${sys}" = "Darwin" ]];then
    # mac版本imagemagick需要指定im目录(解压目录即是)和lib(解压目录下的lib即是)
    export MAGICK_HOME="/Users/qidizi/Desktop/im/";
    export DYLD_LIBRARY_PATH="/Users/qidizi/Desktop/im/lib/";
    magick="/Users/qidizi/Desktop/im/bin/magick"
elif [[ "${sys:0:5}" = "MINGW" || "${sys:0:4}" = "MSYS" || "${sys:0:5}" = "MSYS2" || "${sys:0:6}" = "Cygwin"  ]];then
	# window + bash
	magic="${sh_dir}/magick.exe"
elif [[ "${sys}" = "Linux" ]];then
    # linux 像centos 通过yum安装后它的可执行文件名就叫magick
    magick=$(which magick)

    if [[ "$?" -ne "0" ]];then
        echo "图片处理命令未安装,请访问 https://imagemagick.org/script/download.php 安装"
        exit
    fi
else
    echo "未明环境，脚本无法执行"
    exit
fi

if [[ ! -x "${magick}" ]];then
   echo "图片处理命令未安装,请访问 https://imagemagick.org/script/download.php 安装"
   exit
fi

ttf="${sh_dir}/free.ttf";
water_text="${sh_dir}/water_text.txt";

if [[ ! -f "${ttf}" ]];then
    echo "水印需要的字体文件 ${ttf} 不存在"
    exit
fi

if [[ ! -f "${water_text}" ]];then
    echo "水印文字文件 ${water_text} 不存在"
    exit
fi

echo "↓ 在目录中放入待加水印的JPG或是PNG图片(不支持子目录);"
echo "↓ 把该目录拖至此窗口后放开;"
echo "↓ 回车等待处理结果;"
echo "请操作:"
read src_dir;
src_dir=$(realPath "${src_dir}")

if [[ ! -d "${src_dir}" ]];then
    echo "目录不存在,或者不是目录类型";
    exit;
fi

# 默认空格为分隔符
old_ifs=$IFS
# 设置shell 的分词符号为换行符,默认是任何空白; 防止路径中有空格时被分成多个文件
rn_ifs=$'\n'

function resize_watermark(){
    # 注意 本func要loop 变量需要使用前reset 防止上回的值混入
    # 恢复shell默认for分隔符号,防止出现异常
    IFS=$old_ifs
    img="${1}";
    echo "开始处理 ${img} ..."
    # 把png jpg jpeg后缀名统一转成小写的
    sm=$(basename ${img})
    sm=${sm//P/p}
    sm=${sm//N/n}
    sm=${sm//G/g}
    sm=${sm//J/j}
    sm=${sm//E/e}
    ext="${sm##*.}"

    if [[ "${sm}" = "${ext}" ]];then
        echo "不是图片:${img}无后缀名"
        return 1
    fi

    if [[ "${ext}" != "jpg" && "${ext}" != "png" ]];then
        echo "不是JPG或PNG图片,跳过:${img}";
        return 1
    fi
    
    if [[ "${sm//*\.imagemagick\.jpg/}" = "" ]];then
    # 如果是已经处理的，不要再转
        echo "加过水印的图片，跳过"
        return 0
    fi
 
    # 建议使用命令前,先通读 https://imagemagick.org/script/command-line-processing.php 了解用法
    # 使用特殊格式文件名+缩放指定 [wxh>]表示不不允许任何边超出,否则限定,另边按比例缩小
    img_src="${img}[${max_width}x${max_height}>]";
    # 保存在原来路径下
    img_out="${img}.imagemagick.jpg";
    # 一般缓存区是缓存到一定程度后再输出,为了让缓存收到就吐出,设置缓存大小为0
    # 画布背景设成透明
    # 画布足够大，能放得下水印一个内容，画布透明
    # 画的字居中显示 设置画字的字体,中文必须使用支持中文字体 字体大小
    # rgba颜色格式白色画0.x透明度画笔 旋转角度写一个水印 内容来自txt文件
    # 再画相同一行字 错位达到立体效果 双色也能保证水印兼容性
    # 以一个水印内容区裁剪掉空白画布区域
    # 单个水印repeat时间隔
    # 把图片放入缓存区 格式为png
    # 水印盖在原图上 repeat水印 水印来自缓存区
    # 对于设置类型参数，-参数名表示设置，+参数名表示重置，类似-表示展开，+表示收起

    "${magick}" convert  \
        -define stream:buffer-size=0 \
        -alpha set -background none \
        -size 1000x1000 canvas:none \
        -gravity center -font "${ttf}" -pointsize 30 \
        -fill "rgba(0%, 0%, 0%, 0.2)"       -annotate 350x350+2+2 "@${water_text}" \
        -fill "rgba(100%, 100%, 100%, 0.2)" -annotate 350x350+0+0 "@${water_text}" \
        -trim \
        -bordercolor none -border 20 \
        png:- \
        | "${magick}" composite  \
        -compose atop \
        -tile - \
        "${img_src}"  "${img_out}"
}

# 改变for的行分隔符为换行符 兼容路径存在空格的文件
IFS=$rn_ifs

for img in `ls -B1F "${src_dir}"`;do
    img=$(realPath "${src_dir}/${img}")
    resize_watermark "${img}" 
done

echo "处理完成"

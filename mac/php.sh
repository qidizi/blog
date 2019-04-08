# 用来控制php 的脚本
#有些系统默认不安装realpath命令,这里自己实现,shell的function返回字符中只能echo,然后调用时通过re=$(realPath 'kkk')来获得

function realPath() {
    #得到当前文件的绝对路径,()会fork一个subshell,所以,cd并不会影响parentShell的pwd
    realPath="$(cd `dirname ${1}`; pwd)/$(basename ${1})";
    echo ${realPath};
    return 0;
}

# 是否在运行
function phpOn() {
        ps -A -o pid,command|grep "${php_path}\$"

        if [[ "0" -eq "$?" ]];then
            return 1;
        fi
        
        return 0;
}

shDir=$(realPath $0);
shDir=$(dirname $shDir);
php_path="${shDir}/php/qidizi/sbin/php-fpm"

case $1 in
    'stop')
        phpOn;

        if [[ "1" -eq "$?" ]];then 
            pid=$(ps -A -o pid,command|grep "${php_path}\$" | awk '{print $1}')
            kill ${pid}
            phpOn;

            if [[ "0" -eq "$?" ]];then
                echo "php-fpm 停止成功";
            else
                echo "无法停止 php-fpm";
            fi
        else
            echo "php-fpm 未运行";
        fi
   ;;
    'start')
        phpOn;

        if [[ "0" -eq "$?" ]];then
            sudo $php_path;
            phpOn;

            if [[ "1" -eq "$?" ]];then
                echo "php-fpm 启动成功";
            else
                echo "无法启动 php-fpm";
            fi
        else
            echo "php-fpm 正在运行中";
        fi
        ;;
    'status')
        phpOn;

        if [[ "1" -eq "$?" ]];then
            echo "php-fpm 正在运行中";
        else
            echo "php-fpm 未运行";
        fi
        ;;
    *)
        echo "usage ${0} [stop|start|status]";
    ;;
esac

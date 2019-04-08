# 用来控制nginx 的脚本
#有些系统默认不安装realpath命令,这里自己实现,shell的function返回字符中只能echo,然后调用时通过re=$(realPath 'kkk')来获得
function realPath() {
    #得到当前文件的绝对路径,()会fork一个subshell,所以,cd并不会影响parentShell的pwd
    realPath="$(cd `dirname ${1}`; pwd)/$(basename ${1})";
    echo ${realPath};
    return 0;
}

# nginx是否在运行
function nginxOn() {
        ps aux |grep "nginx\:";

        if [[ "0" -eq "$?" ]];then
            return 1;
        fi
        
        return 0;
}

shDir=$(realPath $0);
shDir=$(dirname $shDir);

case $1 in
    'stop')
        nginxOn;

        if [[ "1" -eq "$?" ]];then 
            sudo $shDir/nginx/qidizi/sbin/nginx -s quit;
            nginxOn;

            if [[ "0" -eq "$?" ]];then
                echo "nginx 停止成功";
            else
                echo "无法停止 nginx";
            fi
        else
            echo "nginx 未运行";
        fi
   ;;
    'start')
        nginxOn;

        if [[ "0" -eq "$?" ]];then
            sudo $shDir/nginx/qidizi/sbin/nginx;
            nginxOn;

            if [[ "1" -eq "$?" ]];then
                echo "nginx 启动成功";
            else
                echo "无法启动 nginx";
            fi
        else
            echo "nginx 正在运行中";
        fi
        ;;
    'status')
        nginxOn;

        if [[ "1" -eq "$?" ]];then
            echo "nginx 正在运行中";
        else
            echo "nginx 未运行";
        fi
        ;;
    'test')
        nginxOn;

        if [[ "1" -eq "$?" ]];then
            echo "nginx 正在运行中";
        else
            echo "nginx 未运行";
        fi

        sudo $shDir/nginx/qidizi/sbin/nginx -t;
    ;;
    *)
        echo "usage ${0} [stop|start|status|test]";
    ;;
esac

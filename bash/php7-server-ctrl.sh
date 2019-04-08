# 在MAC上用来控制自带php的脚本
# 请使用bash 本脚本路径方式来运行;或是使用在~/.bash_profile中通过alias php-start="bash /-/soft/php7.server start"来指定使用,修改后记得使用source ~/.bash_profile加载配置
# php-fpm路径
php_path="/usr/sbin/php-fpm";

# 判断php-fpm是否在运行
function phpOn() {
    ps -A -o pid,command|grep "${php_path}\$"

        if [[ "0" -eq "$?" ]];then
            return 1;
        fi
        
        return 0;
}

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
            sudo ${php_path};
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

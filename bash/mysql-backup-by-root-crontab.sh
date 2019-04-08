#!/bin/sh

# 最新版本
# https://github.com/qidizi/linux-shells/blob/master/mysql-backup-by-root-crontab.sh

# 后台测试命令
# xxxxxx.sh &

# 配置root的crontab -e 定时任务,比如:
# 每天03点自动备份mysql数据库
# 0 03 * * * /home/backup/mysql-backup.sh

# mysql 的备份脚本
# 备份原理:
# 1
#   列举所有的库名称;
# 2
#   列举每个库的每张表,除了指定忽略的库;
# 3
#   使用mysqldump 导出每一张表到文件:主机名/年月日/库/表.mysqldump.sql
# 4
#   验证每张表的sql文件是否包含完成标志;
# 5
#       压缩每个sql文件并删除本sql文件
# 6
#       强制删除超过x天的备份文件夹全部文件
# 7
#       发送处理日志到指定email
# 8
#       需要自行配置同步工具多处服务器备份

#----------mysql备份配置信息-------------
#数据库连接用户名
mysqlBackupUser="user name";
#数据库连接用户的密码,不要包含'号
mysqlBackupPwd='user name password';
#连接主机总是使用 127.0.0.1的,不是远程主机运行，请在mysql中创建用户时注意

# 本shell日志文件路径是/var/log/本shell文件名.log,只保留每次运行的日志
# 指定不需要备份的数据库名称,每个名称使用()号包住,如指定不备份 abc.d 和 abc.e二个数据库,就拼写成"(abc.d)(abc.e)",名字不区分大小写
notBackupDatabases="(mysql)(information_schema)(performance_schema)(mqlcx)"
# 指定不需要备份的表,格式如下: (库名 表名)
notBackupTables="(abc e)"

#备份sql保存的根目录,后面需要加/
backupRoot="/home/www/mysql-auto-backup/"
# 删除x天前的备份的目录/文件:x天前备份的都会被删除,为了节省空间
deleteRootOutDays=60

#smtp发送email通知成败与你的配置和系统条件有关,如果没有收到email通知,请到日志中查找原因
#smtp发件人的email:mail from命令用到,一般现在像qq它会要求通过smtp发送的“发送人”是与登录者相同，否则会出错
smtpFrom="backup-notify@qidizi.com"
#日志的收件人
smtpTo="qidizi@qq.com"
#日志收件标题,注意不要包含'
smtpSubject='mysql备份[linux通知]'
#smtp登录用户,qq服务器是完整的email，一般就是邮箱的全部
smtpUser="backup-notify@qidizi.com"
#smtp连接用户的密码,不能包含又引号防止shell出错
smtpPwd='邮箱的登录密码'
#smtp://协议是固定的,只需要改变域名和端口即可,注意暂时不考虑兼容ssl连接
smtpHost="smtp.qidizi.com"
#smtp的端口
smtpPort=25

#=================配置结束行===============

# ------functions-------------------
# 使用telnet通过esmtp发送email内容的funciton参数顺序 "smtp-host" "smtp-port" "smtp-user" "smtp-pwd" "mail-from" "rcpt-to" "标题" "内容"
function esmtp() {
        # telnet 二次命令之间需要sleep
        cmdTest=$(which "swaks" 2>&1);

        if [ "$?" -ne "0" ];then
                echo 'esmtp函数需要swaks命令,请先安装!';
                return 1;
        fi

        host="${1}";
        port="${2}";
        user="${3}";
        pwd="${4}";
        from="${5}";
        to="${6}";
        bid=$(date +%s);
        subject="${7}";
        subjectB=$(echo "${subject}"|base64);
        body="${8}";
        bodyB=$(echo "${body}"|base64);
        data="MIME-Version: 1.0\n";
        data="${data}Date: %DATE%\n";
        data="${data}To: %TO_ADDRESS%\n";
        data="${data}From: %FROM_ADDRESS%\n";
        data="${data}Subject: =?UTF-8?B?${subjectB}?=\n";
        data="${data}Content-Type: multipart/alternative; boundary=${bid}\n";
        data="${data}\n";
        data="${data}--${bid}\n";
        data="${data}Content-Type: text/plain; charset=UTF-8\n";
        data="${data}Content-Transfer-Encoding: base64\n";
        data="${data}\n";
        data="${data}$(echo 'do not support'|base64)\n";
        data="${data}--${bid}\n";
        data="${data}Content-Type: text/html; charset=UTF-8\n";
        data="${data}Content-Transfer-Encoding: base64\n";
        data="${data}\n";
        data="${data}${bodyB}\n";
        data="${data}--${bid}--\n";

        echo "${data}" | swaks --server "${host}" --to "${to}" --from "${from}" --auth-user "${user}" --auth LOGIN  --auth-password "${pwd}" --data -;
        return 0;
}


function myExit(){
    exitCode=$1
    appendLog "主机IP信息:\n$(sudo -u root -s ip -4 -o addr 2>&1)"
    appendLog "脚本总耗时$(expr $(date +%s) - ${SH_START})秒"

        if [ "${exitCode}" -ne "0" ];then
                appendLog "异常退出,请根据日志解决问题"
        fi


        mailInfo=$(esmtp ${smtpHost} ${smtpPort} ${smtpUser} ${smtpPwd} ${smtpFrom} ${smtpTo} "${smtpSubject}" "<pre>$(cat ${shLogPath})</pre>" 2>&1);
        appendLog "发送email通知交互记录如下:\n\n${mailInfo}"

    exit $exitCode
}

# 追加日志
function appendLog(){
        log="${1}";
        type="${2}";

        case $type in
                "1" ) log='<span style="color:red;">'${log}'</span>';; #错误提示,red
                "2" ) log='<span style="color:orangered;">'${log}'</span>';; #提醒提示
                "3" ) log='<span style="color:green;">'${log}'</span>';; #安全提示
        esac

    echo -e "${log}" >> $shLogPath
}

# ============functions===============
SH_START=$(date +%s)
shName=$(basename $0)
shLogPath="/var/log/${shName}.log.html"
echo -e "${0}@$(date "+%F %T")\n" > $shLogPath

if [ ! -e "${backupRoot}" ];then
    mkInfo=$(mkdir -p $backupRoot 2>&1)

    if [ "$?" -ne "0" ];then
        appendLog "创建不存在的mysql备份总目录${backupRoot}:失败,${mkInfo}" 1
        myExit 1
    fi

elif [ ! -d "${backupRoot}" ];then
    appendLog "mysql备份路径${backupRoot}虽存在,但它不是目录" 1
    myExit 2
fi
#今天的备份目录

todayRoot="${backupRoot}$(date +%Y%m%d%H)/"

if [ ! -e "${todayRoot}" ];then
    mkInfo=$(mkdir $todayRoot 2>&1)

    if [ "$?" -ne "0" ];then
        appendLog "创建本轮的备份目录${todayRoot}:失败,${mkInfo}" 1
        myExit 3
    fi
fi

ver=$(mysql --version 2>&1)

if [ "$?" -ne "0" ];then
    appendLog "mysql命令异常:${ver}" 1
    myExit 4
fi

ver=$(mysqldump -V 2>&1)

if [ "$?" -ne "0" ];then
    appendLog "mysqldump命令异常:${ver}" 1
    myExit 5
fi

ver=$(tail --version 2>&1)

if [ "$?" -ne "0" ];then
    appendLog "tail命令异常:${ver}" 1
    myExit 6
fi

ver=$(tar  --version 2>&1)

if [ "$?" -ne "0" ];then
    appendLog "tar命令异常:${ver}" 1
    myExit 7
fi

databases=$(mysql --host=127.0.0.1 --user="${mysqlBackupUser}"  --password="${mysqlBackupPwd}" --execute="show databases;"  --silent --skip-column-names --unbuffered  2>&1)

if [ "$?" -ne "0" ]; then
    appendLog "列举全部数据库名称异常:${databases}" 1
    myExit 8
else
    appendLog "数据库全部列表:\n${databases}"
fi

for database in $databases; do
    # 匹配时不区分大小写
    echo $notBackupDatabases|grep -i "(${database})" 2>&1 >/dev/null

    # 属于不需要备份的库
    if [ "$?" -eq "0" ];then
        appendLog "${database}库指定不备份" 2
        continue
    fi

    databaseRoot="${todayRoot}${database}/"

    if [ ! -e "${databaseRoot}" ];then
        mkInfo=$(mkdir $databaseRoot 2>&1)

        if [ "$?" -ne "0" ];then
            appendLog "创建${databaseRoot}库的备份目录异常:${mkInfo}" 1
            myExit 9
        fi
    fi

    tables=$(mysql --host=127.0.0.1 --user="${mysqlBackupUser}"  --password="${mysqlBackupPwd}" --execute="show tables from \`${database}\`;"  --silent --skip-column-names --unbuffered 2>&1)

        if [ "$?" -ne "0" ]; then
                appendLog "列举${database}库 全部表名异常:${tables}" 1
                myExit 10
        else
                appendLog "${database}库的全部表名:\n${tables}"
        fi

    for table in $tables; do
                #忽略备份文件
                echo $notBackupTables|grep -i "(${database} ${table})" 2>&1 >/dev/null

                # 属于不需要备份的库
                if [ "$?" -eq "0" ];then
                        appendLog "${database}库${table}表指定不备份" 2
                        continue
                fi

        sqlFile="${table}.sql"
        sqlPath="${databaseRoot}${sqlFile}"
        timeStart=$(date +%s)
        dumpInfo=$(mysqldump --host=127.0.0.1 --user="${mysqlBackupUser}" --password="${mysqlBackupPwd}" --dump-date --comments --quote-names --result-file=${sqlPath} --quick  --databases ${database} --tables ${table} 2>&1)

        if [ "$?" -ne "0" ];then
            appendLog "mysqldump导出${database}库${table}表异常:${dumpInfo}" 1
            myExit 11
        fi

        sok="${database}库${table}表dump到${sqlPath}成功:耗时$(expr $(date +%s) - ${timeStart})秒;查找dump成功的'Dump completed'字符标志:"
        tail --lines=10 "${sqlPath}" |grep "\-\- Dump completed" 2>&1 > /dev/null

        if [ "$?" -ne "0" ];then
                sok=${sok}'<span style="color:red;">无，请登录ssh确认本备份情况</span>'
        else
                sok="${sok}存在，据此判断备份成功了"
                tarFile="${sqlFile}.tar.bz2"
                timeStart=$(date +%s)                sok="${sok};打包压缩${sqlFile}(成功后删除之)成${tarFile}:"
                tarInfo=$(tar --create --remove-files --bzip2 --absolute-names --directory="${databaseRoot}"   --add-file="${sqlFile}" --file="${databaseRoot}${tarFile}" 2>&1)

                if [ "$?" -ne "0" ];then
                                        sok=${sok}'<span style="color:red;">出错,'${tarInfo}'</span>'
                else
                                        sok="${sok}成功"
                fi

                sok="${sok},耗时$(expr $(date +%s) - ${timeStart})秒;"

        fi

        appendLog "${sok}"
    done

done

appendLog "\n ------数据库备份操作全部完成------\n"
#开始清理大于x天的备份

daysDir=$(ls --almost-all --ignore-backups --indicator-style=slash -1 "${backupRoot}" 2>&1)

for bkDir in $daysDir;do
    bkDir="${backupRoot}${bkDir}"

    if [ ! -d "${bkDir}" ];then
        continue
    fi

    dirName=$(basename $bkDir)
    #测试目录名是否规定的格式
    echo $dirName | grep -P "^\d{10}$" 2>&1 >/dev/null

    if [ "$?" -ne "0" ];then
        continue
    fi

    outDay=$(date --date="-${deleteRootOutDays}day" "+%Y%m%d00")

    #如果文件时间小于这个过期时间那么就强制删除整个目录
    if [ "${dirName}" -lt "${outDay}" ];then
        rmInfo=$(rm --force --preserve-root --recursive "${bkDir}" 2>&1)
                rmOk="成功"

                if [ "$?" -ne "0" ];then
                        rmOk='<span style="color:red;">失败 -- '${rmInfo}'</span>'
                fi

        appendLog "备份目录${bkDir}超过 ${deleteRootOutDays}天(${dirName} < ${outDay}):强制删除${rmOk}" 3
    fi

done

appendLog "------删除过期备份文件夹操作完成----"
appendLog "空间使用情况如下:\n $(df -h 2>&1)"
appendLog "本轮备份占用空间情况:\n $(du -hs ${todayRoot} 2>&1)"
myExit 0

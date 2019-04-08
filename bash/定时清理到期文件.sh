#!/bin/bash
# 这是一个模板文件,请复制到cache目录下,并配置只允许root r+x
# 用途:定时删除每个用户目录下timingDeleteDir的到期的目录,需要配置root的crontab来定时执行本文件;
# 定时任务需要设定在每天的01点左右,脚本就会删除昨天或之前的文件
# 本文件只能运行于linux下,请自行修改成window版本的bat
# 注意本文件的换行符必须是linux的换行格式,否则无法运行;
# 可以直接运行测试一下效果,日志将保存在cache目录中同名文件;
# 如果配置不当,这个文件可能被外界访问到,所以,请注意防止保密信息,避免输入私密信息

# 配置区
# 用户根目录的上级目录绝对路径,目录后面的/不必加,比如wftp平台的全部用户home目录都存放在/var/wftp/下,那么,这里就填写/var/wftp
userHomeRoot="/var/www/static.china*.net"
# 定时清理的特殊目录名称,代码中默认是timing-delete
timingDeleteDir="timing-delete"

# smtp配置
#smtp发送email通知成败与你的配置和系统条件有关,如果没有收到email通知,请到日志中查找原因
#smtp发件人的email:mail from命令用到
smtpFrom="linux*@chin*.net"
#日志的收件人
smtpTo="linux*@ch*.net"
#日志收件标题,注意不要包含'
smtpSubject='wftp平台定时删除到期文件日志[linux通知]'
#smtp登录用户,qq服务器是完整的email
smtpUser="linux*@ch*.net"
#smtp连接用户的密码,不能包含又引号防止shell出错
smtpPwd='*******'
#smtp://协议是固定的,只需要改变域名和端口即可,注意暂时不考虑兼容ssl连接
smtpHost="smtp.exmail.qq.com"
smtpPort=25

# 配置区
 
function myExit() {
    logPath="${cachePath}${shellName}.log.php";
    logText="记录于$(date +%c) <br> 本日志生成程序:${shellRealPath}<br>可能root在crontab中配置了这个定时任务文件<br>该脚本按照以下规则进行删除符合条件的目录<br>目的是自动清理永久不再使用的文件,达到节省空间,所以产生了这个日志<br>如果需要了解该脚本代码逻辑,打开脚本文件查看:<br><br>如果某指定路径下的子目录(不理会孙目录)<br>按照'4位年份2位月份2位日期'格式命名目录名时,<br>且这个日期小于今天,那么这个目录就会被删除 <br><br> ${@}"

    if [ -d "${cachePath}" ]; then
        echo -e "<?php exit;?>\n${logText}" > $logPath
    else
        echo -e $logText
    fi
    
    mailInfo=$(esmtp ${smtpHost} ${smtpPort} ${smtpUser} ${smtpPwd} ${smtpFrom} ${smtpTo} "${smtpSubject}" "<pre>${logText}</pre>" 2>&1);
    echo -e "发送email通知交互记录如下:\n\n${mailInfo}" >> $logPath;

    exit 0
}

#有些系统默认不安装realpath命令,这里自己实现,shell的function返回字符中只能echo,然后调用时通过re=$(realPath 'kkk')来获得
function realPath() {
    #得到当前文件的绝对路径,()会fork一个subshell,所以,cd并不会影响parentShell的pwd
    realPath="$(cd `dirname ${0}`; pwd)/$(basename ${0})";
    echo ${realPath};
    return 0;
}


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
        body="<pre>${8}</pre>";
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

shellRealPath=$(realPath ${0});
shellName=$(basename $shellRealPath);
cachePath="$(dirname ${shellRealPath})/";
log=""

userHomeRoot="${userHomeRoot}/";
[ ! -d "${userHomeRoot}" ] && myExit "变量userHomeRoot指定路径[${userHomeRoot}]不存在,或不是目录,请检查"
# 定时最小可设定时间
cronMinTime=10030;
# 定时最大可设定时间
cronMaxTime=10100;
# 定时当前运行时间
cronNowTime=$(date +1%H%M);

if [[ "${cronMinTime}" -lt "${cronNowTime}" ]] && [[ "${cronNowTime}" -lt "${cronMaxTime}" ]];then
	dirs=$(ls -d1 ${userHomeRoot}*/${timingDeleteDir}/*/);
else
	dirs=""
	log="${log}<span style=\"color:red;\">错误:本脚本的定时启动时间只能设定在每天的00:30至01:00之间</span><br><br>"
fi

today=$(date +%Y%m%d);
log="${log}今天是${today}<br><br>";

for line in $dirs; do
    dirName=$(basename $line|grep -P "^\d{4}\d{2}\d{2}$")

    # 不匹配
    if [ -z "$dirName" ]; then
        log="${log} <br> 不符合目录名是 4位年2位月2位日 命名规则,保留:${line}"
        continue
    fi

    # 没有过期;注意使用[]非[[]]格式的if时,<或是>都需要转义
    if [ ! "${dirName}" \< "${today}" ] ;then
        log="${log} <br> 有效期内,保留: ${line}"
        continue  # 目录未到期
    fi

    # 文件命名的日期小于今天了,可以整个文件夹删除;
    log="${log} <br> 今天到期,删除: ${line}"
    rm -rf "$line"
done

log="${log}<br>操作结束"
myExit "${log}"

#!/bin/bash


# 参数顺序 "smtp-host" "smtp-port" "smtp-user" "smtp-pwd" "mail-from" "rcpt-to" "标题" "内容"
function esmtp() {
        # telnet 二次命令之间需要sleep
        cmdTest=$(which "telnet" 2>&1);

        if [ "$?" -ne "0" ];then
                echo 'esmtp函数需要telnet命令,请先安装!';
                return 1;
        fi

        sleepSec=1;

        (
                bid=$(date +%s);
                echo 'ehlo qidizi.com';#打招呼
                sleep ${sleepSec};
                echo 'auth login';
                sleep ${sleepSec};
                echo ${3}|base64;
                sleep ${sleepSec};
                echo ${4}|base64;
                sleep ${sleepSec};
                echo 'MAIL FROM: '${5};
                sleep ${sleepSec};
                echo 'RCPT TO: '${6};
                sleep ${sleepSec};
                echo 'data';
                sleep ${sleepSec};
                echo 'MIME-Version: 1.0';
                echo 'Date: '$(date -R);
                echo 'Subject: =?UTF-8?B?'$(echo ${7}|base64)'?=';
                echo 'From: =?UTF-8?B?'$(echo ${5}|base64)'?= <'${5}'>';
                echo 'To: =?UTF-8?B?'$(echo ${6}|base64)'?= <'${6}'>';
                echo 'Content-Type: multipart/alternative; boundary='${bid};
                echo "";
                echo '--'${bid};
                echo 'Content-Type: text/plain; charset=UTF-8';
                echo 'Content-Transfer-Encoding: base64';
                echo "";
                echo '你的服务器不支持显示html格式信件内容'|base64;
                echo '--'${bid};
                echo 'Content-Type: text/html; charset=UTF-8';
                echo 'Content-Transfer-Encoding: base64';
                echo "";
                echo -e "${8}"|base64;#内容部分需要换行,比如兼容<pre>标签
                echo '--'${bid}'--';
                sleep ${sleepSec};
                echo '.';
                sleep ${sleepSec};
                echo 'quit';
        )|telnet ${1} ${2}
        return 0;
}




#用例,注意正面的变量需要自己定义,
# mailInfo=$(esmtp ${smtpHost} ${smtpPort} ${smtpUser} ${smtpPwd} ${smtpFrom} ${smtpTo} "${smtpSubject}" "<pre>$(cat ${shLogPath})</pre>" 2>&1);
# echo -e "发送email通知交互记录如下:\n\n${mailInfo}"

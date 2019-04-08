# sudoers指令说明

-----------------------------------------------------

` User Host = (Runas) Options Command` 

如上，一行指令分4节,示例如下

` qidizi ALL=(userA:groupA, groupB) NOPASSWD: /home/xxx.sh,/bin/xxxx `

第一节,`User`，表示被授权用户，示例 `qidizi`,表示哪个用户可以使用sudo -u的指令来运行命令;

第二节,`Host`，表示主机,示例`ALL=(userA:groupA, groupB)`的`ALL=`表示可以在那个主机上运行,ALL表示在任意主机上=号后面表示sudo -u可以指定的用户与用户组,如例子-u userA -g groupA;

第三节，`Options`，表示选项,示例`NOPASSWD`表示执行sudo时不要求输入`User`的密码,使用:号来分开多个选项;

第四节，可执行命令,是可以执行的命令,为了安全，建议使用绝对路径限定,也可以使用通配符,如果填写`ALL`是表示可以运行任意指令;

第一节，`User`被授权用户(user)或runas可以是用户名;组名使用%号开头,注意不是通配符,只是表示是组,非用户名而已;uid使用#号打头;或组id使用%#打头;

主机部分可以是ip;或是掩码形式,如192.0.2.0/24;或主机名;

runas部分如果忽略,表示只允许以root运行;如果只指定group,那么只允许用当前用户+指定group来运行;ALL:ALL表示以任意用户,任意用户组运行;

command部分一般使用绝对路径指定可执行文件,后面不跟参数表示可以输入任意参数;如果需要指定的参数需要具体写上,如/bin/ls ./;如果不允许输入参数写成: /bin/ls "";如果可执行路径是以/结束,表示可以执行本目录当前层级的任何文件,但不包括目录下面的子目录的文件;



路径部分可以使用*来通配,但是它不能配置/

/etc/sudoers中配置了很多defaults选项,可以在自己的每行配置中替换掉;

alias语法有几个类型,如Cmd_Alias,Host_Alias,别名名称只能使用大写或_线,使用时直接写即可;



如果需要改变默认选项,如sudo 要求tty来执行,可以这样写；
#sudo的默认配置是不允许通过ssh来执行sudo指令的，必须在本地通过tty来执行，下面就是在sudo配置中取消这个限制
Defaults!/home/qidizi/test.sh !requiretty
# 然后再写规则
test ALL=(ALL) NOPASSWD: /home/qidizi/test.sh
最后就可以通过ssh来执行这个指令了
>_   `ssh test@127.0.0.1 sudo /home/qidizi/test.sh;`

注意上面的命令不能是 `ssh test@127.0.0.1 sudo -s /home/qidizi/test.sh;`多一个-s好像被认为增加了其它参数不匹配上面规则;

最后，建议每个规则独立一个文件，建议使用`visudo -f /etc/sudoers.d/qidizi` 这种方式来编辑，保存时，vi会校验的。

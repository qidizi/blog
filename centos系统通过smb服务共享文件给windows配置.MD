# 虚拟机中安装centos系统,通过smb服务共享文件给windows的配置  
----

## 处理原则  

**根据向谁服务和向谁拿服务2个方向,从信赖少到多的环节确保配置正确处理**  
例如:先确保smbd运行起来了->再通过smbclient来连接确认内部系统能连接成功->再考虑其它系统连接  

## 依赖

1. 虚拟机[Oracle VM VirtualBox](https://www.virtualbox.org/)  
1. 系统[Centos 7](https://www.centos.org/download/)  
1. 安装Windows 10的物理机  

## 步骤  

1. 准备好安装有Windows 10的物理机;
1. 下载安装好虚拟机VirtualBox,安装时建议除了主程序,其它都不要勾选,像:usb支持,不同虚拟网卡,python支持等都不要选择;原因很简单,我用不到,多出几个可能永远用不上的虚拟网卡在网络管理中很不爽;  
1. 安装VirtualBox的扩展包;
1. VirtualBox->全局配置->网络->添加NatNetwork并勾选启用,双击它配置->勾选DHCP;点击端口转发->添加smb转发规则:名称`随意`,协议`TCP`,主机`127.0.0.1`,主机端口`445`,子系统IP`一般是10.0.2.3,具体看centos安装得到多少或是你手工指定的`,子系统端口`445`保存即可;  
1. 自行完成新建Centos7子系统安装;
1. centos中安装并配置samba  
1. 添加smb连接时使用的用户`smbpasswd -a qidizi`,提示:**写这个步骤时手上没有系统,此命令搜索得到的,请自行确认命令正确性,输入smb拼命TAB补全即可**

    安装smb服务组件:`yum install samba -y`; 
    smb参考配置/etc/samba/smb.conf如下(**注意smb版本不同配置也不同,建议在原来基础上逐个调整保证配置可用性**):

```

[global]
    # 改变默认端口
    smb ports = 445
    # 指定是否与物理机同一个工作组
        workgroup = QIDIZI-PCS
        # smb版本信息
        server string = Samba Server Version %v
        # 工作网络中唯一名称,好像smb需要借助这个来查找服务,待考证
        netbios name = qidizi-pc-centos
    #使用用户表,不使用ssh的用户
    username map = /etc/samba/users.map
        # log files split per-machine:
        log file = /var/log/samba/log.%m
        # maximum size of 50KB per log file, then rotate:
        max log size = 50
    # smb连接安全,可以做到匿名访问的;新版本不支持,配置share值,取而代之的是在共享节点上配置 iguest ok= yes
        security = user
        passdb backend = tdbsam
        load printers = no
    printable = no
    disable spoolss = yes
        cups options = raw
     browseable = no

#共享时目录名,对应的在window时访问时要写`\\ip\www`
[www]
comment = web root
#分享的实际目录
path = /home/www
# 可写入
writable = yes
# 可连接用户  
valid users = qidizi
#public = no
# 新建时文件权限
create mask = 0777
directory mode = 0777
# qidizi登录后,强制转换成使用root访问全部文件
force user = root
force group = root

# 以上用意是,因为windows没有linux的权限概念,导致比如php动态写入的文件,它的拥有者是apache,其它用户仅有查看权;强制模拟成root就不存在这个问题了


# 如/etc/hostname vm.localdomain；那么/etc/hosts 要写 vm.localdomain；而不是vm.localhost;否则会出现protocol negotiation failed: NT_STATUS_IO_TIMEOUT
# 当前配置用ssh用户，所以，要passwd qidizi来修改密码才能使用；
```

8. 启动smbd`service smbd start`;遇到错误就要解决,直到可以启动;
1. 确保smbd已经正常运行中:`netstat -anp|grep sm`;通常能看到它监听在`0.0.0.0:445`;
1. 在子系统centos中测试smb连接正常性:`smbclient -d 10 -U qidizi //127.0.0.1/www 密码`;`-d 10`表示连接时使用调试模式;密码就是smbpasswd -a时填写的密码;若连接成功,会是一个smb连接命令行模式,如输入`ls`即可列举出共享目录信息;`exit`断开连接;  
1. 关闭子系统centos的防火墙或是把smb服务加入白名单;
1. 关闭物理机系统windows的防火墙或是把smb加入白名单;
1. 在windows中打开cmd.exe**管理员**,运行services.msc打开服务管理，找到server这个名字的服务，禁用和停止它，如果停止失败，重启机器就可以了；停止这个服务后，0.0.0.0:445这个监听就会消失了；
1. 在windows中文件管理上方菜单找到添加远程驱动器,地址为`\\127.0.0.1\www`来连接smb共享文件;

## 操作要点

1. linux提供smb服务很方便;
2. 物理机的系统要访问虚拟机子系统中的服务时,比较好的方案是通过虚拟机软件提供的端口转发功能,在物理机系统上绑定监听,然后把请求转给子系统来提供对应服务;如web服务实际是子系统提供,绑定在物理机的0.0.0.0:80时,就能向全世界提供网站服务了;  
3. 端口仅允许一个进程绑定监听;windows的smb服务与client都不支持修改端口号,且又是默认启动的.ok,基于这些,停止window的server服务,把445端口让出来,上面的操作意义就在这;

## 不足

1. smb毕竟是一个服务,不是一个底层的文件系统,所以,在ide中的更新会有很大的延迟问题,例如,你在centos中git pull了,ide中还是死活不见pull下来的文件;怎么办?ide中点击同步吧;
1. 你共享的是php源代码目录,windows的ide使用它,同时它在centos中给nginx+php使用着,你想测试php+nginx的文件读写权限分配安全性,不好意思,不支持,只要ide一动某种时机下它就变成了root,且权限是a+wxr的;这就是跨不同文件权限管理系统共享所带来的问题;
1. 在子系统centos中创建了只有大小写区分的同名文件,如a.txt与A.txt,centos是当做2个文件对待的;但是,windows把它认为是同一个文件,不管你是打开A.txt还是打开a.txt写入东西,最后在centos这边查看内容发现总是动了同一个文件;
1. 切记要先关闭使用到smb文件的client,再关闭smb服务,否则,windows中的应用/进程关闭假死会把你气死,仅仅从smb client连接查找不存在的ip时就能看到那得要等多久才知道smb服务已经关门了;

## 未明问题
1. 在设定端口转发规则时,发现使用127.0.0.1没有问题;但是仅且只把它修改成127.0.0.2,windows就无法连接;虽然2也是指向了本机(它是一个loopback ip),但是可能smb这块处理比较特殊,原因未明;如ssh转发到2上面它是能正常使用的--使用putty连接127.0.0.2:22
1. 有同事在使用这种方式编码时--centos中git+windows中phpstorm;经常出现git log损坏的问题,不得不重新clone版本;后来把.git文件放到非smb共享目录中减少了很多这种损坏机率; 目前不知是对方使用方式问题,还是有那个环节真存在会破坏.git文件的可能;


## 参考BLOG

1. [http://www.nikhef.nl/~janjust/CifsOverSSH/Win8Loopback.html](http://www.nikhef.nl/~janjust/CifsOverSSH/Win8Loopback.html)  

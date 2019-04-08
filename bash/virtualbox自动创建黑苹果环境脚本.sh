#/bin/sh
#自动化配置mac虚拟脚本

#虚拟机硬盘保存路径
vdi="/-/vm/mac/mac.vdi";
#mac的安装dmg转iso文件路径，10.13.2不能从商店直接下载
iso="/home/qidizi/Desktop/mac/mac.iso";
#虚拟机的名称
vmName="mac";
#执行文件名
vbm="VBoxManage";
#虚拟机内存大小,单位MB
rem="1818"
#虚拟机硬盘大小,单位MB
hdSize="102400";

VBoxManage showvminfo ${vmName};

if [[ "${?}" -eq "0" ]];then
    #如果存在，先删除
    ${vbm} controlvm ${vmName} poweroff;
    
    if [[ "${?}" -eq "0" ]];then
        echo "等待虚拟机关机完成...";
        sleep 4s;
    fi
        
    echo "mac虚拟机已经存在，先删除(包括虚拟硬盘），再尝试";
    ${vbm} unregistervm ${vmName} --delete;
fi

echo "创建mac虚拟机";
${vbm} createvm --name ${vmName} --groups "/" --register --ostype MacOS_64;
# 生成100g的动态大小的硬盘
echo "生成100g的动态大小的硬盘";
${vbm} createmedium disk --filename ${vdi} --size ${hdSize} --format VDI;
echo "创建虚拟机的sata接口";
${vbm} storagectl ${vmName} --name SATA --add SATA --controller IntelAHCI --portcount 2 --hostiocache on --bootable on 
echo "把硬盘绑定到虚拟机";
${vbm} storageattach ${vmName} --storagectl SATA --port 0 --type hdd --medium ${vdi};
echo "添加光盘"
${vbm} storageattach ${vmName} --storagectl SATA --port 1 --type dvddrive --medium ${iso};
echo "修改内存为1818M，2个cpu，显存128M";
# 测试了只有这个网卡是ok的82545EM，自带驱动否则就会在安装成功初始化时重启（可以先不配置网络进入系统再调整虚拟机）
${vbm} modifyvm ${vmName} --memory ${rem} --cpus 2 --chipset ich9 --boot1 dvd --boot2 disk --boot3 none --boot4 none --audio none --vram 128 --usb on  --description "mac 测试机" --keyboard usb --acpi on --ioapic  on --accelerate3d on --bioslogodisplaytime 10 --biosbootmenu messageandmenu --nic1 natnetwork --nictype1 82545EM --cableconnected1 on --nicpromisc1 allow-all --nat-network1 NatNetwork --macaddress1 auto --mouse usb --firmware efi

echo "设置虚拟CPU符合mac要求"

#这个可以不用也能正常启动，但是好像有点卡，这个不懂是模拟那个cpu
${vbm} modifyvm ${vmName} --cpuid-set 00000001 000106e5 00100800 0098e3fd bfebfbff

# 不加这个好像会显示黑平果，会载入安装比较久，可能是它会按照新机器版本来配置？性能会比较差；下面是假装成2017那款机型，具体可以使用”iMac18,1“搜索，会看到apple的关于每个机型的描述,假装最老的机型，性能会好很多，可能是mac会自动取消一些动画
${vbm} setextradata ${vmName} "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac11,3"

#这个用途不明
${vbm} setextradata ${vmName} "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"

#这个用途不明
${vbm} setextradata ${vmName} "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"

#这个好像是必须的，否则虚拟机就会不停的重启，进不了iso
${vbm} setextradata ${vmName} "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"

#这个用途不明
${vbm} setextradata ${vmName} "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 1

echo "配置虚拟机成功";
echo -e "启动成功后，选择磁盘管器-选择vdi这个硬盘-选择区分大小写+GUID分区表-抹除-退出磁盘管理器-安装-重启会提示boot osx失败，又重进入iso安装了-关机-弹出光盘-启动-按host+r重启虚拟机，然后快速点按f12直到成功进入efi菜单-选择“Boot Maintenance Manager”-选择“Boot from File”-这时有2个选项，一个是“normal Boot partition”，但是这个还没有安装好系统，所以，它boot时会提示boot osx失败；第2个选项是“ Recovery partition“，就是刚才iso安装的内容，选择它-选择”<macOS Install Data>“-选择”Locked Files“-选择”Boot Files“-选择”boot.efi“-正常安装开始了，！！！！如果安装重启，可以选择我的电脑没有网络，安装完成再配置\n更多参考 https://forums.virtualbox.org/viewtopic.php?f=22&t=85631 ";

echo "输入y，立刻启动虚拟机："
read yes;

if [[ "${yes}" = "y" ]];then
 ${vbm} startvm ${vmName};
fi

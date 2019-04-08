@echo off
set vm="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

if NOT exist %vm%. ( 
	echo virtualbox的命令文件%vm%不存在，请修改本bat文件，修正路径.
	pause.
	exit.
)

::开始标签
:menu
echo.

echo 控制面板
echo.
echo 0 列举全部虚拟机；
echo.
echo 1 列举正在支行中虚拟机；
echo.
echo a centos虚拟机开机；
echo.
echo b centos虚拟机关机；
echo.
echo 请输入上面对应字符后,回车即可完成操作的选择，输入其它字符并回车退出本程序：
set /p label=
:eof_menu

set called=0
call :callLabel%label%
::如果命令执行成功，就直接返回主菜单，否则退出
IF %called% EQU 1 goto menu


echo.
echo 本程序即将退出...稍息自动关闭窗口
ping 127.0.0.1 -n 2 >nul
GOTO :EOF
exit

:callLabel0
::列举全部的虚拟机信息
	set called=1
	
	echo.
	echo 机器上安装的全部虚拟机名称与uuid对应关系如下：
	%vm% list vms
	echo.

:eof_callLabel0
	GOTO :EOF
::label-end

:callLabel1
::列举运行中虚拟机信息
	set called=1

	echo.
	echo 正在运行中的虚拟机如下：
	%vm% list runningvms
	echo.

:eof_callLabel1
	GOTO :EOF
::label-end

:callLabela
::centos虚拟机开机
	set called=1
	
	echo.
	echo 尝试启动中 ...
	%vm% startvm centos --type headless
	echo.

:eof_callLabela
	GOTO :EOF
::label-end

:callLabelb
::centos虚拟机关机
	set called=1
	
	echo.
	echo 尝试关机中 ...
	%vm% controlvm centos poweroff
	echo.

:eof_callLabelb
	GOTO :EOF
::label-end

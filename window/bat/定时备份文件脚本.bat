@echo off
echo 全服务器备份脚本
echo.
set batDir=%~dp0
CD "%batDir%"
set bakDir=%~f0
set bakDir=%bakDir%-backup\%date:~0,4%.%date:~5,2%.%date:~8,2%-%time:~0,2%_%time:~3,2%_%time:~6,2%_%time:~9,3%\
echo.

if EXIST "%bakDir%" (
    echo 备份目录%bakDir%存在,可能此目录有其它文件,为了安全,程序退出,请重新运行本程序
    call :exitTip 10
)

echo.

md  %bakDir%
echo.

IF %ERRORLEVEL% NEQ 0 (
    echo 创建备份目录%bakDir%失败,请重新运行再试
    call :exitTip 10
)

echo 创建备份目录%bakDir%成功
echo.
set mqlCode=D:\www\mqlcx\
echo 复制网站代码%mqlCode%

set bk=%bakDir%\mqlcx
md %bk%
copy /v /y "%mqlCode%" "%bk%"

IF %ERRORLEVEL% NEQ 0 (
    echo 复制网站代码%mqlCode%失败,请重新运行再试
    call :exitTip 10
)

echo.
set bxdsj=D:\www\bxdsj\
echo 复制"不许动手机"网站代码%bxdsj%
set bk=%bakDir%\bxdsj
md %bk%
copy /v /y "%bxdsj%" %bk%

IF %ERRORLEVEL% NEQ 0 (
    echo 复制"不许动手机"网站代码%bxdsj%失败,请重新运行再试
    call :exitTip 10
)

echo.

echo 操作完成
call :exitTip 600



:exitTip
::退出前提示
	echo.
    echo.
    echo 注意:程序将在 %1 秒自动退出 ...
    ping 127.0.0.1 -n %1 > nul
    exit 0
:eof_exitTip
    exit 0
	GOTO :EOF
    exit 0
::<<<<<<<



:baseNamePre
::格式化处理先
    set return=%~p1
    call :baseName %return%
    set return=%return%
:eof_baseNamePre
	GOTO :EOF


:baseName
::获取文件或是目录名
    set return=%~nx1
:eof_baseName
	GOTO :EOF

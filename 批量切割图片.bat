:: 文件必须保存成GBK编码，换行使用windows的换行格式
@echo OFF
:: 可以使用%变量名:~1,-1%写法去掉2头双引号

SET sh_dir=%~dp0
SET magick="%sh_dir%\convert.exe"

echo 检测处理工具是否存在...

if NOT EXIST %magick% (
  echo 图片处理命令%magick%未安装,请访问https://imagemagick.org/script/download.php安装
  goto:error_for_exit
)

echo OK!

echo.
echo.

echo 检测待处理目录是否存在...

if NOT EXIST "src_img\" (
  echo 存放待处理的图片目录%sh_dir%src_img不存在,请先创建后并放入待处理的图片,再试
  goto:error_for_exit
)

echo OK!
  
cd src_img
  
if %errorlevel% NEQ 0 (
    echo 处理图片时出错，出错信息如上所示
    GOTO :error_for_exit
)

echo 检测是否有待处理的图片...    
dir *.*
  
if %errorlevel% NEQ 0 (
    echo 这个目录没有jpg图片
    GOTO :error_for_exit
)

echo OK!      

if EXIST "out_img" (
  echo 尝试移除旧处理图片...
  del /q out_img\*
    
  if %errorlevel% NEQ 0 (
      echo 尝试删除旧图片时出错，出错信息如上所示
      GOTO :error_for_exit
  )

  echo OK!
)

if NOT EXIST "out_img" (
  echo 创建输出目录...
  mkdir out_img
  
  if %errorlevel% NEQ 0 (
      echo 创建输出目录出错，出错信息如上所示
      GOTO :error_for_exit
  )
  
  echo OK!
)

echo.
echo.
echo 寻找图片...

FOR %%P in (*.png,*.jpg,*.jpeg) do (
  CALL:resize_watermark "%%P"
)

    
      
echo.
echo.
echo 全部处理完成,请打开%sh_dir%\src_img\out_img\目录查看
start  ""  "%sh_dir%\src_img\out_img\"
echo.
exit /b 0

:resize_watermark

  echo.
  echo.
  echo "准备处理%~f1"
  echo.
    
  
  SET img_src=%~f1
  
  :: 注意,%号属于bat的变量符号,所以要使用%来转义;必须要通过-set filename:xxx "%%内部缩写"来定义,才能使用
  :: 直接在输出文件名那写%t并没有效果
  :: 可用内置变量见 https://imagemagick.org/script/escape.php
  :: 参数说明 -crop 1307x349+0+417  释义 -crop 切出宽度x切出高度+偏移左上0点的X轴+偏移左上角0点的Y轴
  :: "out_img\%%[filename:a]-crop-2.jpg"  这个输出文件名要根据需要编写,如切出的第一块为1,第2块为2修改编号即可
  :: 如果下行命令中出现""中文.jpg"",就会导致中文乱码而异常,所以,要保证它只有一对双引号
  %magick% "%img_src%" -crop 1307x305+0+69 -set filename:a "%%t" "out_img\%%[filename:a]-crop-1.jpg"
  
        
  if %errorlevel% NEQ 0 (
      echo 处理图片时出错，出错信息如上所示
      GOTO :error_for_exit
  )
  
  echo.
  echo.
  
  
GOTO :EOF
  
  
  


:error_for_exit
  pause
  exit /b %errorlevel%

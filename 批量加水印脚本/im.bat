:: 文件必须保存成GBK编码，换行使用windows的换行格式
@echo OFF
:: 可以使用%变量名:~1,-1%写法去掉2头双引号

:: ----config-----
:: 主流2K分辨率为2560x1440 若某边超出这个值,就会进行缩小
SET max_width=2560
SET max_height=1440
:: ----config-----

SET sh_dir=%~dp0
SET magick="%sh_dir%\magick.exe"

if NOT EXIST %magick% (
  echo 图片处理命令%magick%未安装,请访问https://imagemagick.org/script/download.php安装
  goto:error_for_exit
)

SET ttf="%sh_dir%\free.ttf"

if NOT EXIST %ttf% (
  echo 水印需要的字体文件%ttf%不存在
  goto:error_for_exit
)

SET water_text="%sh_dir%\water_text.txt"

if NOT EXIST %water_text% (
  echo 水印内容文件%water_text%不存在
  goto:error_for_exit
)

SET water_text="@%water_text:~1,-1%"

echo.
echo ！！！！本工具所在路径不允许有中文！！！！！！！
echo.
echo.
echo 给文件夹中图片调整大小+加水印
echo ↓把待处理JPG或是PNG图片放入一个文件夹
echo ↓将该文件夹拖至此窗口后放开
echo ↓回车等待处理结果
echo ↓进入该文件夹即可看到已处理好的图片
echo.
echo 请拖入待处理文件夹
echo.
SET /p src_dir=

SET out_ext=.imagemagick.jpg

CALL:dir_img %src_dir%

echo.
echo 处理完成
pause
exit /b 0

:: 使用调用法来处理拖目录可能有双引号问题
:dir_img
  echo.
  echo.
  
  if NOT EXIST "%~f1\" (
    echo 拖入的文件夹不存在或不是一个文件夹
    goto:error_for_exit
  )
  
  cd /d "%~f1"
  
  FOR %%P in (*.png,*.jpg,*.jpeg) do (
    CALL:resize_watermark "%%P"
  )
  echo.
  echo.
  GOTO :EOF


:resize_watermark

  echo.
  echo.
  echo "准备处理%~f1"
  echo.
  
  echo "%~1" | findstr "%out_ext%" >nul
  
  if %errorlevel% equ 0 (
    echo 跳过已处理图片
    GOTO :EOF
   )
    
  :: 建议使用命令前,先通读 https://imagemagick.org/script/command-line-processing.php 了解用法
  :: 使用特殊格式文件名+缩放指定 [wxh>]表示不不允许任何边超出,否则限定,另边按比例缩小
  SET img_src="%~f1[%max_width%x%max_height%>]"
  :: 保存在原来路径下,加上特殊后缀
  SET img_out="%~f1%out_ext%"
  
  :: 一般缓存区是缓存到一定程度后再输出,为了让缓存收到就吐出,设置缓存大小为0
  :: 画布背景设成透明
  :: 画布足够大，能放得下水印一个内容，画布透明
  :: 画的字居中显示 设置画字的字体,中文必须使用支持中文字体 字体大小
  :: rgba颜色格式白色画0.x透明度画笔 旋转角度写一个水印 内容来自txt文件
  :: 再画相同一行字 错位达到立体效果 双色也能保证水印兼容性
  :: 以一个水印内容区裁剪掉空白画布区域
  :: 单个水印repeat时间隔
  :: 把图片放入缓存区 格式为png
  :: 水印盖在原图上 repeat水印 水印来自缓存区
  :: 对于设置类型参数，-参数名表示设置，+参数名表示重置，类似-表示展开，+表示收起
  :: 如果提示无法打开某个xml,就放置该文件即可，目前来说仅需要magick.exe+colors.xml

  %magick% convert  ^
      -define stream:buffer-size=0 ^
      -alpha set -background none ^
      -size 1000x1000 canvas:none ^
      -gravity center -font %ttf% -pointsize 30 ^
      -fill "rgba(0%%, 0%%, 0%%, 0.2)"       -annotate 350x350+2+2 %water_text% ^
      -fill "rgba(100%%, 100%%, 100%%, 0.2)" -annotate 350x350+0+0 %water_text% ^
      -trim ^
      -bordercolor none -border 20 ^
      png:- ^
      | %magick% composite  ^
      -compose atop ^
      -tile - ^
      %img_src%  %img_out%
      
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

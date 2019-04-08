# 批量加水印shell脚本

free.ttf 为水印字体  
src.png 为原图  
src.png.imagemagick.jpg 为处理加水印后图片  
im.sh 为类unix处理脚本  
im.bat 为windows处理脚本  
colors.xml 为windows下运行必须配置文件  
magick.exe 为window下使用工具  

---
## 脚本产生原因

其它部门希望有一个快速批量给图片打水印的工具,考虑了下,若写个php或是写一个java什么的,需要安装环境非常麻烦  
最后找到im,发现使用shell脚本来编写依赖最少,虽然可以使用bat来处理,但是太麻烦了,懒得写,感觉windows中安装个bash很省事的  
最后依赖bash+本脚本+im即可使用  

---
![处理后效果图](https://github.com/qidizi/memo/raw/master/批量加水印脚本/example.jpg)




- # linux下无法输入中文
 因为phpstorm使用qt来实现ui，所以，问题出在qt框架中如何启用中文ime的问题，目前大概尝试能生效的是在env中加入以下配置，ime使用rime
 比如在~/.bashrc中加入
 
 ```
 export GTK_IM_MODULE=ibus
 export XMODIFIERS=@im=ibus
 export QT_IM_MODULE=ibus
 ```

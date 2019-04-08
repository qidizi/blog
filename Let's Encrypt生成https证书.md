# Let's Encrypt 部署方法

1. `yum install certbot -y`

2. 通过dns验证方式获利证书方法

`certbot certonly --manual --preferred-challenge dns -d qidizi.cn`

期间会提示在dns解析中加入txt记录，按照提示加入稍等一会即可回车

3. 准备过期要更新方法，也可以在定时任务中每天执行
`certbot renew`

1. nginx配置与使用；注意不要使用cert.pem这个，虽然nginx不报错，但是微信无法正常显示页面，说链条不完整

```
listen 443;
ssl on;
ssl_certificate /etc/letsencrypt/live/qidizi.cn/fullchain.pem; # managed by Certbot
ssl_certificate_key /etc/letsencrypt/live/qidizi.cn/privkey.pem; # managed by Certbot
ssl_session_timeout 5m;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_prefer_server_ciphers on;
```

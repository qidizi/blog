<?php
/**
 * 使用php实现代理请求功能
 * 使用白名单授权
 * 请求方式
 * fetch("http://域名/proxy.php", {"credentials":"include","headers":{},"referrer":"http://www.bing.com","referrerPolicy":"no-referrer-when-downgrade","body":"base64EncodeUrl=aHR0cDovL2EuY29tLz9raz0zMzMma2trPTM","method":"POST","mode":"cors"});
 */
if (empty($_POST) || empty($_POST['base64EncodeUrl'])) {
    $example = [
        'base64EncodeUrl' => 'base64_encode(xx://domain/path?name=val&...)',
        'base64EncodePost' => 'base64_encode(name=val&...)',
        'header' => '[h1,h2]'
    ];
    exit(json_encode($example, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT));
}
if (empty($_SERVER['REQUEST_METHOD']) || 'POST' !== $_SERVER['REQUEST_METHOD']) exit('only POST');
// 目前得知，ajax是不允许修改这个值的
if (empty($_SERVER['HTTP_REFERER'])) exit('deny');
// 允许的域名
const ALLOW_DOMAIN = ',https://qidizi.github.io,http://php.local.qidizi.com,';
$request = preg_replace('/^([^:]+[:\/]+[^\/]+).*$/', '${1}', $_SERVER['HTTP_REFERER']);
// 只允许指定的域名
if (false === strpos(ALLOW_DOMAIN, ',' . $request . ',')) {
    exit('deny');
}
// 允许指定域名通过ajax访问；
header('Access-Control-Allow-Origin: ' . $request, true);
header('Access-Control-Allow-Methods: ' . $request, true);
header('Access-Control-Allow-Headers: ' . $request, true);
// 防止转义，php编码是utf-8
$ch = curl_init(base64_decode($_POST['base64EncodeUrl']));
// 设置代理等待超时时间，防止过久，浪费服务器资源
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
// 直接使用客户端的请求浏览器信息，防止对方做了拒绝某些浏览器限制
curl_setopt($ch, CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT']);
if (!empty($_POST['base64EncodePost'])) {
    // post
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, base64_decode($_POST['base64EncodePost']));
}
// 默认是get
if (!empty($_POST['header']) && is_array($_POST['header'])) {
    curl_setopt($ch, CURLOPT_HTTPHEADER, $_POST['header']);
}
// 禁用后cURL将终止从服务端进行验证。使用CURLOPT_CAINFO选项设置证书使用CURLOPT_CAPATH选项设置证书目录 如果CURLOPT_SSL_VERIFYPEER(默认值为2)被启用，CURLOPT_SSL_VERIFYHOST需要被设置成TRUE否则设置为FALSE。
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
// 1 检查服务器SSL证书中是否存在一个公用名(common name)。译者注：公用名(Common Name)一般来讲就是填写你将要申请SSL证书的域名 (domain)或子域名(sub domain)。2 检查公用名是否存在，并且是否与提供的主机名匹配。
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
// 尝试连接超时秒数
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
// 最大的持久连接数
curl_setopt($ch, CURLOPT_MAXCONNECTS, 5);
// 响应保存到变量中,不是直接输出到浏览器
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
// 输出内容前面包含对方响应头
curl_setopt($ch, CURLOPT_HEADER, true);
// 非200时，也显示服务器输出的body
curl_setopt($ch, CURLOPT_FAILONERROR, false);
// 支持302
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
// 处理完立即断开，不复用
curl_setopt($ch, CURLOPT_FORBID_REUSE, true);
// 最大的重定向次数 防止出现loop
curl_setopt($ch, CURLOPT_MAXREDIRS, 5);
// 有些网站可能是gbk的
echo curl_exec($ch);
curl_close($ch);

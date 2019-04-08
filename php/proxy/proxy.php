<?php
/**
 * 使用php实现代理请求功能
 * 目前支持get与post
 * 目前是通过$_GET方式来中转参数，可能会受到url长度的限制
 * 
 * 请求用例：
 * 
 * http://域名/proxy.php?keyword=remix&_c=GBK&_p=密码&_u=http%3A%2F%2Fwww.dj.com%2Fsearch.html
 */
// 目前使用的是密码授权方式；有时可以使用JSONP+域名授权方式更加便利，因为如果对方通过服务器中转使用本功能，还不如自行搭建；
$passwordFile = __FILE__ . '.password.' . md5(__FILE__ . (empty($_GET['_p']) ? '' : $_GET['_p']));
// 方便生成密码串；生成后，重命名去掉.tmp即可使用；加上tmp防止忘记删除成安全bug
//file_put_contents($passwordFile . '.tmp', $passwordFile);
/**
 * 以json格式输出内容
 * @param null $data
 * @param string $msg
 * @param string $code
 */
function response($data = null, $msg = '成功', $code = 'success')
{
    $data = [
        'msg' => $msg,
        'code' => $code,
        'data' => $data
    ];
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
/**
 * 输出并终止php
 * @param string $msg
 * @param null $data
 */
function fail($msg = '异常', $data = null)
{
    response($data, $msg, 'fail');
    exit;
}
// 比如，对方编辑是gbk，那就把utf8转成gbk再提交过去，否则对方接受到的中文是乱码
function buildQueryEncode(&$value, $key, $charset = null)
{
    if (is_string($value)) $value = mb_convert_encoding($value, $charset, 'UTF-8');
}
function buildQuery($params, $charset, $pre = '')
{
    if (empty($params)) return '';
    if (!empty($charset)) {
        array_walk_recursive($params, 'buildQueryEncode', $charset);
    }
    return $pre . http_build_query($params);
}
// 允许任何域名通过ajax访问；如果打算仅使用域名白名单方式授权，这里要修改；且对referer做域名检查；
header('Access-Control-Allow-Origin: *', true);
header('Access-Control-Allow-Methods: *', true);
header('Access-Control-Allow-Headers: *', true);
if (!file_exists($passwordFile)) {
    fail('您未授权');
}
// unset 不需要中转参数，防止产生意外
unset($_GET['_p']);
if (empty($_GET['_u'])) {
    fail('用法：?_c=对方的编码&_p=授权&_h[]=自定义请求头&_u=协议://跨域的域名/路径&...更多get参数、post会直接传递给对方');
}
$headers = [];
$charset = empty($_GET['_c']) ? null : $_GET['_c'];
unset($_GET['_c']);
if (!empty($_GET['_h'])) {
    $headers = $_GET['_h'];
    unset($_GET['_h']);
}
$url = $_GET['_u'];
unset($_GET['_u']);
$url .= buildQuery($_GET, $charset, '?');
// 用来响应给前端，后端都做了什么操作
$data = [
    'requestUri' => $url
];
$ch = curl_init($url);
$query = '';
curl_setopt($ch, CURLOPT_ACCEPT_ENCODING, 'gzip');
// 设置代理等待超时时间，防止过久，浪费服务器资源
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
// 直接使用客户端的请求浏览器信息，防止对方做了拒绝某些浏览器限制
curl_setopt($ch, CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT']);
if (!empty($_POST)) {
    // post
    $query = buildQuery($_POST, $charset);
    $data['requestMethod'] = 'POST';
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $query);
} else {
    // get
    $data['requestMethod'] = 'GET';
    curl_setopt($ch, CURLOPT_HTTPGET, true);
}
if (is_array($headers) && !empty($headers)) {
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
}
// 禁用后cURL将终止从服务端进行验证。使用CURLOPT_CAINFO选项设置证书使用CURLOPT_CAPATH选项设置证书目录 如果CURLOPT_SSL_VERIFYPEER(默认值为2)被启用，CURLOPT_SSL_VERIFYHOST需要被设置成TRUE否则设置为FALSE。
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
// 1 检查服务器SSL证书中是否存在一个公用名(common name)。译者注：公用名(Common Name)一般来讲就是填写你将要申请SSL证书的域名 (domain)或子域名(sub domain)。2 检查公用名是否存在，并且是否与提供的主机名匹配。
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
// 响应保存到变量中,不是直接输出到浏览器
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
// 启用时会将头文件的信息作为数据流输出。
curl_setopt($ch, CURLOPT_HEADER, 0);
// 显示<= http code 400的信息
curl_setopt($ch, CURLOPT_FAILONERROR, TRUE);
// 支持302
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
// 最大的重定向次数 防止出现loop
curl_setopt($ch, CURLOPT_MAXREDIRS, 5);
// 有些网站可能是gbk的，json encode会返回null
$data['response'] = mb_convert_encoding(curl_exec($ch), 'UTF-8', 'GBK,UTF-8');
$data['requestError'] = curl_errno($ch);
$data['requestMsg'] = curl_error($ch);
$data['responseHeaders'] = curl_getinfo($ch);
curl_close($ch);
response($data);

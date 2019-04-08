<?php
/**
 * 配合定时任务，可以1分钟一次上报办公室外网ip；
 * 小米路由器可以开通 shell功能，使用ssh登录，使用crontab来达到，这样小米路由就能当linux服务器
 * 请求方式
 * # 请使用时保证与php的格式一样
 * md5_text=$(date +"%Y/---/%m/---/%d/    /%H/:::/00/:::/00");
 * # echo -n   not need <rn>
 * md5_text=$(echo -n "${md5_text}"|md5sum - | awk -F ' ' '{print $1 }')
 * curl -s "http://域名/文件名.php?password=${md5_text}" >/dev/null 2>&1
 */
// 因为ip从请求中取，必须有
!empty($_SERVER['REMOTE_ADDR']) or die('your ip?');
// 授权实现
$password_key = 'password';
// 授权，误差可以在上下1个小时内
!empty($_GET[$password_key]) or die('where?');
// 获取请求者ip
$user_ip = $_SERVER['REMOTE_ADDR'];
// TODO 请注意使用时修改验证格式;加入其它特殊字符或是数字，达到安全；如果想要更加安全，建议把小时换成5分钟
$date_fm = 'Y/---/m/---/d/   /H/:::/00/:::/00';
// 误差小时前
$md5_time_pre = md5(date($date_fm, strtotime('-1 hour')));
// 请求者与服务器在同小时
$md5_time_now = md5(date($date_fm));
// 请求比服务器快一小时
$md5_time_next = md5(date($date_fm, strtotime('+1 hour')));
switch ($_GET[$password_key]) {
    // 误差在前后一小时即可通过
    case $md5_time_pre:
    case $md5_time_now:
    case $md5_time_next:
        break;
    default:
        die('who?');
}
// 如果ip变化了，就处理；否则终止
//include_once __DIR__ . '/../lib/share_memory.php';
// 共享内存保存这个信息，最大只需要这个字节数
$shmMax = 20;
$res = ShareMemory::newCreate(ShareMemory::IP_CHANGE_ID, $shmMax);
if (!$res) die('share memory error');
$old_ip = $res->readText();
if ($user_ip === $old_ip) die('same');
if (false === $res->writeText($user_ip)) die('share memory write error');
// ali yun ram用户信息
define('ACCESS_ID', 'ram用户id');
define('ACCESS_KEY', 'ram用户key');
update_rds_ip($user_ip);
update_dns_so_ip($user_ip);
function update_rds_ip($user_ip)
{
// 开始处理rds深圳办公室白名单
    line('update rds sz_office white list:');
// 阿里要的是0时差的
    $tz_0 = date("Y-m-d\TH:i:s\Z", time() - date('Z'));
    $params = [
// 方法是修改ip
        'Action' => 'ModifySecurityIps',
        // 替换式
        'ModifyMode' => 'Cover',
        // rds实名
        'DBInstanceId' => 'rds实例id',
        // 新ip
        'SecurityIps' => $user_ip,
        // 白名单分组名
        'DBInstanceIPArrayName' => '白名单分组名',
        'Format' => 'JSON',
        'Version' => '2014-08-15',
        'AccessKeyId' => ACCESS_ID,
        'SignatureMethod' => 'HMAC-SHA1',
        'Timestamp' => $tz_0,
        'SignatureVersion' => '1.0',
        // 必须每次请求不同
        'SignatureNonce' => uniqid('rds' . microtime(true) . rand(), true)
    ];
    foreach ($params as $k => $v) $params_2[] = urlencode($k) . '=' . urlencode($v);
// 按字母顺序排列
    sort($params_2);
// 按要求格式拼接
    $sign_data = 'GET' . '&' . urlencode('/') . '&' . urlencode(implode('&', $params_2));
// 使用sha1签名
    $sign = hash_hmac('SHA1', $sign_data, ACCESS_KEY . '&', true);
// 对方要的是base64
    $sign = base64_encode($sign);
    $params_2[] = 'Signature=' . urlencode($sign);
    $url = 'http://rds.aliyuncs.com/';
    $params = implode('&', $params_2);
    $url = $url . '?' . $params;
    //   line($url);
    curl($url);
}
function update_dns_so_ip($user_ip)
{
// 更新 so.0.域名解析ip
    line('update so.0 ip:');
// 阿里要的是0时差的
    $tz_0 = date("Y-m-d\TH:i:s\Z", time() - date('Z'));
    $params = [
// 方法是修改ip
        'Action' => 'UpdateDomainRecord',
        // 记录id，打开浏览器的network，找到它修改保存，即可看到
        'RecordId' => '记录id',
        // 记录名
        'RR' => 'so.0',
        // 新ip
        'Value' => $user_ip,
        // 记录类型
        'Type' => 'A',
        'Format' => 'JSON',
        'Version' => '2015-01-09',
        'AccessKeyId' => ACCESS_ID,
        'SignatureMethod' => 'HMAC-SHA1',
        'Timestamp' => $tz_0,
        'SignatureVersion' => '1.0',
        // 必须每次请求不同
        'SignatureNonce' => uniqid('dns' . microtime(true) . rand(), true)
    ];
    foreach ($params as $k => $v) $params_2[] = urlencode($k) . '=' . urlencode($v);
// 按字母顺序排列
    sort($params_2);
// 按要求格式拼接
    $sign_data = 'GET' . '&' . urlencode('/') . '&' . urlencode(implode('&', $params_2));
// 使用sha1签名
    $sign = hash_hmac('SHA1', $sign_data, ACCESS_KEY . '&', true);
// 对方要的是base64
    $sign = base64_encode($sign);
    $params_2[] = 'Signature=' . urlencode($sign);
    $url = 'http://alidns.aliyuncs.com/';
    $params = implode('&', $params_2);
    $url = $url . '?' . $params;
    //  line($url);
    curl($url);
}
/**
 * curl 请求实现
 * @param $url
 */
function curl($url)
{
    $url = trim($url);
    if (!preg_match("/^https?\:\/\/.+/", $url)) {
        line('curl请求的url必须使用绝对路径，本次请求url：' . $url);
        return;
    }
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_MAXREDIRS, 5); // 最大的重定向次数
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    if (false === $result || curl_errno($ch)) {
        line('error :' . curl_error($ch));
        return;
    }
    if ('200' != $httpCode) {
        line('code = ' . $httpCode . "\n" . $result);
        return;
    }
    curl_close($ch);
    line($result);
}
function line($txt)
{
    echo $txt . chr(10);
}
// 共享内存类
/**
 * php的共享内存操作类
 *
 * 注意这里的内存单位是按字节来计算的，并不是按照字符来计算，比如 中 字就占用3个，而  a 字只占用1个；可以使用本类提供的方法来得到字符长度
 *
 * 在mac（类linux），可以使用ipcs -m 列举；使用ipcrm -M key 来删除
 */
class ShareMemory
{
    /** @var int ip 改变处理 */
    const IP_CHANGE_ID = 1;
    private $resource = null;
    // 因为shmop的id是系统级，为了防止与其它的共享应用冲突id，这里要加上php路径做前缀
    static private $phpKey = 0;
    /**
     * 转化成安全的key
     * @param $key
     * @return int
     */
    static public function toKey($key)
    {
        if (!static::$phpKey) {
            static::$phpKey = (int)ftok(__FILE__, 't');
        }
        return static::$phpKey + $key;
    }
    /**
     * 获取一串字符的字节长度
     * @param string $str
     * @return int
     */
    static public function getStrBytes($str = '')
    {
        if (!is_string($str)) {
            return 0;
        }
        return mb_strlen($str);
    }
    /**
     * 以只读模式创建
     * @param int $key
     * @return bool|ShareMemory
     */
    static public function newRead($key)
    {
        $key = static::toKey($key);
        // 访问模式，后面2个参数设置成0
        $res = @shmop_open($key, 'a', 0, 0);
        if (!$res) {
            return false;
        }
        $newer = new static;
        $newer->resource = $res;
        return $newer;
    }
    /**
     * 如果不存在，就创建；
     * 如果存在，就直接读,因为读取时，如果指定的bytes值比创建时大，就导致读取失败，比小能正常读取，应该是忽略了参数，也就是说，没有扩容功能；
     * 根据这个方法的特点，建议是不要考虑扩容，必须第一次创建就要想好最大容量
     * @param $key
     * @param int $createBytes 注意，这个值只对不存在创建时有效，已经存在的，将忽略，不要误以为传了，也能改变已存在的大小
     * @param int $createMode 注意这个值只对创建时有效
     * @return bool|ShareMemory
     */
    static public function newCreate($key, $createBytes, $createMode = 0644)
    {
        $key = static::toKey($key);
        $res = @shmop_open($key, 'c', $createMode, $createBytes);
        if (!$res) {
            // 尝试是不是已经存在，参数超出创建时大小导致获取不到，那就用读模式试下。
            $res = self::newRead($key);
            return $res;
        }
        $newer = new static;
        $newer->resource = $res;
        return $newer;
    }
    /**
     * 读写模式，如果不存在，返回false
     *
     * @param $key
     * @return bool|ShareMemory
     */
    static public function newWrite($key)
    {
        $key = static::toKey($key);
        // 访问模式，后面2个参数设置成0
        $res = @shmop_open($key, 'w', 0, 0);
        if (!$res) {
            return false;
        }
        $newer = new static;
        $newer->resource = $res;
        return $newer;
    }
    /**
     * 只有不存在时，才能创建，否则返回false
     * @param $key
     * @param $bytes
     * @param int $mode
     * @return bool|ShareMemory
     */
    static public function newNew($key, $bytes, $mode = 0644)
    {
        $key = static::toKey($key);
        // 访问模式，后面2个参数设置成0
        $res = @shmop_open($key, 'n', $mode, $bytes);
        if (!$res) {
            return false;
        }
        $newer = new static;
        $newer->resource = $res;
        return $newer;
    }
    /**
     * 写入
     * @param string $data 如果长度超出容量，就会丢失后面内容,比如长度为2，放一个中文，它就只保留中文的前2个字节
     * @return int|bool 若空间不足，就返回 false
     */
    public function writeText($data = '')
    {
        if (empty($data) || !is_string($data) || !$this->resource) {
            return 0;
        }
        // 因为写入是从左按位替换的，会出现如下情况：内存原来内容为 abcdefg，新内容为123，写入后内容就会变成123defg，所以，这里使用空字符占位
        //$strLen = self::getStrBytes($data);
        // 内存长度
        $memLen = self::getBytes();
        // 要使用空字符填充后边空间
        return @shmop_write($this->resource, str_pad($data, $memLen, chr(0), STR_PAD_RIGHT), 0);
    }
    /**
     * 读出,读出的内容好像还包含了后面内存空白
     * @param null $count
     * @param int $start
     * @return string
     */
    public function readText($count = null, $start = 0)
    {
        if (!$this->resource) {
            return '';
        }
        if (!($count > 0)) {
            // 若没有提供读的数量，就获取
            $count = $this->getBytes();
        }
        if ($start < 0) {
            $start = 0;
        }
        $text = @shmop_read($this->resource, $start, $count);
        if (is_string($text)) {
            // 读取时，会把\0字符读出，所以要删除
            $text = str_replace(chr(0), '', $text);
        }
        return $text;
    }
    /**
     * 获取内存占用空间
     * @return int
     */
    public function getBytes()
    {
        $size = 0;
        if ($this->resource) {
            // 只有初始化成功时，才处理
            $size = @shmop_size($this->resource);
        }
        return $size;
    }
    /**
     * 删除内存条目
     * @return bool
     */
    public function delete()
    {
        if ($this->resource) {
            $result = @shmop_delete($this->resource);
            // 防止折构时，再关闭一下
            $this->resource = null;
            return $result;
        }
        return false;
    }
    /**
     * 类结束要自动关闭句柄
     * 关闭是自动关闭了，所以，不提供关闭方法
     */
    public function __destruct()
    {
        if ($this->resource) {
            @shmop_close($this->resource);
        }
    }
}

nginxDir="/-/soft/nginx";

# exit2fail 上个命令退出值   退出提示[操作失败]   退出码[1]
function exit2fail () {
    if [[ "$1" -ne "0" ]];then
        if [[ -z "$2" ]];then
            echo "操作失败";
        else
            echo "$2";
        fi

        if [[ -z "$3" ]];then 
            exit 1;
        else
            exit $3;
        fi
    fi
}

# 目录不存在就退出，参数1为目录路径
function exit2notDir() {
    if [[ ! -d  "${1}" ]];then
        echo "目录 [${1}] 不存在";
        exit 2;
    fi
}

exit2notDir "$nginxDir"

echo "需要修改openssl的config成./Configure darwin64-x86_64-cc \$@; 因为opens的config默认是386的，nginx却要求64位；同时openssl不能有编译好的东西。否则在nginx调用make clean时出错，先rm 编译完了nginx再编译openssl"
openssl="${nginxDir}/../openssl"
exit2notDir $openssl
pcre="${nginxDir}/../pcre"
exit2notDir $pcre

cd "${nginxDir}";
bash configure \
--prefix=${nginxDir}/qidizi \
--http-client-body-temp-path=/tmp/nginx.client_body_temp \
--http-proxy-temp-path=/tmp/nginx.proxy_temp \
--http-fastcgi-temp-path=/tmp/nginx.fastcgi_temp \
--http-uwsgi-temp-path=/tmp/nginx.uwsgi_temp \
--http-scgi-temp-path=/tmp/nginx.scgi_temp \
--http-log-path=/tmp/nginx.access \
--error-log-path=/tmp/nginx.error \
--without-select_module \
--without-poll_module \
--with-threads \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_addition_module \
--with-http_sub_module \
--with-http_gunzip_module \
--with-http_auth_request_module \
--with-http_secure_link_module \
--with-pcre=${pcre} \
--with-pcre-jit \
--with-openssl=${openssl} \
;
exit2fail $?
make 
exit2fail $?
make install
exit2fail $?
echo -e "\n\n\n ${nginxBuild} build成功"


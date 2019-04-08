// 本方法更新到 https://github.com/qidizi/memo/edit/master/docs/browser_helper.js
function browser_helper(user, password) {
    // 用来加载阿里code插件
    try {
        let sign = 'https://signin.aliyun.com', code = 'https://code.aliyun.com';

        // 处于登录页
        if (location.href.indexOf(sign) === 0) {
            let form = $('form.login-form').get(0);
            $('#user_principal_name').val(user);
            $('#password_ims').val(password);
            form.onsubmit = null;

            if (/captcha/i.test(form.innerHTML)) {
                // 有验证码，需要人工输入
                alert('有验证码，无法自动登录\n成功登录后，请再次点击执行');
            } else {
                // 可以自动登录
                alert('登录中...请稍候执行');
                form.submit();
            }

            return;
        }

        let url = code + '/qidizi/browser_helper/raw/master/helper.js?r=' + +new Date;
        // 处于code页
        xhr(
            url,
            null,
            function (t) {
                try {
                    +new Function('', t)();
                } catch (e) {
                    alert('执行如下url代码失败：' + url);
                }
            },
            function (e) {
                alert('请求如下网址失败：' + e + '\n' + url);
            }
        );

        function xhr(url, post_string, ok_cb, fail_cb, method) {
            let req = new XMLHttpRequest();
            req.open(method || 'GET', url);
            // 无超时
            req.timeout = 0;
            req.responseType = 'text';
            req.onreadystatechange = function () {
                if (req.readyState === XMLHttpRequest.DONE) {
                    //console.log('responseURL', req.responseURL, 'getAllResponseHeaders', req.getAllResponseHeaders());
                    if (200 === req.status) {
                        'function' === typeof ok_cb && ok_cb.call(req, req.response);
                    } else {
                        'function' === typeof fail_cb && fail_cb.call(req, req.status + ' ' + req.statusText);
                    }
                }
            };
            req.send(post_string || null);
        }
    } catch (e) {
        alert('执行browser_helper.js出错：' + e);
    }
}

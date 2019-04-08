

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
                alert('成功登录后，请再次点击执行');
                form.submit();
            }

            return;
        }

        // 处于code页
        xhr(
            code + '/qidizi/browser_helper/raw/master/helper.js?r=' + +new Date,
            function (t) {
                +new Function('', t)();
            }
        );
    } catch (e) {
        alert('执行出错：' + e);
    }


    function xhr(url, func, post_string, method) {
        let req = new XMLHttpRequest();
        req.open(method || 'GET', url);
        // 无超时
        req.timeout = 0;
        req.responseType = 'text';
        req.onreadystatechange = function () {
            if (req.readyState === XMLHttpRequest.DONE && req.status === 200) {
                //console.log('responseURL', req.responseURL, 'getAllResponseHeaders', req.getAllResponseHeaders());
                'function' === typeof func && func.call(req, req.response);
            }
        };
        req.send(post_string || null);
    }
}

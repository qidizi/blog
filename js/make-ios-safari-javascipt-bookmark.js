// 制作ios safari书签javascript协议的网址，因为ios safari会对某些字符转义，导致无法正常添加javascript书签。
// 这些字符比如中括号[],单双引号"

    function javascriptCode() {
        document.write('<' + 'script src="https://raw.githubusercontent.com/qidizi/djPlayer/master/insert.js?r=' + (+new Date) + '"><' + '/script>');
    }

    var str = String(javascriptCode).replace(/^[^{]+{|\}\s*$/g, '').replace(/[\r\n]+|^\s+|\s+$/gm, '');
    var code = [];

    for (var i = 0; i < str.length; i++) {
        code.push(str.charCodeAt(i));
    }
    var url = 'javascript:eval(String.fromCharCode(' + code + '));';
    prompt('请复制下面代码做为书签网址',url);

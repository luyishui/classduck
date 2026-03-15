function request(tag, data, url,token) {
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, false);
    //xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.setRequestHeader("token", token);
    xhr.send(data);
    return ss;
}

function base64Encode(input){
    var _keys = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    //if (this.is_unicode) input = this._u2a(input);
    var output = '';
    var chr1, chr2, chr3 = '';
    var enc1, enc2, enc3, enc4 = '';
    var i = 0;
    do {
        chr1 = input.charCodeAt(i++);
        chr2 = input.charCodeAt(i++);
        chr3 = input.charCodeAt(i++);
        enc1 = chr1 >> 2;
        enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
        enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
        enc4 = chr3 & 63;
        if (isNaN(chr2)){
            enc3 = enc4 = 64;
        } else if (isNaN(chr3)){
            enc4 = 64;
        }
        output = output+_keys.charAt(enc1)+_keys.charAt(enc2)+_keys.charAt(enc3)+_keys.charAt(enc4);
        chr1 = chr2 = chr3 = '';
        enc1 = enc2 = enc3 = enc4 = '';
    } while (i < input.length);
    return output;
};

let info = JSON.parse(request("get",null,"http://172.20.0.144/hxxyjw/jw/common/showYearTerm.action"));
let courseTable = request("get",null,"http://172.20.0.144/hxxyjw/student/wsxk.xskcb10319.jsp?params="+base64Encode("xn="+info.xn+"&xq="+info.xqM+"&xh="+info.userCode));
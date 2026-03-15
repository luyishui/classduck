function Base64() {

    // private property
    _keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    // public method for encoding
    this.encode = function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;
        input = _utf8_encode(input);
        while (i < input.length) {
            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);
            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;
            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }
            output = output +
                _keyStr.charAt(enc1) + _keyStr.charAt(enc2) +
                _keyStr.charAt(enc3) + _keyStr.charAt(enc4);
        }
        return output;
    }

    // public method for decoding
    this.decode = function (input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
        while (i < input.length) {
            enc1 = _keyStr.indexOf(input.charAt(i++));
            enc2 = _keyStr.indexOf(input.charAt(i++));
            enc3 = _keyStr.indexOf(input.charAt(i++));
            enc4 = _keyStr.indexOf(input.charAt(i++));
            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;
            output = output + String.fromCharCode(chr1);
            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }
        }
        output = _utf8_decode(output);
        return output;
    }

    // private method for UTF-8 encoding
    _utf8_encode = function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";
        for (var n = 0; n < string.length; n++) {
            var c = string.charCodeAt(n);
            if (c < 128) {
                utftext += String.fromCharCode(c);
            } else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            } else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }
        return utftext;
    }

    // private method for UTF-8 decoding
    _utf8_decode = function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;
        while ( i < utftext.length ) {
            c = utftext.charCodeAt(i);
            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            } else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            } else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }
        }
        return string;
    }
}
function getSjarr(sha,dom,prul){
    let username = prompt("请输入用户名")
    let pas = prompt("请输入密码")
    // pas = CryptoJS.SHA1(sha+pas)
    pas = new Base64().encode(sha+pas)
    let data
    if(dom.getElementsByClassName("verity-image").length != 0){
        let yzm = prompt("请输入页面验证码")
        data = "username="+username+"&password="+pas+"&encodedPassword=&captcha_response="+yzm+"&session_locale=zh_CN"
    }
    else{
        data = "username="+username+"&password="+pas+"&encodedPassword=&session_locale=zh_CN"
    }
    if(username == null || username.length == 0){
        return false;
    }
    else{
        request("post",data,prul+'/eams-shuju/login.action');
        return getSjarr1(prul)
    }

}
function request(tag, data, url) {
    let ss = "";
    var xhr;
    if (window.XMLHttpRequest)
    {// code for IE7+, Firefox, Chrome, Opera, Safari
        xhr=new XMLHttpRequest();
    }
    else
    {// code for IE6, IE5
        xhr=new ActiveXObject("Microsoft.XMLHTTP");
    }

    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded;charset=utf8");
    xhr.send(data);
    return ss;
}

function getSjarr1(preUrl){
    let sjarr=[]
    let idurl = preUrl+'/eams-shuju/courseTableForStd.action'
    let kctitle = request("get",null,idurl)

    //let semesterBar_Semester = "semesterBar"+kctitle.match(/(?<=semesterBar).*?(?=Semester)/)[0]+"Semester"
    let semesterBar_Semester = "projectUI"+kctitle.match(/(?<=projectUI).*?(?=Semester)/)[0]+"Semester"

    let value1 = kctitle.match(/(?<=value:").*?(?=")/)[0]
    let xqurl = preUrl+"/eams-shuju/dataQuery.action"
    let xqdata = "tagId="+semesterBar_Semester+"&dataType=semesterCalendar&value="+value1+"&empty=false"
    let xqjson = request("post",xqdata,xqurl)
    xqjson = eval("("+xqjson.replace(new RegExp("\r\n","gm"), "").replace(new RegExp("\n","gm"), "")+")");
    xqid = xqjson.semesterId

    id = kctitle.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)
    if(id==null) alert("ids匹配有误")
    let data1 ="ignoreHead=1&setting.kind=std&startWeek=&semester.id="+xqid+"&ids="+id
    let urll = preUrl+"/eams-shuju/courseTableForStd!courseTable.action"
    let sj = request("post",data1,urll)
    //console.log(sj)
    return sj.match(/(?<=new TaskActivity\().*?(?=\);)|(?<=unitCount\+).*?(?=;)|(?<=index \=).*?(?=\*unitCount)/g)
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let jg =
        ` >>>导入流程（cas版）<<<
   1.在登录页面点击统一身份认证
   2.在跳转后的页面最下方，输入账号密码
   3.点击登录
   4.选择教务系统
   5.在跳转后的空白页面（上方有姓名），点击一键导入
    >>>导入流程（普通）<<<
    (退出系统后，请等待30秒在进行尝试登录)
    1、在登录页面点击一键导入
    2、输入账号密码
    3、等待导入完成
  
   `
    alert(jg)
    //  let preUrl1 = location.href.replace("/eams/homeExt.action","")
    let preUrl = location.href.split("/").slice(0,-2).join("/")
    console.log(preUrl)
    let arr = []
    let kcar = []
    let message = ""
    let kc = {weeks:[],sections:[]}
    // arr = getSjarr1(preUrl)
    try{
        if(location.href!="https://jw.sandau.edu.cn/eams-shuju/login.action"){
            arr = getSjarr1(preUrl);
        }
        else{
            var loginHtm=document.getElementsByTagName('html')[0].innerHTML;
            let sha = loginHtm.match(/(?<=b.encode\(").*?(?=")/)[0];
            arr =getSjarr(sha,dom,preUrl);
            let i = 0;
            if(!arr||arr ==null && i<=1){
                alert("用户名或密码有误，请退出重新进入");
                return;
            }
        }

        console.log(arr)
        let weekTag = true;
        for(let i = 0;i< arr.length;i++){
            let line = arr[i]
            if(line.length>=53){
                if(i!=0){
                    kcar.push(JSON.parse(JSON.stringify(kc)))
                    kc = {weeks:[],sections:[]}
                }
                let courseCon = line.split(/(?<="),(?=")/).filter(function (s) {return s && s.trim();})
                kc.teacherName = courseCon[1].replace(/"/g,"")
                kc.courseName = courseCon[3].replace(/"/g,"")
                kc.roomName = courseCon[5].replace(/"/g,"")
                courseCon[6] = courseCon[6].replace(/"/g,"")
                courseCon[6].split("").forEach((em,index) => {
                    if( em == 1) kc.weeks.push(index)
                })
            }
            else {
                if (weekTag){
                    kc.day = Number(line)+1
                    weekTag = false
                }
                else{
                    kc.sections.push({section:Number(line)>5?Number(line)-1:Number(line)+1})
                    weekTag = true;
                }
            }
        }

        kc.teacherName&&kcar.push(kc)

        if(kcar.length ==0 ) message="未获取到课表"
    }catch(e){
        console.log(e)
        message=e.message.slice(0,50)
    }
    if(message.length!=0){
        kcar.length=0;
        kcar.push({courseName:"遇到错误,请加群:628325112,找开发者进行反馈",teacherName:"开发者-萧萧",roomName:message,day:1,weeks:[1],sections:[{section:1},{section:2}]})
    }
    console.log(kcar)
    return JSON.stringify(kcar)
}
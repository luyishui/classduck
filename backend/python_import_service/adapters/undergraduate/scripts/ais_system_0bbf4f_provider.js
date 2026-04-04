// Source: 参考文件/aishedule-master/树维/河南理工大学/provider.js

let  loadTools=  async (url) => {
    let jsStr = await request("get",null,url)
    console.log(jsStr)
    window.eval(jsStr)
}
function encrypt(content, key){
    var sKey = AesJS.enc.Utf8.parse(key);
    var sContent = AesJS.enc.Utf8.parse(content);
    var encrypted = AesJS.AES.encrypt(sContent, sKey, {mode:AesJS.mode.ECB,padding: AesJS.pad.Pkcs7});
    return encrypted.toString();
}
let textToDom = (text) => {
    let parser = new DOMParser()
    return parser.parseFromString(text,"text/html")
}
//添加img元素
let addImg = (url) =>{
    let addInterval = setInterval(addFun,"100")
    function addFun () {
        let aiDiv = document.getElementsByTagName("ai-schedule-div")
        if(aiDiv.length!=0){
            let img = document.createElement("img")
            img.src = url;
            img.style.cssText = "display: block; width: 50%; max-width: 200px; min-height: 11vw; max-height: 6vh; position: relative; overflow: auto; margin-top:0vh; padding: 2vw;"
            img.setAttribute("onclick","this.src='"+url+"'")
            aiDiv[2].appendChild(img)
            clearInterval(addInterval)
        }
    }

}
async function getSjarr(sha, aes,dom, prul,urls) {

    let username = document.getElementById("username").value
    let pas = document.getElementById("password").value

    username = !username ? await AISchedulePrompt({
        titleText: "请输入用户名",
        tipText: "",
        defaultText: "",
        validator: (username) => { if(!username) return "用户名输入有误";else return false }
    }) :username;
pas = !pas ? await AISchedulePrompt({
        titleText: "请输入密码",
        tipText: "",
        defaultText: "",
        validator: (password) => { if(!password) return "密码输入有误";else return false }
    }):pas;
    pas =  CryptoJS.SHA1(sha + pas);
    username = encrypt(username,aes)
//  pas = new Base64().encode(sha+pas)
    let loginData = new FormData()
    loginData.set("username", username)
    loginData.set("password", pas)
    loginData.set("pwd", pas)
    loginData.set("session_locale", "zh_CN")

    let vim = dom.getElementsByClassName("verity-image")
    let cr = dom.getElementsByClassName("captcha_response")
// alert(vim.length != 0 || cr.length != 0)
    if (vim.length != 0 || cr.length != 0) {
        addImg(!vim.length?cr[0].nextElementSibling.src:vim[0].childNodes[0].src)
        loginData.set("encodedPassword=","")
        loginData.set("captcha_response",
            await AISchedulePrompt({
                titleText: "请输入页面验证码",
                tipText: "",
                defaultText: "",
                validator:  (yzm) => { if(!yzm) return "验证码输入有误";else return false }
            })
        )

    }
    if (username == null || username.length == 0) {
        return false;
    } else {

        let logRe = await request("POST", loginData, prul + urls.login);
        console.log(logRe)
        let tdom = textToDom(logRe);
        let errtext = tdom.getElementsByClassName("actionError")
        if(!!errtext.length) {
            await AIScheduleAlert({
                contentText: errtext[0].innerText+">>>请退出重新进入<<<",
                titleText: '错误',
                confirmText: '确认',
            })
            return ""
        }
        console.info("登录中。。。")
        return getSjarr1(prul);
    }

}

async function request(method, data, url) {
    return await fetch(url, { method: method, body: data }).then(v => v.text()).then(v => v).catch(v => v)
}
function sleep(timeout) {
    for (let t = Date.now(); Date.now() - t <= timeout * 1000;);
}

async function getSemestersId(preUrl, courseTableCon) {
    let semesterIds = []
    let mess = "";
    let xqurl = preUrl + "/dataQuery.action";

    let xqdata = new FormData()
    xqdata.set("tagId", "semesterBar" + courseTableCon.match(/(?<=semesterBar).*?(?=Semester)/)[0] + "Semester")
    xqdata.set("dataType", "semesterCalendar")
    xqdata.set("value", courseTableCon.match(/(?<=value:").*?(?=")/)[0])
    xqdata.set("empty", false)

    let currentYear = new Date().getFullYear();
    let semesters = eval("(" + await request("post", xqdata, xqurl) + ")").semesters;
    let count = 0;
    let semesterIndexTag = 0
    let selectList =[]
    console.log(semesters)

    for (key in semesters) {
        if (semesters[key][0].schoolYear.search(currentYear) != -1) {
            for (let key1 in semesters[key]) {
                let semId = semesters[key][key1]
                selectList.push( (semesterIndexTag++) +":"+semId['schoolYear'] + '学年' + semId['name'] + "学期")                
                semesterIds.push(semesters[key][key1]['id']);
            }
            if (++count == 2) break;
        }
    }
    
    let semesterIndex = (await AIScheduleSelect({
        titleText:"学期",
        contentText:"请选择当前学期",
        selectList:selectList
    })).split(":")[0]
    
    console.log(semesterIndex)     
    return {
        'semesterIds': semesterIds,
        'semesterIndex': semesterIndex
    }
}


async function getSjarr1(preUrl) {
    sleep(0.35)
    let idurl = preUrl + '/courseTableForStd.action';
    let courseTableCon = await request("get", null, idurl);
    console.info("获取学期中。。。")
    // alert(idurl)
    // alert(courseTableCon)
    // alert(await request("get", null, idurl))
    let semIdsJson =  await getSemestersId(preUrl, courseTableCon);

    console.log(semIdsJson.semesterIds)
    
    let ids = courseTableCon.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)[0];
    console.info("获取ids中。。。")
    if (ids == null) { alert("ids匹配有误"); return }
    console.info("获取到ids", ids)

    let courseArr = [];
    let i = semIdsJson.semesterIndex;
    while (courseArr.length <= 1 && i >= 0) {
        sleep(0.4)
        console.info("正在查询课表", semIdsJson.semesterIds[i])
        
        let formData = new FormData();
        formData.set("ignoreHead", 1)
        formData.set("setting.kind", "std")
        formData.set("startWeek", "")
        formData.set("semester.id", semIdsJson.semesterIds[i])
        formData.set("ids", ids)      
        let url = preUrl + "/courseTableForStd!courseTable.action";
        courseArr = (await request("post", formData, url)).split(/var teachers = \[.*?\];/);
        i--;
    }

    return courseArr;
}

function distinct(arr) {
    return Array.from(new Set(arr));
}

async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    //await loadTools("https://cdn.bootcss.com/vConsole/3.2.0/vconsole.min.js")
    //new VConsole()
    await loadTool('AIScheduleTools')

    let warning =
        `
    >>>导入流程<<<
    1、从统一认证身份认证页面登录
    2、登陆后直接点击一建导入
    3、在弹框中输入教务系统的账号，密码，验证码
    4、选择学期信息，点击确定
    5、大概需要等待5秒左右，导入完成后会自动跳转
    注意：导入完成后，注意检查时间和课程是否正确！！！      
    `
    await AIScheduleAlert(warning)

    let message = ""
    //alert("请确保你已经连接到校园网！！")
    let urlar = location.href.split("/")
    !urlar[urlar.length-1]&&urlar.pop()
    let verTag = urlar.pop()
    let preUrl = urlar.join("/");
    // alert(location.href)
    // alert(urlar.toString())
    // alert(preUrl)
    // location.href.split("/").slice(0, -2).join("/");
    let urls1={
        "home":"/homeExt.action",
        "login":"/loginExt.action",
        "loginTableClassName":"login-table"
    }
    let urls2={
        "home":"/home.action",
        "login":"/login.action",
        "loginTableClassName":"logintable"
    }
    let urls = verTag.search("Ext")===-1?urls2:urls1;   
    let courseArr = [];
    let arr = []
    try {
        //验证是否登录
        let homeText = await request("get",null,preUrl + urls.home)
        let homeDom = await textToDom(homeText)
        let logintag = homeDom.getElementsByClassName(urls.loginTableClassName).length
        console.log("home"+homeDom)
    //    alert(preUrl+urls.login)
        sleep(0.5)

        if (location.href.search("cas/login") != -1) { 
            await AIScheduleAlert("请登录。。。");
            return "do not continue"
        }
        else if (!logintag || location.href.split(";")[0] != preUrl+urls.login) {
            // alert("go")
            arr = await getSjarr1(preUrl);
        }
        else {
            // alert( location.href != preUrl+urls.login)
            await loadTools("/eams/static/scripts/aes.min.js")
            await loadTools("/eams/static/scripts/sha1.js")
            let sha = homeText.match(/(?<=CryptoJS\.SHA1\(').*?(?=')/)[0];
            let aes =  homeText.match(/(?<=encrypt\(username,').*?(?=')/)[0];
            // let sha = loginHtm.match(/(?<=b.encode\(").*?(?=")/)[0];
            arr = await getSjarr(sha, aes,homeDom, preUrl,urls);
            if (!arr) {
                return "do not continue";
            }
        }
        if (arr.length >= 1) {
            arr.slice(1).forEach(courseText => {
                let course = { weeks: [], sections: [] };
                console.log(courseText)
                let orArr = courseText.match(/(?<=actTeacherName.join\(','\),).*?(?=\);)/g);
                let day = distinct(courseText.match(/(?<=index \=).*?(?=\*unitCount)/g));
                let section = distinct(courseText.match(/(?<=unitCount\+).*?(?=;)/g));
                let teacher = distinct(courseText.match(/(?<=name:").*?(?=")/g));
                console.log(orArr, day, section, teacher)
                let courseCon = orArr[0].split(/(?<="|l|e),(?="|n|a)/)
                console.log(courseCon)
                course.courseName = courseCon[1].replace(/"/g, "")
                course.roomName = courseCon[3].replace(/"/g, "")
                course.teacherName = teacher.join(",")
                courseCon[4] = courseCon[4].split(",")[0].replace('"', "")
                courseCon[4].split("").forEach((em, index) => {
                    if (em == 1) course.weeks.push(index);
                })
                course.day = Number(day) + 1;
                section.forEach(con => {
                    course.sections.push(Number(con) + 1 )
                })
                console.log(course)
                courseArr.push(course)
            })
            if (courseArr.length == 0) message = "未获取到课表"
        } else {
            message = "未获取到课表"
        }

    } catch (e) {
        console.log(e)
        message = e.message.slice(0, 50)
    }
    if (message.length != 0) {
        courseArr.length = 0;
        courseArr.push({ courseName: "遇到错误,请加群:628325112,找开发者进行反馈", teacherName: "开发者-萧萧", roomName: message, day: 1, weeks: [1], sections: [{ section: 1 }, { section: 2 }, { section: 3 }] })
    }
    console.log(courseArr)
    return JSON.stringify(courseArr);
}

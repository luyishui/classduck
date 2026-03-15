 
  function SHA1(s) {
    function encodeUTF8(s) {
        var i, r = [], c, x;
        for (i = 0; i < s.length; i++)
            if ((c = s.charCodeAt(i)) < 0x80) r.push(c);
            else if (c < 0x800) r.push(0xC0 + (c >> 6 & 0x1F), 0x80 + (c & 0x3F));
            else {
                if ((x = c ^ 0xD800) >> 10 == 0) //对四字节UTF-16转换为Unicode
                    c = (x << 10) + (s.charCodeAt(++i) ^ 0xDC00) + 0x10000,
                        r.push(0xF0 + (c >> 18 & 0x7), 0x80 + (c >> 12 & 0x3F));
                else r.push(0xE0 + (c >> 12 & 0xF));
                r.push(0x80 + (c >> 6 & 0x3F), 0x80 + (c & 0x3F));
            };
        return r;
    }
    var data = new Uint8Array(encodeUTF8(s))
    var i, j, t;
    var l = ((data.length + 8) >>> 6 << 4) + 16, s = new Uint8Array(l << 2);
    s.set(new Uint8Array(data.buffer)), s = new Uint32Array(s.buffer);
    for (t = new DataView(s.buffer), i = 0; i < l; i++)s[i] = t.getUint32(i << 2);
    s[data.length >> 2] |= 0x80 << (24 - (data.length & 3) * 8);
    s[l - 1] = data.length << 3;
    var w = [], f = [
        function () { return m[1] & m[2] | ~m[1] & m[3]; },
        function () { return m[1] ^ m[2] ^ m[3]; },
        function () { return m[1] & m[2] | m[1] & m[3] | m[2] & m[3]; },
        function () { return m[1] ^ m[2] ^ m[3]; }
    ], rol = function (n, c) { return n << c | n >>> (32 - c); },
        k = [1518500249, 1859775393, -1894007588, -899497514],
        m = [1732584193, -271733879, null, null, -1009589776];
    m[2] = ~m[0], m[3] = ~m[1];
    for (i = 0; i < s.length; i += 16) {
        var o = m.slice(0);
        for (j = 0; j < 80; j++)
            w[j] = j < 16 ? s[i + j] : rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1),
                t = rol(m[0], 5) + f[j / 20 | 0]() + m[4] + w[j] + k[j / 20 | 0] | 0,
                m[1] = rol(m[1], 30), m.pop(), m.unshift(t);
        for (j = 0; j < 5; j++)m[j] = m[j] + o[j] | 0;
    };
    t = new DataView(new Uint32Array(m).buffer);
    for (var i = 0; i < 5; i++)m[i] = t.getUint32(i << 2);

    var hex = Array.prototype.map.call(new Uint8Array(new Uint32Array(m).buffer), function (e) {
        return (e < 16 ? "0" : "") + e.toString(16);
    }).join("");
    return hex;
}

async function getSjarr(sha, dom, prul) {


    let username = await AISchedulePrompt({
        titleText: "请输入用户名",
        tipText: "",
        defaultText: "",
        validator: () => { return false; }
    })
    let pas = await AISchedulePrompt({
        titleText: "请输入密码",
        tipText: "",
        defaultText: "",
        validator: () => { return false; }
    })
    //pas = CryptoJS.SHA1(sha + pas);

    let loginData = new FormData()
    loginData.set("username", username)
    loginData.set("password", pas)
    loginData.set("pwd", pas)
    loginData.set("session_locale", "zh_CN")

    if (dom.getElementsByClassName("verity-image").length != 0 || dom.getElementsByClassName("captcha_response").length != 0) {
        loginData.set("encodedPassword=","")
        loginData.set("captcha_response",
            await AISchedulePrompt({
                titleText: "请输入页面验证码",
                tipText: "",
                defaultText: "",
                validator: () => { return false; }
            })
        )

    }
    if (username == null || username.length == 0) {
        return false;
    } else {
        await request("POST", loginData, prul + '/eams/login.action');
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
    let xqurl = preUrl + "/eams/dataQuery.action";

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
    let idurl = preUrl + '/eams/courseTableForStd.action';
    let courseTableCon = await request("get", null, idurl);
    console.info("获取学期中。。。")

    let semIdsJson = await getSemestersId(preUrl, courseTableCon);

    console.log(semIdsJson.semesterIds)

    let ids = courseTableCon.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)[0];
    console.info("获取ids中。。。")
    if (ids == null) { alert("ids匹配有误"); return }
    console.info("获取到ids", ids)

    let courseArr = [];
    let i = semIdsJson.semesterIndex;
      while ((courseArr == null || courseArr.length <= 1) && i >= 0) {
        sleep(0.4)
        console.info("正在查询课表", semIdsJson.semesterIds[i])
        let data2 = new FormData();
        data2.set("ignoreHead", 1)
        data2.set("setting.kind", "std")
        data2.set("startWeek", "")
        data2.set("semester.id", semIdsJson.semesterIds[i])
        data2.set("ids", ids)
        let url = preUrl + "/eams/courseTableForStd!courseTable.action";
        courseArr = (await request("post", data2, url)).split(/activity = new /);
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
    await loadTool('AIScheduleTools')

    let warning =
        `
        >>>导入流程<<<
        1、登录系统
        2、登陆后直接点击一键导入
        3、大概需要等待5秒左右，导入完成后会自动跳转
  
       `
    await AIScheduleAlert(warning)

    let message = ""
    let preUrl = "";
   // let preUrl = location.href.split("/").slice(0, -2).join("/");
    console.info(preUrl);
    let courseArr = [];
    let arr = []
    try {
        /**可登录时**/
        //  arr = getSjarr1(preUrl);
        //console.log(arr);
        /***不可登录时**/
        if (location.href.search("cas/login") != -1) { await AIScheduleAlert("请登录。。。"); return }
        else if (location.href.search("login.action")==-1) {
            arr = await getSjarr1(preUrl);
        }
        else {
            var loginHtm = document.getElementsByTagName('html')[0].innerHTML;
           // let sha = loginHtm.match(/(?<=CryptoJS\.SHA1\(').*?(?=')/)[0];
            arr = await getSjarr("sha", dom, preUrl);
            let i = 0;
            if (!arr || arr == null && i <= 1) {
                await AIScheduleAlert("用户名或密码有误，请退出重新进入");
                return "do not continue";
            }
        }
        
        console.log(arr)
        if (arr.length >= 1) {
            arr.slice(1).forEach(courseText => {
                let course = { weeks: [], sections: [] };
                console.log(courseText)
                let orArr = courseText.match(/(?<=TaskActivity\().*?(?=\);)/g);
                let day = distinct(courseText.match(/(?<=index \=).*?(?=\*unitCount)/g));
                let section = distinct(courseText.match(/(?<=unitCount\+).*?(?=;)/g));
               let courseCon = orArr[0].split(/","/)
                console.log(orArr, day, section, courseCon[1])
                 console.log(courseCon)   
                course.courseName = courseCon[3]
                course.roomName = courseCon[5]
                course.teacherName =courseCon[1]
                courseCon[6] = courseCon[6].replace('"', "")
                courseCon[6].split("").forEach((em, index) => {
                    if (em == 1) course.weeks.push(index);
                })
                course.day = Number(day) + 1;
                section.forEach(con => {
                    course.sections.push(Number(con) + 1)
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
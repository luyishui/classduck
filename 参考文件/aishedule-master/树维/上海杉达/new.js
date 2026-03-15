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


  let textToDom = (text) => {
      let parser = new DOMParser()
      return parser.parseFromString(text,"text/html")
  }
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
  async function getSjarr(sha, dom, prul) {
  
    let username = document.getElementById("username").value
    let pas = document.getElementById("inputPassword").value
  
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
    //pas = SHA1(sha + pas);
    pas = new Base64().encode(sha+pas)
    let loginData = new FormData()
    loginData.set("username", username)
    loginData.set("password", pas)
    loginData.set("pwd", pas)
    loginData.set("session_locale", "zh_CN")
    
    console.log(dom)
    if (!!dom.getElementById("captcha")) {
        let yzmdom = dom.getElementById("captcha")
        console.log(yzmdom.nextSibling)
        addImg(yzmdom.nextElementSibling.src)
        loginData.set("encodedPassword=","")
        loginData.set("captcha_response",
            !yzmdom.value?
            await AISchedulePrompt({
                titleText: "请输入页面验证码",
                tipText: "",
                defaultText: "",
                validator:  (captcha) => { if(!captcha) return "验证码输入有误";else return false}
            }):yzmdom.value
        )
  
    }
    if (username == null || username.length == 0) {
        return false;
    } else {
        let logRe = await request("POST", loginData, prul + '/login.action');
        console.log(logRe)
        let tdom = textToDom(logRe);
        let errtext = tdom.getElementsByClassName("actionError")
        if(!!errtext.length) {
            await AIScheduleAlert({
                contentText: errtext[0].innerText+">>>请退出重新进入<<<",
                titleText: '错误',
                confirmText: '确认',
              })//"错误"+errtext[0].innerText+";")
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
  
    console.log("获取学期表单数据中")
    let xqdata = new FormData()
//    xqdata.set("tagId", "semesterBar" + courseTableCon.match(/(?<=semesterBar).*?(?=Semester)/)[0] + "Semester")
    xqdata.set("tagId", "projectUI" + courseTableCon.match(/(?<=projectUI).*?(?=Semester)/)[0] + "Semester")

    xqdata.set("dataType", "semesterCalendar")
    xqdata.set("value", courseTableCon.match(/(?<=value:").*?(?=")/)[0])
    xqdata.set("empty", false)
    console.log("获取学期表单数据成功")
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
  
    let semIdsJson =  await getSemestersId(preUrl, courseTableCon);
  
    console.log(semIdsJson.semesterIds)
  
    console.info("获取ids中。。。")
    let ids = courseTableCon.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)[0];
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
       // courseArr = (await request("post", formData, url)).split(/var teachers = \[.*?\];/);
       courseArr = (await request("post", formData, url)).split(/activity = new /);
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
    //  const { AIScheduleAlert } = AIScheduleTools()
      // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
      let warning =
          `
      >>>导入流程<<<
      1、通过统一身份认证平台登录系统
      2、在空白页面，点击一键导入
      3、大概需要等待5秒左右，导入完成后会自动跳转
      注意：导入完成后，注意检查时间和课程是否正确！！！      
     `
      await AIScheduleAlert(warning)
   
    let message = ""
    //alert("请确保你已经连接到校园网！！")
    //  let preUrl1 = location.href.replace("/eams/homeExt.action","");
    let preUrl = location.href.split("/").slice(0, -1).join("/");
    //preUrl += '/eams-shuju'
    console.info(preUrl);
    let courseArr = [];
    let arr = []
    try {
        /**可登录时**/
        //  arr = getSjarr1(preUrl);
        //console.log(arr);
        /***不可登录时**/
        let homeText = await request("get",null,preUrl + "/home.action")
        let homeDom = await textToDom(homeText)
        let logintag = homeDom.getElementsByClassName("logintable").length
        //let img = homeDom.getElementsByTagName("img")
    
        sleep(0.5)
        if (location.href.search("cas/login") != -1) { await AIScheduleAlert("请登录。。。"); return }
        else if (!logintag || location.href.search("/login.action")==-1) {
            arr = await getSjarr1(preUrl);
        }
        else {
            //var loginHtm = document.getElementsByTagName('html')[0].innerHTML;
           // let sha = homeText.match(/(?<=CryptoJS\.SHA1\(').*?(?=')/)[0];
            let sha = homeText.match(/(?<=b.encode\(").*?(?=")/)[0];
            arr = await getSjarr(sha, homeDom, preUrl);
            let i = 0;
            if (!arr || arr == null && i <= 1) {
                //await AIScheduleAlert("用户名或密码有误，请退出重新进入");
                return "do not continue";
            }
        }
        if (arr.length >= 1) {
            arr.slice(1).forEach(
            //     courseText => {
            //     let course = { weeks: [], sections: [] };
            //     console.log(courseText)
            //     let orArr = courseText.match(/(?<=actTeacherName.join\(','\),).*?(?=\);)/g);
            //     let day = distinct(courseText.match(/(?<=index \=).*?(?=\*unitCount)/g));
            //     let section = distinct(courseText.match(/(?<=unitCount\+).*?(?=;)/g));
            //     let teacher = distinct(courseText.match(/(?<=name:").*?(?=")/g));
            //     console.log(orArr, day, section, teacher)
            //     let courseCon = orArr[0].split(/(?<="|l|e),(?="|n|a)/)
            //     console.log(courseCon)
            //     course.courseName = courseCon[1].replace(/"/g, "")
            //     course.roomName = courseCon[3].replace(/"/g, "")
            //     course.teacherName = teacher.join(",")
            //     courseCon[4] = courseCon[4].split(",")[0].replace('"', "")
            //     courseCon[4].split("").forEach((em, index) => {
            //         if (em == 1) course.weeks.push(index);
            //     })
            //     course.day = Number(day) + 1;
            //     section.forEach(con => {
            //         course.sections.push(Number(con) + 1 )
            //     })
            //     console.log(course)
            //     courseArr.push(course)
            // }
            courseText => {
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
            }
            )
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
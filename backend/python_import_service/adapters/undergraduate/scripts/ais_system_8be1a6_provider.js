// Source: 参考文件/aishedule-master/树维/武汉职业技术学院/provider.js

async function request(method, data, url) {
    return await fetch(url, { method: method, body: data }).then(v => v.text()).then(v => v).catch(v => v)
  }
  function requests(tag, data, url) {
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.send(data);
    return ss;
}
  function sleep(timeout) {
    for (let t = Date.now(); Date.now() - t <= timeout * 1000;);
  }

  async function getSjarr1(preUrl) {
   
    // let ids = document.getElementsByTagName('html')[0].innerHTML.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)[0];

    let url1= preUrl + "/eams/courseTableForStd.action";
    let courseTableCon = requests("post", null, url1)
    let ids = courseTableCon.match(/(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/)[0];
    console.info("获取ids中。。。")
    if (ids == null) { alert("ids匹配有误"); return }
    console.info("获取到ids", ids)
         sleep(0.4)
        let data1 = "ignoreHead=1"
        + "&setting.kind=std"
        + "&startWeek="
        + "&semester.id=" 
        + "&ids=" + ids;
        let url = preUrl + "/eams/courseTableForStd!courseTable.action";
        let arrss = requests("post", data1, url)
        let text = `
          课程获取结果
          --------------------------
          ${arrss.slice(0,100)}
          ${arrss.slice(0,100).length==0?"课表获取失败，请尝试清除小爱同学数据，再进行导入":""}
        
        `
        await AIScheduleAlert({
            contentText: text,
            titleText: '课程内容',
            confirmText: '我已知晓',
          }
            
        )

         return arrss.split(/var teachers = \[.*?\];/);
    
  }
  
  function distinct(arr) {
    return Array.from(new Set(arr));
  }
  
  async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
      await loadTool('AIScheduleTools')
      let solve = "请确保【课程内容】弹窗中，虚线下方有一串英文字母，否则请尝试清除小爱同学数据，再进行导入；\n清除数据方法：请自行百度搜索“小米手机怎样清除应用数据”";
      let warning =
          `
      >>>导入流程<<<
      !!!登陆后，不要点击任何控件，否则会导入失败!!!
      1、通过统一身份认证平台登录系统
      2、直接点击一键导入
      3、大概需要等待5秒左右，导入完成后会自动跳转
      注意：导入完成后，注意检查课程是否正确！！！
  
      >>>>常见问题解决方法<<<<
      Q：导入的课程为上学期，非当前学期
      A：请尝试清除小爱同学数据后重新导入    
     `
      await AIScheduleAlert(warning)
   
    let message = ""
    //alert("请确保你已经连接到校园网！！")
    //  let preUrl1 = location.href.replace("/eams/homeExt.action","");
    let preUrl = location.href.split("/").slice(0, -2).join("/");
    console.info(preUrl);
    let courseArr = [];
    let arr = []
    try {
        /**可登录时**/
          arr = await getSjarr1(preUrl);
          console.log(arr)
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
            if (courseArr.length == 0) message = "未获取到课表,"+solve
        } else {
            message = "未获取到课表,"+solve
        }
  
    } catch (e) {
        console.log(e)
        message = e
    }
    if (message.length != 0) {
        courseArr.length = 0;
        let errText = `
        遇到错误，请凭此页面截图，加群:628325112,找【开发者-萧萧】进行反馈;
        错误：${message}
        url:${preUrl}
        `
        AIScheduleAlert({
            contentText: errText,
            titleText: '错误',
            confirmText: '我已知晓',
          })
        return 'do not continue'  
    }
    console.log(courseArr)
    return JSON.stringify(courseArr);
  }

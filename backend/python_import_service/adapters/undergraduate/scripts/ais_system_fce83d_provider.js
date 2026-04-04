// Source: 参考文件/aishedule-master/超星/成都大学/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-28 17:46:09
 * @LastEditTime: 2022-03-28 18:04:13
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\超星\provider.js
 * @QQ：357914968
 */

function AIScheduleLoading({
    titleText = '加载中',
    contentText = 'loading...',
  } = {}) {
    console.log('start......')
    AIScheduleComponents.addMeta()
    const title = AIScheduleComponents.createTitle(titleText)
    const content = AIScheduleComponents.createContent(contentText)
    const card = AIScheduleComponents.createCard([title, content])
    const mask = AIScheduleComponents.createMask(card)
  
    let dyn
    let count = 0
    function dynLoading() {
      if (count == 4) count = 0
      content.innerText = contentText + '.'.repeat(count++)
      // console.log(contentText + '.'.repeat(count))
    }
  
    this.show = () => {
      console.log('show......')
      document.body.appendChild(mask)
      dyn = setInterval(dynLoading, 1000)
    }
    this.close = () => {
      document.body.removeChild(mask)
      clearInterval(dyn)
    }
  }

 function request(tag,url,data)
 {
    let pre = window.location.protocol+"//"+window.location.host+"/"
     let ss = "";
     var xhr = new XMLHttpRequest();
     xhr.onreadystatechange = function() {
         console.log(xhr.readyState+" "+xhr.status)
             if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {  
                 ss = xhr.responseText
             }
         };
     xhr.open(tag, pre+url,false);
     xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
     xhr.send(data)
     return ss;
  }
 
 async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
     //除函数名外都可编辑
     //以下为示例，您可以完全重写或在此基础上更改

    await loadTool('AIScheduleTools')
    let loading = new AIScheduleLoading({contentText:"课表加载中"});
    try {
       let json = ''
       let fram ;
       let a_s = dom.querySelectorAll('.J_menuTab','a') 
       let xnxq='';
       let tag = '';
       let  iframes = document.getElementsByTagName('iframe');

        let currentUrl = window.location.href;
        if(currentUrl.search("jw")!==-1){
            tag = "jw";
        }else if(currentUrl.search(/i.chaoxing.com|kb.chaoxing.com/)!==-1){
            tag = 'cx'
        }else {
            await AIScheduleAlert(`
            您可能不在课表页，请到达课表页；
            若已在课表页请加群:628325112,找开发者进行反馈
        `)
        }
       
        loading.show()

        if (tag === 'jw'){
            for (let index = 0; index < a_s.length; index++) {
                const element = a_s[index];
                if(element.innerText.trim()=='我的课表'){
                    fram = dom.getElementsByTagName('iframe')[index];
                    break;
                }
            }
            if(fram){
                let dom1 = fram.contentDocument
                xnxq = dom1.getElementById('xnxq').value
                let xhid = dom1.getElementById('xhid').value
                let xqdm = dom1.getElementById('xqdm').value
                let url = 'admin/pkgl/xskb/sdpkkbList?xnxq='+xnxq+'&xhid='+xhid+'&xqdm='+xqdm
                json = request('get',url,null)
            }
            else{
                let html = request('get','/admin/pkgl/xskb/queryKbForXsd',null)
                let dom1 = new DOMParser().parseFromString(html, 'text/html')
                xnxq = dom1.getElementById('xnxq').value
                let xhid = dom1.getElementById('xhid').value
                let xqdm = dom1.getElementById('xqdm').value
                let url = 'admin/pkgl/xskb/sdpkkbList?xnxq='+xnxq+'&xhid='+xhid+'&xqdm='+xqdm
                json = request('get',url,null)
            }
        }else if (tag==='cx'){
            if(window.location.href.search("/curriculum/schedule.html")===-1){
                let iframs = document.getElementsByTagName('iframe');
                let src = ''
                for (let index = 0; index < iframs.length; index++) {
                    if(iframes[index].src.search("/curriculum/schedule.html")!==-1){
                        src = iframs[index].src
                    }
                }
                if(src.length === 0){
                    window.location.href = "https://kb.chaoxing.com/res/pc/curriculum/schedule.html";
                }else {
                    window.location.href = src;
                }
                return 'do not continue'
            }

            let  res = request("get","/pc/curriculum/getMyLessons?curTime="+new Date().getTime());
            let resJson = JSON.parse(res);
            let  maxWeek = resJson.data.curriculum.maxWeek

            let allResultPromise = []
            for(let week = 1;week<=Number(maxWeek?maxWeek:25);week++){
                allResultPromise.push(
                    fetch("/pc/curriculum/getMyLessons?curTime="+new Date().getTime()+"&week="+week, {
                        "method": "GET",
                    }).then(v=>v.json()).then(v=>v).catch(e=>console.error(e))
                )
            }
            let allResultJson = await Promise.all(allResultPromise)
            let allResult = []
            allResultJson.forEach(result=>allResult.push(...result.data.lessonArray))
            console.log(allResultJson)
            let arr = []
            allResult = allResult.filter(res => {
                let key = `${res.beginNumber}+${res.length}+${res.dayOfWeek}+${res.name}+${res.teacherNo}+${res.location}+${res.weeks}`
                let isNew = arr.indexOf(key) === -1
                arr.push(key)
                return isNew;
            });
            json = JSON.stringify(allResult)
        }

       return JSON.stringify({"data":JSON.parse(json),"xnxq":xnxq,"tag":tag})
    } catch (error) {
            console.log(error)
        let errText = `
        遇到错误，请凭此页面截图，加群:628325112,找开发者进行反馈
        错误：${ error.message.slice(0, 50)}
        `
      AIScheduleAlert({
        contentText: errText,
        titleText: '错误',
        confirmText: '我已知晓',
      })
      return "do not continue"
    } finally{
        loading.close()
    }
 }

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-28 17:46:21
 * @LastEditTime: 2022-03-28 18:20:09
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\超星\parser.js
 * @QQ：357914968
 */

 function resolveCourseConflicts(result) {
    let splitTag="&"
//将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach(singleCourse => {
        singleCourse.weeks.forEach(week => {
            singleCourse.sections.forEach(value => {
                let course = {sections: [], weeks: []}
                course.name = singleCourse.name;
                course.teacher = singleCourse.teacher==undefined?"":singleCourse.teacher;
                course.position = singleCourse.position==undefined?"":singleCourse.position;
                course.day = singleCourse.day;
                course.weeks.push(week);
                course.sections.push(value);
                allResultSet.add(JSON.stringify(course));
            })
        })
    })
    let allResult = JSON.parse("[" + Array.from(allResultSet).toString() + "]").sort(function (a, b) {
        //return b.day - e.day;
        return (a.day - b.day)||(a.sections[0]-b.sections[0]);
    })

    //将冲突的课程进行合并
    let contractResult = [];
    while (allResult.length !== 0) {
        let firstCourse = allResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
     //   console.log(firstCourse)
        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0] === allResult[i].sections[0]) {
                    let index = firstCourse.name.split(splitTag).indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += splitTag + allResult[i].name;
                        firstCourse.teacher += splitTag + allResult[i].teacher;
                        firstCourse.position += splitTag + allResult[i].position;
                       // firstCourse.position = firstCourse.position.replace(/undefined/g, '')
                        allResult.splice(i, 1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split(splitTag);
                        let position = firstCourse.position.split(splitTag);
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join(splitTag);
                        firstCourse.position = position.join(splitTag);
                       // firstCourse.position = firstCourse.position.replace(/undefined/g, '');
                        allResult.splice(i, 1);
                        i--;
                    }

                }
            }
        }
        contractResult.push(firstCourse);
    }
    //将每一天内的课程进行合并
    let finallyResult = []
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.weeks[0] === contractResult[i].weeks[0] && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                if (firstCourse.sections[firstCourse.sections.length - 1] + 1 === contractResult[i].sections[0]) {
                    firstCourse.sections.push(contractResult[i].sections[0]);
                    contractResult.splice(i, 1);
                    i--;
                } else break
                // delete (contractResult[i])
            }
        }
        finallyResult.push(firstCourse);
    }
    //将课程的周次进行合并
    contractResult = JSON.parse(JSON.stringify(finallyResult));
    finallyResult.length = 0;
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.sections.sort((a,b)=>a-b).toString()=== contractResult[i].sections.sort((a,b)=>a-b).toString() && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                firstCourse.weeks.push(contractResult[i].weeks[0]);
                contractResult.splice(i, 1);
                i--;
            }
        }
        finallyResult.push(firstCourse);
    }
    console.log(finallyResult);
    return finallyResult;
}

function getWeeks(Str) {
    function range(con, tag) {
        if(con.length==1) return [];
        let retWeek=[]
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag === 1 || tag === 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag===0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 !== 0    }))
        })
        return retWeek
    }
    Str = Str.replace(/[(){}|第\[\]]/g, "").replace(/到/g, "-")
    let reWeek = [];
    let week1 = []
    while (Str.search(/周|\s/) !== -1) {
        let index = Str.search(/周|\s/)
        if (Str[index + 1] === '单' || Str[index + 1] === '双') {
            week1.push(Str.slice(0, index + 2).replace(/周|\s/g, ""));
            index += 2
        } else {
            week1.push(Str.slice(0, index + 1).replace(/周|\s/g, ""));
            index += 1
        }

        Str = Str.slice(index)
        index = Str.search(/\d/)
        if (index !== -1) Str = Str.slice(index)
        else Str = ""

    }
    if (Str.length !== 0) week1.push(Str)
    console.log(week1)
    week1.forEach(v => {
        console.log(v)
        if (v.slice(-1) === "双") reWeek.push(...range(v, 2))
        else if (v.slice(-1) === "单") reWeek.push(...range(v, 3))
        else reWeek.push(...range(v+"全", 1))
    });
    return reWeek;
}
    function scheduleHtmlParser(html) {
        //除函数名外都可编辑
        //传入的参数为上一步函数获取到的html
        //可使用正则匹配
        //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
        //以下为示例，您可以完全重写或在此基础上更改
        let result=[];
        let kcdata = JSON.parse(html).data
        let tag = JSON.parse(html).tag
        console.log(kcdata)
        let message = ''
        if(tag === 'jw'){
            try{
                kcdata.forEach(con => {
                    let re = {sections:[],weeks:[]}
                    re.name = con.kcmc.match(/(?<="\>).*?(?=\<\/)/g).toString()
                    re.teacher = con.tmc.match(/(?<="\>).*?(?=\<\/)/g)
                    re.teacher = !re.teacher?"":re.teacher.toString()
                    re.day = con.xingqi
                    re.weeks = getWeeks(con.zc)
                    re.sections.push(con.djc)
                    re.position = con.croommc.match(/(?<="\>).*?(?=\<\/)/g)
                    re.position = !re.position?"":re.position.toString()
                    result.push(re)
                })
            } catch (err) {
                console.error(err)
                message = err.message.slice(0, 50);
            }
        }else if (tag === 'cx'){
            kcdata.forEach(con => {
                let re = {sections:[],weeks:[]}
                re.name = con.name
                re.teacher = con.teacherName
                re.day = con.dayOfWeek
                re.weeks = con.weeks.split(',')
                for (let start = 0;start < con.length ; start++){
                    re.sections.push(con.beginNumber+start)
                }
                re.position = con.location
                result.push(re)
            })
        }else {
            message = '未知异常';
        }


        if(kcdata.length===0){
            message = "未获取到课表"
        }
        if (message.length !== 0) {
            result.length = 0;
            result.push({
                'name': "遇到错误，请加qq群：628325112进行反馈",
                'teacher': "开发者",
                'position': message,
                'day': 1,
                'weeks': [1],
                'sections': [{section: 1}, {section: 2}, {section: 3}]
            });
        }
        
        return resolveCourseConflicts(result) 
    }

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-15 18:40:09
 * @LastEditTime: 2022-03-28 18:15:52
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\超星\timer.js
 * @QQ：357914968
 */


function requests(tag,url,data)
{
   let pre = window.location.protocol+"//"+window.location.host+"/"
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        console.log(xhr.readyState+" "+xhr.status)
            if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {  
                ss = xhr.responseText
            }
            
        };
    xhr.open(tag, pre+url,false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    xhr.send(data)
    return ss;
 }

/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer({
    providerRes,

  } = {}) {
    try{
        let res ={
            totalWeek: 24, // 总周数：[1, 30]之间的整数
            startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
            startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
            showWeekend: false, // 是否显示周末
            forenoon: 0, // 上午课程节数：[1, 10]之间的整数
            afternoon: 0, // 下午课程节数：[0, 10]之间的整数
            night: 0, // 晚间课程节数：[0, 10]之间的整数
            sections:  []// 课程时间表，注意：总长度要和上边配置的节数加和对齐
        }

        let tag = JSON.parse(providerRes).tag
        console.log(tag)
        if(tag==='jw'){
            let time = requests("get","admin/system/zy/xlgl/selectJxzxsj/"+JSON.parse(providerRes).xnxq)
            let times = JSON.parse(time)
            times.forEach(t=>{
                res.sections.push({
                    section:t.jc,
                    startTime:t.kssj,
                    endTime:t.jssj
                })
                if(t.sjd==='sw'){
                    res.forenoon++
                }
                if(t.sjd==='xw'){
                    res.afternoon++
                }
                if(t.sjd==='bw' || t.sjd==='ws'){
                    res.night++
                }
            })
        }else if(tag === 'cx'){
            let  resJson = await fetch("/pc/curriculum/getMyLessons?curTime="+new Date().getTime()).then(v=>v.json()).then(v=>v);
            let timeArr = resJson.data.curriculum.lessonTimeConfigArray
            console.log(timeArr)
            res.forenoon = 4
            res.afternoon = 4
            res.night = timeArr.length-8;
            timeArr.forEach((t,index)=>{
                let ab = t.split("-");
                res.sections.push({
                    section:index+1,
                    startTime:ab[0].length === 4 ? '0' + ab[0]:ab[0],
                    endTime:ab[1].length === 4 ? '0' + ab[1]:ab[1]
                })
            })
        }

  return res.sections.length===0?{}:res 
}catch(e){
    return {}
}
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

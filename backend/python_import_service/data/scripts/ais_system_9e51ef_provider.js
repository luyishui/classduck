// Source: 参考文件/aishedule-master/金智教务/安徽医学高等专科学校/provider.js

/*
 * @Author: your name
 * @Date: 2022-02-19 22:54:23
 * @LastEditTime: 2023-02-20 09:49:01
 * @LastEditors: xiaoxiao
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: \AISchedule\金智教务\燕山大学\provider.js
 */


    let req = async (method,body,url)=>{
        return await fetch(url,{method:method, body:body,headers:{
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
        }}).then(re=>re.json()).then(v=>v).catch(err=>console.error(err))
    }
    let getCourse = async (mode)=>{
            let nowXNXQ = "/jwapp/sys/wdkb/modules/jshkcb/dqxnxq.do"
            let course = "/jwapp/sys/wdkb/modules/xskcb/xskcb.do"
            let showApp = "/appShow?appId=4770397878132218" //我的课表appid
            // console.log(await req("get",null,showApp))
            await fetch(showApp,{method:"get"}).then(v=>v).then(v=>v.text())
            let xnxq = !document.getElementById('dqxnxq2')?(await req("post",null,nowXNXQ)).datas.dqxnxq.rows[0].DM:document.getElementById('dqxnxq2').getAttribute('value')
            console.log(xnxq)
            let courseText = (await req("post","XNXQDM="+xnxq,course)).datas.xskcb.rows
            console.log(courseText)
           return JSON.stringify({'courseJson':courseText,'mode':mode})
    }
    function AIScheduleLoading({
        titleText='加载中',
        contentText = 'loading...',
    }={}
    ){
        console.log("start......")
        AIScheduleComponents.addMeta()
        const title = AIScheduleComponents.createTitle(titleText)
        const content = AIScheduleComponents.createContent(contentText)
        const card = AIScheduleComponents.createCard([title, content])
        const mask = AIScheduleComponents.createMask(card)
        
        let dyn 
        let count = 0
        function dynLoading(){
            let t = ['loading','loading.','loading..','loading...']
            if(count==4) count=0
            content.innerText = t[count++]
        }

        this.show=()=>{ 
            console.log("show......")
            document.body.appendChild(mask)
            dyn = setInterval(dynLoading,1000);
        }
        this.close=()=>{
            document.body.removeChild(mask)
            clearInterval(dyn)
        }
        }
    async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
        //除函数名外都可编辑
        //以下为示例，您可以完全重写或在此基础上更改
        await loadTool('AIScheduleTools')
      
        try{
             let mode = (await AIScheduleSelect({
                titleText:"导入模式选择",
                contentText:"请选择导入模式",
                selectList:[
                    "模式一:解析当前页面（速度快）",
                    "模式二:请求接口（速度慢）"
                ]
            })).split(':')[0]

            if(mode=='模式一'){
                return JSON.stringify({'html':dom.getElementById("kcb_container").outerHTML,'mode':mode})
            }
            else if(mode=='模式二'){
                let loading = new AIScheduleLoading()
                loading.show()
                let res = await getCourse(mode)
                loading.close()
            return res
            }
        }catch(e){
            console.error(e)
            try{
                let loading = new AIScheduleLoading()
                loading.show()
                let res = await getCourse("模式二")
               loading.close()
                return res
            }catch(e){
                await AIScheduleAlert({
                    contentText: e,
                    titleText: '错误',
                    confirmText: '导入失败',
                  })
                return "do not continue"
            }
            
        }
       
             
    }

// Merged parser.js

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
        let retWeek=[]
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag == 1 || tag == 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag==0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 != 0    }))
        })
        return retWeek
    }
    Str = Str.replace(/[(){}|第]/g, "").replace(/到/g, "-")
    let reWeek = [];
    let week1 = []
    while (Str.search(/周/) != -1) {
        let index = Str.search(/周/)
        if (Str[index + 1] == '单' || Str[index + 1] == '双') {
            week1.push(Str.slice(0, index + 2).replace("周", ""));
            index += 2
        } else {
            week1.push(Str.slice(0, index + 1).replace("周", ""));
            index += 1
        }

        Str = Str.slice(index)
        index = Str.search(/\d/)
        if (index != -1) Str = Str.slice(index)
        else Str = ""

    }
    if (Str.length != 0) week1.push(Str)

    week1.forEach(v => {
        console.log(v)
        if (v.slice(-1) == "双") reWeek.push(...range(v, 2))
        else if (v.slice(-1) == "单") reWeek.push(...range(v, 3))
        else reWeek.push(...range(v+"全", 1))
    });
    return reWeek;
}
function getJc(Str){
    let jc = []
    Str = Str.replace(/第|节/g,"")
    let Strar = Str.split("-")
    for(i=Number(Strar[0]);i<=Strar[Strar.length-1];i++){
        jc.push(i)
    }
    return jc
}
function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
    let result = []
    let message = ""
    try{
        let jsonData = JSON.parse(html);
        if(jsonData.mode=='模式一'){
            let $ = cheerio.load(jsonData.html, {decodeEntities: false})
            let tbody = $('table[class = wut_table] tbody')
            let trs = tbody.find('tr')
            trs.each(function (inde, em) {
                let tds = $(this).find("td[data-role=item]")
                tds.each(function (ind, emmm) {
                    let div = $(this).find('.mtt_arrange_item')
                    div.each(function (indexx, eem) {
                        console.log($(this).find('.mtt_item_kcmc').eq(0).find('a').length)
                        if ($(this).find('.mtt_item_kcmc').eq(0).find('a').length != 0) return;
                        let re = {weeks: [], sections: []}
                        let namet = $(this).find('.mtt_item_kcmc').eq(0).text()
                        let name = namet.match(/(?<=([A-Z]|\d)*\s).*?(?=\[)/)
                        if (name == null) name = namet.split(/\[|\$|\s/)
                        re.name = name[0]
                        re.teacher = $(this).find('.mtt_item_jxbmc').eq(0).text()
                        let jskc = $(this).find('.mtt_item_room').eq(0).text()
                        let jskcar = jskc.split(",")
                        re.position = jskcar[jskcar.length - 1]
                        jskcar.pop()
                        re.sections = getJc(jskcar[jskcar.length - 1])
                        jskcar.pop()
                        re.day = jskcar[jskcar.length - 1].replace("星期", "")
                        re.day = parseInt(re.day)
                        jskcar.pop()
                        let zcstr = jskcar.toString()
                        re.weeks = getWeeks(zcstr)
                        result.push(re)
                    })
                })
            })
        }else if(jsonData.mode=='模式二'){
            let courses = jsonData.courseJson
            courses.forEach(course=>{
                result.push({
                    "name":course.KCM+(!course.TYXMDM_DISPLAY?"":`(${course.TYXMDM_DISPLAY})`),
                    "teacher":course.SKJS,
                    'position':course.JASMC,
                    'sections':(()=>{
                        let start = course.KSJC
                        let end = course.JSJC
                        let sec=[]
                        for(let i = start;i<=end;i++){
                            sec.push(i)
                        }
                        return sec
                    })(),
                    'weeks':(()=>{
                        let week = []
                        course.SKZC.split("").forEach((em, index) => {
                            if (em == 1) week.push(index+1);
                        })
                       return week
                    })(),
                    'day':course.SKXQ
                })
            })
        }

        if(result.length) result = resolveCourseConflicts(result)
        else message="没有获取到课表"
    }catch(e){
        message = e.message
    }
    if(message.length){
        result.length = 0
        result.push({name:"遇到错误,请加群:628325112,找开发者进行反馈",teacher:"开发者-萧萧",position:message,day:1,weeks:[1],sections:[{section:1},{section:2}]})
    }

    return result
}

// Merged timer.js

function getTimes(xJConf,dJConf){
    //xJConf : 夏季时间配置文件
    //dJConf : 冬季时间配置文件
    //return : Array[{},{}]
    dJConf = dJConf ===undefined ? xJConf : dJConf;
    function getTime(conf){
        let courseSum = conf.courseSum;  //课程节数 : 12
        let startTime  = conf.startTime; //上课时间 :800
        let oneCourseTime = conf.oneCourseTime;  //一节课的时间
        let shortRestingTime = conf.shortRestingTime;  //小班空

        let longRestingTimeBegin=conf.longRestingTimeBegin; //大班空开始位置
        let longRestingTime  = conf.longRestingTime;   //大班空
        let lunchTime  = conf.lunchTime;     //午休时间
        let dinnerTime = conf.dinnerTime;    //下午休息
        let abnormalClassTime = conf.abnormalClassTime;      //其他课程时间长度
        let abnormalRestingTime = conf.abnormalRestingTime;    //其他休息时间

        let result = [];
        let studyOrRestTag = true;
        let timeSum = startTime.slice(-2)*1+startTime.slice(0,-2)*60;

        let classTimeMap = new Map();
        let RestingTimeMap = new Map();
        if(abnormalClassTime !== undefined) abnormalClassTime.forEach(time=>{classTimeMap.set(time.begin,time.time)});
        if(longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time=>RestingTimeMap.set(time,longRestingTime));
        if(lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin,lunchTime.time);
        if(dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin,dinnerTime.time);
        if(abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => {RestingTimeMap.set(time.begin,time.time)});

        for(let i = 1, j=1; i<=courseSum*2; i++){
            if(studyOrRestTag){
                let startTime = ("0"+Math.floor(timeSum/60)).slice(-2)+':'+('0'+timeSum%60).slice(-2);
                timeSum+=classTimeMap.get(j)===undefined?oneCourseTime:classTimeMap.get(j);
                let endTime = ("0"+Math.floor(timeSum/60)).slice(-2)+':'+('0'+timeSum%60).slice(-2);
                studyOrRestTag=false;
                result.push({
                    section:j++,
                    startTime:startTime,
                    endTime:endTime
                })
            }
            else {
                timeSum += RestingTimeMap.get(j-1) === undefined?shortRestingTime:RestingTimeMap.get(j-1);
                studyOrRestTag = true;
            }
        }
        return result;
    }

    let nowDate = new Date();
    let year = nowDate.getFullYear();                       //2020
    let wuYi = new Date(year+"/"+'05/01');           //2020/05/01
    let jiuSanLing = new Date(year+"/"+'09/30');     //2020/09/30
    let shiYi = new Date(year+"/"+'10/01');          //2020/10/01
    let nextSiSanLing = new Date((year+1)+"/"+'04/30');    //2021/04/30
    let previousShiYi = new Date((year-1)+"/"+'10/01');     //2019/10/01
    let siSanLing = new Date(year+"/"+'04/30');         //2020/04/30
    let xJTimes = getTime(xJConf);
    let dJTimes = getTime(dJConf);
    console.log("夏季时间:\n",xJTimes)
    console.log("冬季时间:\n",dJTimes)
    if(nowDate >= wuYi && nowDate <= jiuSanLing){
        return xJTimes;
    }
    else if(nowDate >= shiYi && nowDate <= nextSiSanLing || nowDate >= previousShiYi && nowDate <= siSanLing){
        return dJTimes;
    }
}

let reqest = async (method,body,url)=>{
    return await fetch(url,{method:method, body:body,headers:{
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
    }}).then(re=>re.json()).then(v=>v).catch(err=>console.error(err))
}
/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer() {
  
    let time = "https://ehall.ysu.edu.cn/jwapp/sys/wdkb/modules/jshkcb/jc.do"
    // let timeJson = (await reqest("post",null,time)).datas.jc.rows
    // let secs = []
    // timeJson.forEach(v=>{
    //     secs.push({
    //         'section':v.DM,
    //         'startTime':v.KSSJ,
    //         'endTime':v.JSSJ
    //     })
    // })

    let dJConf={
        courseSum: 12,
        startTime: '820',
        oneCourseTime: 40,
        longRestingTime: 15,
        shortRestingTime: 10,
        longRestingTimeBegin: [2,6],
        lunchTime: {begin: 4, time: 2 * 60 - 25},
        dinnerTime: {begin: 8, time: 2*60+5},
        // abnormalClassTime:[{begin:11,time:40}],
    }
        let xJConf={
        courseSum: 12,
        startTime: '820',
        oneCourseTime: 40,
        longRestingTime: 15,
        shortRestingTime: 10,
        longRestingTimeBegin: [2,6],
        lunchTime: {begin: 4, time: 2 * 60 + 5},
        dinnerTime: {begin: 8, time: 2*60-25},
        // abnormalClassTime:[{begin:11,time:40}],
    }
    console.log(result)

  return {
    'totalWeek': 20, // 总周数：[1, 30]之间的整数
    'startSemester': '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    'startWithSunday': false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    'showWeekend': false, // 是否显示周末
    'forenoon': 4, // 上午课程节数：[1, 10]之间的整数
    'afternoon': 4, // 下午课程节数：[0, 10]之间的整数
    'night': 4, // 晚间课程节数：[0, 10]之间的整数
    'sections':getTimes(xJConf,dJConf), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

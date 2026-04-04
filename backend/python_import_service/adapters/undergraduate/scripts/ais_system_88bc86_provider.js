// Source: 参考文件/aishedule-master/自研教务/山东药品职业学院/provider.js

let req = async (method,data,url)=>{
return await fetch(url,{method:method,body:data}).then(re=>re.json()).then(v=>v)
}
async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
  //  alert("即将开始导入，导入时长受网络影响，请等待。。。。")
    let resuslt={}
    try{
        let token =location.href.split("=")[1]
        if(!token){
            let scr = dom.getElementsByTagName("script")
            token = scr[scr.length-1].outerHTML.match(/(?<=api_token:').*?(?=')/)[0]
        }
        let xqurl = "http://jwxt.sddfvc.cn/mobile/student/mobile_kcb_xq?api_token="+token       
        let xqdom = dom.getElementsByTagName("select")
        let xqid = !xqdom.length?(await req("get",null,xqurl)).data.xq_current.id:xqdom[0].value
        console.log(xqid)
        let kburl = "http://jwxt.sddfvc.cn/mobile/student/mobile_kcb?api_token="+token+"&xq="+xqid
       resuslt = await req("get",null,kburl)
    }catch(e){
        resuslt.error = e.message
    }

    return JSON.stringify(resuslt)   
}

// Merged parser.js

function getWeeks(zcjson) {
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
    let Str = ""
    switch(zcjson.dsz){
        case 1:Str=zcjson.zc+"单";break
        case 2:Str=zcjson.zc+"双";break
        default:Str=zcjson.zc;
    }
    Str = Str.replace(/\(|\)|\{|\}|\||第/g, "").replace(/到/g, "-")
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

// function getSections(Str){
//     let jc=[];
//     let jcar = Str.replace("节","").split("-")
//     for(i=Number(jcar[0]);i<=jcar[jcar.length-1];i++){
//         jc.push(i)
//     }
//     return jc
// }

function resolveCourseConflicts(result) {
    let splitTag="&"
//将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach(singleCourse => {
        singleCourse.weeks.forEach(week => {
            singleCourse.sections.forEach(value => {
                let course = {sections: [], weeks: []}
                course.name = singleCourse.name;
                course.teacher = singleCourse.teacher;
                course.position = singleCourse.position;
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

        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0] === allResult[i].sections[0]) {
                    let index = firstCourse.name.split(splitTag).indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += splitTag + allResult[i].name;
                        firstCourse.teacher += splitTag + allResult[i].teacher;
                        firstCourse.position += splitTag + allResult[i].position;
                        firstCourse.position = firstCourse.position.replace(/undefined/g, '')
                        allResult.splice(i, 1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split(splitTag);
                        let position = firstCourse.position.split(splitTag);
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join(splitTag);
                        firstCourse.position = position.join(splitTag);
                        firstCourse.position = firstCourse.position.replace(/undefined/g, '');
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
    // contractResult = contractResult.sort(function (a, b) {
    //     return (a.day - b.day)||(a.sections[0]-b.sections[0]);
    // })
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
    // contractResult = contractResult.sort(function (a, b) {
    //     return a.day - b.day;
    // })
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

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
let result=[]
let courseInfo ={}
let message = ""
let Info = JSON.parse(html)
if(!Info.error)  courseInfo = Info.data
else message = Info.error
console.log(courseInfo)
try{
    for(let day=1;day<=7;day++){
        let xqCourse = courseInfo['xq'+day]
        for(let jieci in xqCourse){
            console.log(day +":"+jieci +":")
            let courses = xqCourse[jieci]
            for(let key in courses){
                console.log(courses[key])
                let course = courses[key]
                let pkmx = course.pkmx
                for(let pkkey in pkmx){               
                    let re = {teacher:"",sections:[],weeks:[]}
                    let name = course.pkbmc.split("#")
                    console.log(name)
                    re.name = name[0].search(/\d+级.*?班/)==-1?name[0]:name[1]
                    re.position = pkmx[pkkey].classroom
                    re.day = parseInt(day)
                    re.sections=[parseInt(jieci),parseInt(jieci)+1]
                    for(let kk in  pkmx[pkkey]['teacher']){
                        re.teacher+=pkmx[pkkey]['teacher'][kk]['xm']
                    }
                    re.weeks = getWeeks(pkmx[pkkey]['zc'])
                    result.push(re)
                }

            }
        }
    }
   if(result.length) result = resolveCourseConflicts(result)
   else if(!message.length)message="课表为空"
}catch(e){
    message=e.message.slice(0,50)
}
if(message.length) {
    result.length=0
    result.push({name:"遇到错误,请加群:628325112,找开发者进行反馈",teacher:"开发者-萧萧",position:message,day:1,weeks:[1],sections:[{section:1},{section:2}]})
}

console.log(result)



console.log(result)
    return result
}

// Merged timer.js

function scheduleTimer(){
function getTimes(xJConf, dJConf) {
    //xJConf : 夏季时间配置文件
    //dJConf : 冬季时间配置文件
    //return : Array[{},{}]
    dJConf = dJConf === undefined ? xJConf : dJConf;

    function getTime(conf) {
        let courseSum = conf.courseSum;  //课程节数 : 12
        let startTime = conf.startTime; //上课时间 :800
        let oneCourseTime = conf.oneCourseTime;  //一节课的时间
        let shortRestingTime = conf.shortRestingTime;  //小班空

        let longRestingTimeBegin = conf.longRestingTimeBegin; //大班空开始位置
        let longRestingTime = conf.longRestingTime;   //大班空
        let lunchTime = conf.lunchTime;     //午休时间
        let dinnerTime = conf.dinnerTime;    //下午休息
        let abnormalClassTime = conf.abnormalClassTime;      //其他课程时间长度
        let abnormalRestingTime = conf.abnormalRestingTime;    //其他休息时间

        let result = [];
        let studyOrRestTag = true;
        let timeSum = startTime.slice(-2) * 1 + startTime.slice(0, -2) * 60;

        let classTimeMap = new Map();
        let RestingTimeMap = new Map();
        if (abnormalClassTime !== undefined) abnormalClassTime.forEach(time => {
            classTimeMap.set(time.begin, time.time)
        });
        if (longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time => RestingTimeMap.set(time, longRestingTime));
        if (lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin, lunchTime.time);
        if (dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin, dinnerTime.time);
        if (abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => {
            RestingTimeMap.set(time.begin, time.time)
        });

        for (let i = 1, j = 1; i <= courseSum * 2; i++) {
            if (studyOrRestTag) {
                let startTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
                timeSum += classTimeMap.get(j) === undefined ? oneCourseTime : classTimeMap.get(j);
                let endTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
                studyOrRestTag = false;
                result.push({
                    section: j++,
                    startTime: startTime,
                    endTime: endTime
                })
            } else {
                timeSum += RestingTimeMap.get(j - 1) === undefined ? shortRestingTime : RestingTimeMap.get(j - 1);
                studyOrRestTag = true;
            }
        }
        return result;
    }

    let nowDate = new Date();
    let year = nowDate.getFullYear();                       //2020
    let wuYi = new Date(year + "/" + '05/01');           //2020/05/01
    let jiuSanLing = new Date(year + "/" + '09/30');     //2020/09/30
    let shiYi = new Date(year + "/" + '10/01');          //2020/10/01
    let nextSiSanLing = new Date((year + 1) + "/" + '04/30');    //2021/04/30
    let previousShiYi = new Date((year - 1) + "/" + '10/01');     //2019/10/01
    let siSanLing = new Date(year + "/" + '04/30');         //2020/04/30
    let xJTimes = getTime(xJConf);
    let dJTimes = getTime(dJConf);
    console.log("夏季时间:\n", xJTimes)
    console.log("冬季时间:\n", dJTimes)
    if (nowDate >= wuYi && nowDate <= jiuSanLing) {
        return xJTimes;
    } else if (nowDate >= shiYi && nowDate <= nextSiSanLing || nowDate >= previousShiYi && nowDate <= siSanLing) {
        return dJTimes;
    }
}

return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: false, // 是否显示周末
    forenoon:4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 2, // 晚间课程节数：[0, 10]之间的整数
    sections: getTimes({
        courseSum: 10,
        startTime: '830',
        oneCourseTime: 45,
        longRestingTime: 15,
        shortRestingTime: 0,
        longRestingTimeBegin: [2, 6],
        lunchTime: {begin: 4, time: 2 * 60 - 15},
        dinnerTime: {begin: 8, time: 60 + 75},
        abnormalClassTime:[{begin:10,time:75}]
    }) // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
}

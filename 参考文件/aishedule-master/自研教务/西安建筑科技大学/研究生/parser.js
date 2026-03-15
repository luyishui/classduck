function resolveCourseConflicts(result) {
    function pdSection(or, inn) {
        // console.log(or,inn)
        or.sort(function (a, b) {
            return a.section - b.section;
        })
        inn.sort(function (a, b) {
            return a.section - b.section;
        })
        if (JSON.stringify(or) === JSON.stringify(inn)) {
            return true;
        } else return false;
    }

//将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach(singleCourse => {
        singleCourse.weeks.forEach(week => {
            singleCourse.sections.forEach(section => {
                let course = {sections: [], weeks: []}
                course.name = singleCourse.name;
                course.teacher = singleCourse.teacher;
                course.position = singleCourse.position;
                course.day = singleCourse.day;
                course.weeks.push(week);
                course.sections.push(section);
                allResultSet.add(JSON.stringify(course));
            })
        })
    })
    let allResult = JSON.parse("[" + Array.from(allResultSet).toString() + "]").sort(function (b, e) {
        return b.day - e.day;
    })

    //将冲突的课程进行合并
    let contractResult = [];
    while (allResult.length !== 0) {
        let firstCourse = allResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;

        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0].section === allResult[i].sections[0].section) {
                    let index = firstCourse.name.split('|').indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += "|" + allResult[i].name;
                        firstCourse.teacher += "|" + allResult[i].teacher;
                        firstCourse.position += "|" + allResult[i].position;
                        firstCourse.position = firstCourse.position.replace(/undefined/g, '')
                        allResult.splice(i, 1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split("|");
                        let position = firstCourse.position.split("|");
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join("|");
                        firstCourse.position = position.join("|");
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
    contractResult = contractResult.sort(function (a, b) {
        return a.day - b.day;
    })
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.weeks[0] === contractResult[i].weeks[0] && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                if (firstCourse.sections[firstCourse.sections.length - 1].section + 1 === contractResult[i].sections[0].section) {
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
    contractResult = contractResult.sort(function (a, b) {
        return a.day - b.day;
    })
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (pdSection(firstCourse.sections, contractResult[i].sections) && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
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
/**
 * 形如 1-3单周,4-8周双，10-12周
 * 原理：以周为界限进行分割
 * @param Str
 * @returns {*[]}
 */
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
    Str = Str.replace(/[(){}|第\[\]\s]/g, "").replace(/到/g, "-")
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
    let result = []
    let $ = cheerio.load(html,{decodeEntities: false})
    let trs = $('tr').slice(1)
    let tag = false;
    let countTag = 0;
    let currentSec = 0
    let message = "";
    try{
    trs.each(function(index,_){
        let tds = $(this).children('td')
        if(tds.eq(0).text().trim()=='中午'||tag) {
            if(!tag&&countTag==0) countTag=tds.eq(0).attr("rowspan");tag=true;
            if(--countTag==0)tag = false;
            return;
            }
         else {
             currentSec++
         }
        tds.filter(function(i,el){return $(this).attr('id')!=undefined}).each(function(index,_){
            let courseInfo = $(this).html().split("<br>").filter(v=>{return v.trim()&&v})
            let weekOfDay = $(this).attr('id').split('_')[1];
            let secLen = $(this).attr('rowspan')==undefined?1:Number($(this).attr('rowspan'));
            if(courseInfo.length==0) return; 
            for(i=0;i<courseInfo.length;i=i+4){
                let re = {sections:[],weeks:[]}
                re.name = courseInfo[i].split(/:|：/)[1];
                re.teacher = courseInfo[i+2].split(/:|：/)[1];
                let mixInfo = courseInfo[i+3];
                re.position = mixInfo.split(/:|\(/)[1].split("-").slice(-1)[0];
                re.day = Number(weekOfDay);
                for(let sec=currentSec;sec<currentSec+secLen;sec++){
                    re.sections.push({section:sec});
                }
                re.weeks = getWeeks(mixInfo.split(/:|\(/)[2])   
               result.push(re);
            }
        
        })
    })
        console.log(result);
        if (result.length === 0) message = "未获取到课表";
        else result = resolveCourseConflicts(result);
    } catch (err) {
        message = err.message.slice(0, 50);
    }
    if (message.length !== 0) {
        result.length = 0;
        result.push({
            name: "遇到错误，请加qq群：628325112进行反馈",
            teacher: "开发者-萧萧",
            position: message,
            day: 1,
            weeks: [1],
            sections: [{section: 1}, {section: 2}, {section: 3}]
        });
    }
    let xJConf={
    courseSum: 11,
    startTime: '800',
    oneCourseTime: 50,
    longRestingTime: 20,
    shortRestingTime: 10,
    longRestingTimeBegin: [2,],
    lunchTime: {begin: 4, time: 2 * 60 + 30},
    dinnerTime: {begin: 8, time: 100},
  //  abnormalClassTime:[{begin:11,time:40}],
    // abnormalRestingTime: [{begin: 11, time: 5}, {begin: 12, time: 5}]
}
let dJConf={
    courseSum: 11,
    startTime: '800',
    oneCourseTime: 50,
    longRestingTime: 20,
    shortRestingTime: 10,
    longRestingTimeBegin: [2,],
    lunchTime: {begin: 4, time: 2 * 60 },
    dinnerTime: {begin: 8, time: 100},
   // abnormalClassTime:[{begin:11,time:40}],
}

    return { courseInfos: result,sectionTimes: getTimes(xJConf,dJConf)}
}


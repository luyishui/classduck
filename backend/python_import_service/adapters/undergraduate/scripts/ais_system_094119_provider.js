// Source: 参考文件/aishedule-master/强智教务/手机端/湖南软件职业技术学院/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:50
 * @LastEditTime: 2022-03-08 14:08:43
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\强智教务\手机端\湖南软件职业技术学院\provider.js
 * @QQ：357914968
 */
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



function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    
    

    let baseUrl = "http://222.243.161.213:81/hnrjzyxyhd"
    let token = sessionStorage.getItem('Token')

    let kbjcmsid = request("post",null,baseUrl+"/Get_sjkbms",token)
    kbjcmsid = JSON.parse(kbjcmsid).data[0].kbjcmsid
    console.log(kbjcmsid)

    let teachingWeek = request("post",null,baseUrl+"/teachingWeek",token)
    teachingWeek = JSON.parse(teachingWeek).data
    console.log(teachingWeek)

    let courses=new Set()
    teachingWeek.forEach(week=>{
        let data = request("post",null,baseUrl+"/student/curriculum?week="+week.week+"&kbjcmsid="+kbjcmsid,token)
        data = JSON.parse(data).data[0].item
        data.forEach(v=>{
            courses.add(JSON.stringify(v))
        })
    })
    return "["+Array.from(courses).toString()+"]"

}

// Merged parser.js

function resolveCourseConflicts(result) {
    function pdSection(or, inn) {
        // console.log(or,inn)
        or.sort(function (a, b) {
            return a.section - b.section
        })
        inn.sort(function (a, b) {
            return a.section - b.section
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
                course.sections.push(section)
                allResultSet.add(JSON.stringify(course))
            })
        })
    })
    let allResult = JSON.parse("[" + Array.from(allResultSet).toString() + "]").sort(function (b, e) {
        return b.day - e.day
    })

    //将冲突的课程进行合并
    let contractResult = [];
    while (allResult.length !== 0) {
        let firstCourse = allResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day

        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0].section === allResult[i].sections[0].section) {
                    let index = firstCourse.name.split('|').indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += "|" + allResult[i].name;
                        firstCourse.teacher += "|" + allResult[i].teacher;
                        firstCourse.position += "|" + allResult[i].position;
                        firstCourse.position = firstCourse.position.replace(/undefined/g,'')
                        allResult.splice(i,1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split("|");
                        let position = firstCourse.position.split("|");
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join("|");
                        firstCourse.position = position.join("|");
                        firstCourse.position = firstCourse.position.replace(/undefined/g,'')
                        allResult.splice(i,1);
                        i--;
                    }

                }
            }
        }
        contractResult.push(firstCourse);
    }
    //将每一天内的课程进行合并
    let finallyResult = []
    contractResult = contractResult.sort(function (a,b){return a.day-b.day})
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.weeks[0] === contractResult[i].weeks[0] && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                if(firstCourse.sections[firstCourse.sections.length-1].section+1===contractResult[i].sections[0].section){
                    firstCourse.sections.push(contractResult[i].sections[0]);
                    contractResult.splice(i,1);
                    i--;
                }
                else break
                // delete (contractResult[i])
            }
        }
        finallyResult.push(firstCourse);
    }
    //将课程的周次进行合并
    contractResult = JSON.parse(JSON.stringify(finallyResult));
    finallyResult.length = 0
    contractResult = contractResult.sort(function (a,b){return a.day-b.day})
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (pdSection(firstCourse.sections, contractResult[i].sections) && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                firstCourse.weeks.push(contractResult[i].weeks[0]);
                contractResult.splice(i,1);
                i--;
            }
        }
        finallyResult.push(firstCourse);
    }
    console.log(finallyResult)
    return finallyResult;
}
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

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
    let result=[]
    let courseInfo = JSON.parse(html)
    console.log(courseInfo)
    courseInfo.forEach(course=>{
        let re = {sections:[],weeks:[]}
        re.name = course.courseName
        re.teacher = course.teacherName
        re.position = course.location
        re.day = parseInt(course.classTime.slice(0,1))
        let sectionString = course.classTime.slice(1)
        while(sectionString){
            re.sections.push({section:parseInt(sectionString.slice(0,2))})
            sectionString = sectionString.slice(2)
        }
        course.classWeekDetails.split(",").filter(v=>{return v.trim()}).forEach(v=>{re.weeks.push(parseInt(v))})
        result.push(re)
    })
    if(result.length) result = resolveCourseConflicts(result)

    let dj = {
        courseSum: 10,
        startTime: '800',
        oneCourseTime: 45,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2, 6],
        lunchTime: {begin: 4, time: 2 * 60 + 50},
        dinnerTime: {begin: 8, time: 60 + 20}
    }

    console.log(result)
    return {courseInfos: result, sectionTimes:getTimes(dj)}
}

// Source: 参考文件/aishedule-master/YN智慧校园/德阳通用电子科技学校/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-09-18 19:57:55
 * @LastEditTime: 2022-09-18 21:14:14
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\新正方教务\山东师范大学\parser.js
 * @QQ: 357914968
 */
function resolveCourseConflicts(result) {
    let splitTag = '&'
    //将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach((singleCourse) => {
      singleCourse.weeks.forEach((week) => {
        singleCourse.sections.forEach((value) => {
          let course = { sections: [], weeks: [] }
          course.name = singleCourse.name
          course.teacher =
            singleCourse.teacher == undefined ? '' : singleCourse.teacher
          course.position =
            singleCourse.position == undefined ? '' : singleCourse.position
          course.day = singleCourse.day
          course.weeks.push(week)
          course.sections.push(value)
          allResultSet.add(JSON.stringify(course))
        })
      })
    })
    let allResult = JSON.parse(
      '[' + Array.from(allResultSet).toString() + ']'
    ).sort(function (a, b) {
      //return b.day - e.day;
      return a.day - b.day || a.sections[0] - b.sections[0]
    })
  
    //将冲突的课程进行合并
    let contractResult = []
    while (allResult.length !== 0) {
      let firstCourse = allResult.shift()
      if (firstCourse == undefined) continue
      let weekTag = firstCourse.day
      //   console.log(firstCourse)
      for (
        let i = 0;
        allResult[i] !== undefined && weekTag === allResult[i].day;
        i++
      ) {
        if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
          if (firstCourse.sections[0] === allResult[i].sections[0]) {
            let index = firstCourse.name
              .split(splitTag)
              .indexOf(allResult[i].name)
            if (index === -1) {
              firstCourse.name += splitTag + allResult[i].name
              firstCourse.teacher += splitTag + allResult[i].teacher
              firstCourse.position += splitTag + allResult[i].position
              // firstCourse.position = firstCourse.position.replace(/undefined/g, '')
              allResult.splice(i, 1)
              i--
            } else {
              let teacher = firstCourse.teacher.split(splitTag)
              let position = firstCourse.position.split(splitTag)
              teacher[index] =
                teacher[index] === allResult[i].teacher
                  ? teacher[index]
                  : teacher[index] + ',' + allResult[i].teacher
              position[index] =
                position[index] === allResult[i].position
                  ? position[index]
                  : position[index] + ',' + allResult[i].position
              firstCourse.teacher = teacher.join(splitTag)
              firstCourse.position = position.join(splitTag)
              // firstCourse.position = firstCourse.position.replace(/undefined/g, '');
              allResult.splice(i, 1)
              i--
            }
          }
        }
      }
      contractResult.push(firstCourse)
    }
    //将每一天内的课程进行合并
    let finallyResult = []
    while (contractResult.length != 0) {
      let firstCourse = contractResult.shift()
      if (firstCourse == undefined) continue
      let weekTag = firstCourse.day
      for (
        let i = 0;
        contractResult[i] !== undefined && weekTag === contractResult[i].day;
        i++
      ) {
        if (
          firstCourse.weeks[0] === contractResult[i].weeks[0] &&
          firstCourse.name === contractResult[i].name &&
          firstCourse.position === contractResult[i].position &&
          firstCourse.teacher === contractResult[i].teacher
        ) {
          if (
            firstCourse.sections[firstCourse.sections.length - 1] + 1 ===
            contractResult[i].sections[0]
          ) {
            firstCourse.sections.push(contractResult[i].sections[0])
            contractResult.splice(i, 1)
            i--
          } else break
          // delete (contractResult[i])
        }
      }
      finallyResult.push(firstCourse)
    }
    //将课程的周次进行合并
    contractResult = JSON.parse(JSON.stringify(finallyResult))
    finallyResult.length = 0
    while (contractResult.length != 0) {
      let firstCourse = contractResult.shift()
      if (firstCourse == undefined) continue
      let weekTag = firstCourse.day
      for (
        let i = 0;
        contractResult[i] !== undefined && weekTag === contractResult[i].day;
        i++
      ) {
        if (
          firstCourse.sections.sort((a, b) => a - b).toString() ===
            contractResult[i].sections.sort((a, b) => a - b).toString() &&
          firstCourse.name === contractResult[i].name &&
          firstCourse.position === contractResult[i].position &&
          firstCourse.teacher === contractResult[i].teacher
        ) {
          firstCourse.weeks.push(contractResult[i].weeks[0])
          contractResult.splice(i, 1)
          i--
        }
      }
      finallyResult.push(firstCourse)
    }
    console.log(finallyResult)
    return finallyResult
  }

function request(tag, data, url,anys) {
    if (anys==null) anys = false
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, anys);
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    xhr.send(data);
    return ss;
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let message =""
    let result = []
    try{
        let studentId =  window.localStorage["ls.platformSysUserId"].replace(/"/g,"")
        let systemIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/portal/queryServiceTypes.htm"
        let systemId = JSON.parse(request("get",null,systemIdUrl)).result.filter(v=>{return v.name == "教务教学"})[0].serviceLevelMenuList.filter(v=>{return v.name == "查看课表"})[0].id
        let menuIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/portal/queryMenusOfService.htm?serviceId="+systemId
        let menuId = JSON.parse(request("get",null,menuIdUrl)).result.children.filter(v=>{return v.name =="我的课表"})[0].id
        let teamIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/commonDropDownListController/queryAllUseAbleTerms.htm"
        let termId = JSON.parse(request("get",null,teamIdUrl)).result.filter(v=>{return v.typeDesc=="当前学期"})[0].id


        let courseUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/schoolTimetable/studentTimetable/getStudentTimetableData.htm"
        alert("准备就绪，受网络影响本次导入大概需要一些10s左右，点击确定开始导入，请等待！！！")
        for(let i = 1;i<=30;i++){
            console.log(i)
            let data = "termId="+termId+"&week="+i+"&studentId="+studentId+"&systemId="+systemId+"&menuId="+menuId
            let jsonText = request("post",data,courseUrl)
            let list = JSON.parse(jsonText).result.timeTableTimeTypeProcessVOList
            let jc=0
            list.forEach(con=>{
                let secs = con.timePeriodProcessVOList
                secs.forEach((sec,secIndex)=>{
                    jc++;
                    let courses = sec.knobProcessVOList
                    courses.forEach((weeks,weekIndx)=>{
                        if(!weeks.detailVOList) return
                        let couseInfo=weeks.detailVOList[0]
                        //                     console.log(jc,weekIndx+1,couseInfo)
                        result.push({
                            name:couseInfo.courseName,
                            teacher:couseInfo.teacherNames,
                            position:!couseInfo.classRoomNames?"":couseInfo.classRoomNames,
                            day:weekIndx+1,
                            sections:[jc],
                            weeks:[i]
                        })
                    })
                })
            })
            if(i==15) alert("已解析到第15周，点击确定继续解析。。。。")
        }
        if(result.length==0) message = "课表获取失败"
        else result = resolveCourseConflicts(result)
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
            sections: [1, 2,  3]
        });
    }
    return JSON.stringify(result)
}

// Merged parser.js

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改


    return JSON.parse(html)
}

// Merged timer.js

/**
 *
 * @param xJConf : {lunchTime: {time: number, begin: number}, longRestingTimeBegin: number[], abnormalRestingTime: [{time: number, begin: number}, {time: number, begin: number}], oneCourseTime: number, longRestingTime: number, dinnerTime: {time: number, begin: number}, startTime: string, shortRestingTime: number, courseSum: number, abnormalClassTime: [{time: number, begin: number}]} : 夏季时间
 * @param [dJConf] : {lunchTime: {time: number, begin: number}, longRestingTimeBegin: number[], oneCourseTime: number, longRestingTime: number, dinnerTime: {time: number, begin: number}, startTime: string, shortRestingTime: number, courseSum: number, abnormalClassTime: [{time: number, begin: number}]} : 冬季时间 可选参数
 * @param [timeRangeConf] : {summerBegin:String, summerEnd: String}
 * @returns {Array[{section:Number, startTime:String, endTime:String}]} 返回时间数组
 * @example
 *let Conf=
 {
       courseSum: 11,
       startTime: '800',
       oneCourseTime: 45,
       longRestingTime: 20,
       shortRestingTime: 10,
       longRestingTimeBegin: [2],
       lunchTime: {begin: 4, time: 2 * 60 + 50},
       dinnerTime: {begin: 8, time: 60},
       abnormalClassTime:[{begin:11,time:40}]
      }

 =>  getTimes(Conf) =>

 [
 { section: 1, startTime: '08:00', endTime: '08:45' },
 { section: 2, startTime: '08:55', endTime: '09:40' },
 { section: 3, startTime: '10:00', endTime: '10:45' },
 { section: 4, startTime: '10:55', endTime: '11:40' },
 { section: 5, startTime: '14:30', endTime: '15:15' },
 { section: 6, startTime: '15:25', endTime: '16:10' },
 { section: 7, startTime: '16:20', endTime: '17:05' },
 { section: 8, startTime: '17:15', endTime: '18:00' },
 { section: 9, startTime: '19:00', endTime: '19:45' },
 { section: 10, startTime: '19:55', endTime: '20:40' },
 { section: 11, startTime: '20:50', endTime: '21:30' }
 ]
 */
 function getTimes(xJConf, dJConf ,timeRangeConf={
    summerBegin:'04/30',
    summerEnd:'10/01'
}) {
   //xJConf : 夏季时间配置文件
   //dJConf : 冬季时间配置文件
   //return : Array[{},{}]
   let summerBegin = timeRangeConf.summerBegin //夏令时开始时间 :'04/30'
   let summerEnd = timeRangeConf.summerEnd //夏令时结束时间:'10/01'

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
       if (abnormalClassTime !== undefined) abnormalClassTime.forEach(time => { classTimeMap.set(time.begin, time.time) });
       if (longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time => RestingTimeMap.set(time, longRestingTime));
       if (lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin, lunchTime.time);
       if (dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin, dinnerTime.time);
       if (abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => { RestingTimeMap.set(time.begin, time.time) });

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
           }
           else {
               timeSum += RestingTimeMap.get(j - 1) === undefined ? shortRestingTime : RestingTimeMap.get(j - 1);
               studyOrRestTag = true;
           }
       }
       return result;
   }

   let nowDate = new Date();
   let year = nowDate.getFullYear();                       //2020
   let wuYi = new Date(year + "/" + summerBegin);           //2020/05/01
   let jiuSanLing = new Date(year + "/" + summerEnd);     //2020/09/30
   let xJTimes = getTime(xJConf);
   let dJTimes = getTime(dJConf);
   console.log("夏季时间:\n",xJTimes)
   console.log("冬季时间:\n", dJTimes)
   if (nowDate >= wuYi && nowDate <= jiuSanLing) {
       return xJTimes;
   }
   else  {
       return dJTimes;
   }
}

/**
* 时间配置函数，此为入口函数，不要改动函数名
*/
async function scheduleTimer() {

   let timeJson = {
       totalWeek: 24, // 总周数：[1, 30]之间的整数
       startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
       startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
       showWeekend: true, // 是否显示周末
       forenoon: 4, // 上午课程节数：[1, 10]之间的整数
       afternoon: 4, // 下午课程节数：[0, 10]之间的整数
       night: 3, // 晚间课程节数：[0, 10]之间的整数
       sections: []
   }
   
   //夏令时配置
   let xJConf = {
    courseSum: 11,
    startTime: '805',
    oneCourseTime: 45,
    longRestingTime: 35,
    shortRestingTime: 10,
    longRestingTimeBegin: [2],
    lunchTime: {begin: 4, time: 2 * 60 + 40},
    dinnerTime: {begin: 7, time: 100},
    abnormalClassTime: [{begin: 8, time: 65},{begin: 10, time: 50},{begin: 11, time: 30}],
    abnormalRestingTime:[{begin:5,time:15},{begin:10,time:0}]
   }


   //冬季时间配置
   let dJConf = {
       courseSum: 11,
       startTime: '800',
       oneCourseTime: 45,
       longRestingTime: 20,
       shortRestingTime: 10,
       longRestingTimeBegin: [2,6],
       lunchTime: {begin: 4, time: 2 * 60 + 50},
       dinnerTime: {begin: 8, time: 60},
       abnormalClassTime: [{begin: 11, time: 40}],
   }

   //夏令时时间区间
   let timeRangeConf = {
       summerBegin:'03/01',
       summerEnd:'10/30'
   }

//    timeJson.sections = getTimes(xJConf,dJConf,timeRangeConf) //分东夏零时
   timeJson.sections = getTimes(xJConf)//不分 

  if(timeJson.sections.length==0) timeJson = {}
   return timeJson
   // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

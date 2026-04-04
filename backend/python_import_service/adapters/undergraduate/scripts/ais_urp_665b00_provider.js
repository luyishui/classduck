// Source: 参考文件/aishedule-master/URP教务/烟台大学/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-08-22 16:34:58
 * @LastEditTime: 2022-08-22 16:35:00
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\URP教务\烟台大学\provider.js
 * @QQ: 357914968
 */


async function req(method, url, data) {
  return await fetch(url, { method: method, body: data }).then(v => v.text()).then(v => v).catch(v => v)
}
async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {


  let html
  let url1 = "/student/courseSelect/thisSemesterCurriculum/callback"  //get thisSemesterCurriculum  //post calendarSemesterCurriculum planCode: 2023-2024-1-1
  let url2 = "/student/courseSelect/thisSemesterCurriculum/ajaxStudentSchedule/callback"     //get courseSelect
  let plancode = !document.getElementById("planCode") ? '' : document.getElementById("planCode").value


  let preUrl = window.location.href

  if (preUrl.search('webvpn') != -1) {
    await AIScheduleAlert(preUrl)
    html = document.getElementById('courseTable').outerHTML
    return JSON.stringify({ data: html, tag: true })
  }

  try {
    if (preUrl.search('thisSemesterCurriculum') != -1) {
      html = await req('get', url1)
    }
    else if (preUrl.search('calendarSemesterCurriculum') != -1) {
      let formData = new FormData()
      formData.set("planCode", plancode)
      html = await req('post', url2, formData)
    }
    else if (preUrl.search('courseSelectResult') != -1) {
      html = await req('get', url1)
    }
    else {
      html = await req('get', url1)
    }
    return JSON.stringify({ data: html, tag: false })
  } catch (e) {
    html = document.getElementById('courseTable').outerHTML
    return JSON.stringify({ data: html, tag: true })
  }

}


// async function scheduleHtmlProvider(
//   iframeContent = '',
//   frameContent = '',
//   dom = document
// ) {

//   alert("test")



// }

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-08-22 16:35:05
 * @LastEditTime: 2022-08-22 16:35:06
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\URP教务\烟台大学\parser.js
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
        course.teacher = singleCourse.teacher
        course.position = singleCourse.position
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
            firstCourse.position = firstCourse.position.replace(
              /undefined/g,
              ''
            )
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
            firstCourse.position = firstCourse.position.replace(
              /undefined/g,
              ''
            )
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
  // contractResult = contractResult.sort(function (a, b) {
  //     return (a.day - b.day)||(a.sections[0]-b.sections[0]);
  // })
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
  // contractResult = contractResult.sort(function (a, b) {
  //     return a.day - b.day;
  // })
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
function getWeeks(Str) {
  function range(con, tag) {
    let retWeek = []
    con
      .slice(0, -1)
      .split(',')
      .forEach((w) => {
        let tt = w.split('-')
        let start = parseInt(tt[0])
        let end = parseInt(tt[tt.length - 1])
        if (tag === 1 || tag === 2)
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((f) => {
                return f % tag === 0
              })
          )
        else
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((v) => {
                return v % 2 !== 0
              })
          )
      })
    return retWeek
  }
  Str = Str.replace(/[(){}|第\[\]]/g, '').replace(/到/g, '-')
  let reWeek = []
  let week1 = []
  while (Str.search(/周|\s/) !== -1) {
    let index = Str.search(/周|\s/)
    if (Str[index + 1] === '单' || Str[index + 1] === '双') {
      week1.push(Str.slice(0, index + 2).replace(/周|\s/g, ''))
      index += 2
    } else {
      week1.push(Str.slice(0, index + 1).replace(/周|\s/g, ''))
      index += 1
    }

    Str = Str.slice(index)
    index = Str.search(/\d/)
    if (index !== -1) Str = Str.slice(index)
    else Str = ''
  }
  if (Str.length !== 0) week1.push(Str)
  console.log(week1)
  week1.forEach((v) => {
    console.log(v)
    if (v.slice(-1) === '双') reWeek.push(...range(v, 2))
    else if (v.slice(-1) === '单') reWeek.push(...range(v, 3))
    else reWeek.push(...range(v + '全', 1))
  })
  return reWeek
}

/**
 *
 * @param Str : String : 如: 1-4节 或 1-2-3-4节
 * @returns {Array[{section:Number}]}
 * @example
 * getSection("1-4节")=>[{section:1},{section:2},{section:3},{section:4}]
 */
function getSection(Str) {
  console.log(Str)
  let rejc = []
  let strArr = Str.replace('节', '').replace(/\s/g, '').split('-')
  if (strArr.length <= 2) {
    for (let i = Number(strArr[0]); i <= strArr[strArr.length - 1]; i++) {
      console.log(strArr, i)
      rejc.push(Number(i))
    }
  } else {
    strArr.forEach((v) => {
      rejc.push(Number(v))
    })
  }
  console.log(strArr, rejc)
  return rejc
}

function scheduleHtmlParser(html) {
  //除函数名外都可编辑
  //传入的参数为上一步函数获取到的html
  //可使用正则匹配
  //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
  //以下为示例，您可以完全重写或在此基础上更改
  let result = []
  let message = ''
  let json = JSON.parse(html)
  console.log(json.tag)
  try {
    if (!json.tag) {
      let courses = JSON.parse(json.data).dateList[0].selectCourseList
      courses.forEach((course) => {
        //  let re = {weeks:[],sections:[]} ;
        let name = course.courseName
        let teacher = course.attendClassTeacher
          .replace('*', '')
          .trim()
          .replace(/\s+/g, ',')
        if (!course.timeAndPlaceList) return
        course.timeAndPlaceList.forEach((time) => {
          let day = time.classDay
          let position = time.teachingBuildingName + time.classroomName
          let weeks = new Array()
          let sections = new Array()
          time.classWeek.split('').forEach((em, index) => {
            if (em == 1) weeks.push(index + 1)
          })
          for (let i = 0; i < time.continuingSession; i++) {
            sections.push(time.classSessions + i)
          }
          result.push(
            JSON.parse(
              JSON.stringify({
                name: name,
                teacher: teacher,
                position: position,
                day: day,
                weeks: weeks,
                sections: sections,
              })
            )
          )
        })
      })
    } else {
      let $ = cheerio.load(json.data, { decodeEntities: false })
      let hang = $('#courseTableBody tr')
      for (let i = 0; i < hang.length; i++) {
        let lie = $('td', hang.eq(i))
        for (let j = 0; j < lie.length; j++) {
          let kc = lie.eq(j).children('div')
          if (kc.length == 0) {
            continue
          }
          kc.each(function (i, elem) {
            console.log($(this).html())
            let re = { weeks: [], sections: [] }
            let pa = $(this).children('p')
            console.log(pa)
            re.name = pa.eq(0).text().split('_')[0]
            re.position = pa
              .eq(4)
              .text()
              .replace(/.*?[校区]/g, '')
            re.teacher = pa
              .eq(1)
              .text()
              .replace('*', '')
              .trim()
              .replace(/\s+/g, ',')
              

            re.day = j + 1
            //                  re.sections=getSection(pa.eq(3).text().match(/(?<=（).*(?=）)/)[0])
            //                  re.weeks = getWeeks(pa.eq(3).text().split("（")[0]);

            console.log(pa
              .eq(3)
              .text())
            re.sections = getSection(
              pa
                .eq(3)
                .text()
                // .match(/\((.+?)\)|（(.+?)）/g)[0]
                // .replace(/[\(\)（）]/g, '')
                // .trim()
            )
            console.log(re)
            re.weeks = getWeeks(
              pa
                .eq(2)
                .text()
                .split(/[\(（]/g)[0]
            )

            console.log(re)
            result.push(re)
          })
        }
      }
    }

    if (result.length == 0) message = '课表获取失败'
    else result = resolveCourseConflicts(result)
  } catch (err) {
    console.log(err)
    message = err.message.slice(0, 50)
  }
  if (message.length !== 0) {
    result.length = 0
    result.push({
      name: '遇到错误，请加qq群：628325112进行反馈',
      teacher: '开发者-萧萧',
      position: message,
      day: 1,
      weeks: [1],
      sections: [{ section: 1 }, { section: 2 }, { section: 3 }],
    })
  }

  console.log(result)
  return result
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-08-22 16:35:10
 * @LastEditTime: 2022-08-22 16:35:11
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\URP教务\烟台大学\timer.js
 * @QQ: 357914968
 */
function getTimes(xJConf, dJConf) {
  //xJConf : 夏季时间配置文件
  //dJConf : 冬季时间配置文件
  //return : Array[{},{}]
  dJConf = dJConf === undefined ? xJConf : dJConf

  function getTime(conf) {
    let courseSum = conf.courseSum //课程节数 : 12
    let startTime = conf.startTime //上课时间 :800
    let oneCourseTime = conf.oneCourseTime //一节课的时间
    let shortRestingTime = conf.shortRestingTime //小班空

    let longRestingTimeBegin = conf.longRestingTimeBegin //大班空开始位置
    let longRestingTime = conf.longRestingTime //大班空
    let lunchTime = conf.lunchTime //午休时间
    let dinnerTime = conf.dinnerTime //下午休息
    let abnormalClassTime = conf.abnormalClassTime //其他课程时间长度
    let abnormalRestingTime = conf.abnormalRestingTime //其他休息时间

    let result = []
    let studyOrRestTag = true
    let timeSum = startTime.slice(-2) * 1 + startTime.slice(0, -2) * 60

    let classTimeMap = new Map()
    let RestingTimeMap = new Map()
    if (abnormalClassTime !== undefined)
      abnormalClassTime.forEach((time) => {
        classTimeMap.set(time.begin, time.time)
      })
    if (longRestingTimeBegin !== undefined)
      longRestingTimeBegin.forEach((time) =>
        RestingTimeMap.set(time, longRestingTime)
      )
    if (lunchTime !== undefined)
      RestingTimeMap.set(lunchTime.begin, lunchTime.time)
    if (dinnerTime !== undefined)
      RestingTimeMap.set(dinnerTime.begin, dinnerTime.time)
    if (abnormalRestingTime !== undefined)
      abnormalRestingTime.forEach((time) => {
        RestingTimeMap.set(time.begin, time.time)
      })

    for (let i = 1, j = 1; i <= courseSum * 2; i++) {
      if (studyOrRestTag) {
        let startTime =
          ('0' + Math.floor(timeSum / 60)).slice(-2) +
          ':' +
          ('0' + (timeSum % 60)).slice(-2)
        timeSum +=
          classTimeMap.get(j) === undefined
            ? oneCourseTime
            : classTimeMap.get(j)
        let endTime =
          ('0' + Math.floor(timeSum / 60)).slice(-2) +
          ':' +
          ('0' + (timeSum % 60)).slice(-2)
        studyOrRestTag = false
        result.push({
          section: j++,
          startTime: startTime,
          endTime: endTime,
        })
      } else {
        timeSum +=
          RestingTimeMap.get(j - 1) === undefined
            ? shortRestingTime
            : RestingTimeMap.get(j - 1)
        studyOrRestTag = true
      }
    }
    return result
  }

  let nowDate = new Date()
  let year = nowDate.getFullYear() //2020
  let wuYi = new Date(year + '/' + '05/01') //2020/05/01
  let jiuSanLing = new Date(year + '/' + '09/30') //2020/09/30
  let shiYi = new Date(year + '/' + '10/01') //2020/10/01
  let nextSiSanLing = new Date(year + 1 + '/' + '04/30') //2021/04/30
  let previousShiYi = new Date(year - 1 + '/' + '10/01') //2019/10/01
  let siSanLing = new Date(year + '/' + '04/30') //2020/04/30
  let xJTimes = getTime(xJConf)
  let dJTimes = getTime(dJConf)
  console.log('夏季时间:\n', xJTimes)
  console.log('冬季时间:\n', dJTimes)
  if (nowDate >= wuYi && nowDate <= jiuSanLing) {
    return xJTimes
  } else if (
    (nowDate >= shiYi && nowDate <= nextSiSanLing) ||
    (nowDate >= previousShiYi && nowDate <= siSanLing)
  ) {
    return dJTimes
  }
}
/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function timeReq(method, url, data) {
  return await fetch(url, { method: method, body: data })
    .then((v) => v.json())
    .then((v) => v)
    .catch((v) => v)
}
async function scheduleTimer() {
  let nowMonth =  new Date().getMonth()+1

  let formData = new FormData()
  formData.set("planNumber","")
  formData.set("ff","f")
  formData.set("xqh",nowMonth>=2&nowMonth<=9?'02':'01')


  let data = (await timeReq("POST","/ajax/student/getSectionAndTime",formData)).data

  let secs = []
  data.sectionTime.forEach(v=>{
    secs.push({
      startTime: v.startTime.slice(0,2)+":"+v.startTime.slice(2,4),
      section: v.id.session,
      endTime:v.endTime.slice(0,2)+":"+v.endTime.slice(2,4)
    })
  })

  return {
    totalWeek: 30, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: false, // 是否显示周末
    forenoon: data.section.swjc, // 上午课程节数：[1, 10]之间的整数
    afternoon: data.section.xwjc, // 下午课程节数：[0, 10]之间的整数
    night: data.section.wsjc, // 晚间课程节数：[0, 10]之间的整数
    sections:secs
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
  
}

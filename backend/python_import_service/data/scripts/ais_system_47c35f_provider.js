// Source: 参考文件/aishedule-master/自研教务/西安建筑科技大学/本科/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-08-09 21:46:03
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\西安建筑科技大学\本科\Provider.js
 * @QQ: 357914968
 */
async function getjson(method, data, url) {
  return await fetch(url, {
    method: method,
    body: data,
    headers: {
      'Content-Type': 'application/json',
    },
  })
    .then((v) => v.json())
    .then((v) => v)
    .catch((v) => v)
}
async function request(method, data, url) {
  return await fetch(url, {
    method: method,
    body: data,
    headers: {
      Server: '************',
    },
  })
    .then((v) => v.text())
    .then((v) => v)
    .catch((v) => v)
}
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')
  await AIScheduleAlert(
    '导入过程大概需要5秒左右，请点击确定开始导入\n当时间块（深蓝）与课程块（浅蓝）没有对齐时将会丢失课程，请悉知！！'
  )
  //   alert('导入过程大概需要5秒左右，请点击确定开始导入\n当时间块（深蓝）与课程块（浅蓝）没有对齐时将会丢失课程，请悉知！！')

  let cthtml = await request('get', null, '/student/for-std/course-table')
  bizTypeId = cthtml.match(/(?<=var bizTypeId \= ).*?(?=;)/)[0]
  semesterId =
    dom.getElementById('allSemesters') == null
      ? cthtml.match(/(?<=selected\="selected" value\=").*?(?="\>)/)[0]
      : dom.getElementById('allSemesters').value
  stdPersonId = cthtml.match(/(?<=data\['stdPersonId'\] = ).*?(?=;)/)[0]
  studentId = cthtml.match(/(?<=data\['studentId'\] = ).*?(?=;)/)[0]
  let kcjson = await getjson(
    'get',
    null,
    '/student/for-std/course-table/get-data?bizTypeId=' +
      bizTypeId +
      '&semesterId=' +
      semesterId
  )
  let data = {
    lessonIds: kcjson.lessonIds,
    stdPersonId: Number(stdPersonId),
    studentId: studentId == 'null' ? null : studentId,
    weekIndex: null,
  }
  console.log(kcjson)

  starTime = await getjson(
    'post',
    JSON.stringify({ timeTableLayoutId: kcjson.timeTableLayoutId }),
    '/student/ws/schedule-table/timetable-layout'
  )
  startTimeJson = starTime.result.courseUnitList
  let daum = await getjson(
    'post',
    JSON.stringify(data),
    '/student/ws/schedule-table/datum'
  )
  //   console.log(daum.result)
  //   console.log(startTimeJson)
  return JSON.stringify({
    courseJson: daum.result,
    startTimeJson: startTimeJson,
  })
}

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-08-09 21:30:27
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\西安建筑科技大学\本科\Parser.js
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
function getjcc(sta, num, timeMap) {
  num1 = timeMap.get(sta)
  let sec = []
  for (let i = 0; i < num; i++) {
    sec.push(num1++)
  }
  return sec
}
function scheduleHtmlParser(html) {
  //除函数名外都可编辑
  //传入的参数为上一步函数获取到的html
  //可使用正则匹配
  //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
  //以下为示例，您可以完全重写或在此基础上更改
  let allJson = JSON.parse(html)
  //   console.log(allJson)
  let startTimes = allJson.startTimeJson
  let re = allJson.courseJson
  let schlist = re.scheduleList
  let leslist = re.lessonList
  //    console.log(re)
  let timeMap = new Map()
  startTimes.forEach((time) => {
    timeMap.set(time.startTime, time.indexNo)
  })
  //    console.log(timeMap)
  let kcmap = new Map()
  leslist.forEach((vv) => {
    kcmap.set(vv.id, vv.courseName)
  })
  //   console.log(kcmap)
  let result = []
  schlist.forEach((vv) => {
    console.log(vv)
    let re = { weeks: [], sections: [] }
    re.name = kcmap.get(vv.lessonId)
    re.teacher = vv.personName
    re.position = vv.room == null ? '' : vv.room.nameZh
    re.day = vv.weekday
    if (vv.weekIndex <= 0) return
    re.weeks.push(vv.weekIndex)
    re.sections = getjcc(vv.startTime, vv.periods, timeMap)
    result.push(re)
    //        console.log(re)
  })
  let data = resolveCourseConflicts(result)

  data = data.filter(function (s) {
    return s && s != undefined
  })
  console.log(data)
  return data
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-08-09 20:52:30
 * @LastEditTime: 2022-08-09 20:54:05
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\西安建筑科技大学\本科\timer.js
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
async function scheduleTimer() {
  // 内嵌loadTool工具，传入工具名即可引用公共工具函数(暂未确定公共函数，后续会开放)
  // await loadTool('AIScheduleTools')
  // const { AIScheduleAlert } = AIScheduleTools()
  // // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
  // await AIScheduleAlert('liuwenkiii yyds!')
  // // 支持异步操作 推荐await写法
  // const someAsyncFunc = () => new Promise(resolve => {
  //   setTimeout(() => resolve(), 100)
  // })
  // await someAsyncFunc()
  // 返回时间配置JSON，所有项都为可选项，如果不进行时间配置，请返回空对象
  return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: false, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 4, // 晚间课程节数：[0, 10]之间的整数
    sections: getTimes({
      courseSum: 12,
      startTime: '0830',
      oneCourseTime: 45,
      longRestingTime: 10,
      shortRestingTime: 5,
      longRestingTimeBegin: [4, 8],
      // lunchTime: { begin: 4, time: 2 * 60 },
      dinnerTime: { begin: 10, time: 130 },
      abnormalRestingTime: [
        { begin: 2, time: 20 },
        { begin: 6, time: 15 },
      ],
    }), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

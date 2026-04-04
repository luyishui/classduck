// Source: 参考文件/aishedule-master/eurasia/西安欧亚学院/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-09-16 20:43:52
 * @LastEditTime: 2022-09-16 21:24:06
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\eurasia\西安欧亚学院\provider.js
 * @QQ: 357914968
 */
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')
  await AIScheduleAlert(`
  >>导入流程<<
  1.点击左上角9个点的logo（可能会被橙色警告窗遮住，请先关闭橙色警告窗）
  2.点击课表
  3.点击学期课表
  4.点击一键导入
  `)
  if (document.URL.search('OuterStudWeekOfTimeTable') === -1) {
    await AIScheduleAlert('请先定位到学期课表')
    return 'do not continue'
  }
  const ifrs = dom.getElementById(
    'ContentPlaceHolder1_ucTimetableInWeeks1_tabTimetableInWeek'
  )

  return ifrs.outerHTML
}

// Merged parser.js

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
function getjc(Str) {
  let arr = Str.split(/-|,/)
  let sec = []
  arr.forEach((v) => {
    sec.push(Number(v))
  })
  return sec
}
function scheduleHtmlParser(html) {
  //除函数名外都可编辑
  //传入的参数为上一步函数获取到的html
  //可使用正则匹配
  //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
  //以下为示例，您可以完全重写或在此基础上更改
  let result = []
  let $ = cheerio.load(html, { decodeEntities: false })
  let trs = $('table tr')
  trs.each(function (index, _) {
    if (index == 0) return
    let tds = $(this).find('td')
    tds.each(function (weekofday, __) {
      if (weekofday == 0) return
      cours = $(this).find('div')
      cours.each(function (index1, ___) {
        let course = { weeks: [], sections: [] }
        let conar = $(this).html().split('<br>')
        if (conar.length < 4) return
        if (conar[0].indexOf('晨读') != -1) return
        course.sections = getjc(
          conar[0].match(/(?<=\>).*?(?=\<)/)[0].replace(/\s|第|节/g, '')
        )
        course.name = conar[1]
        course.teacher = conar[2]
        course.position = conar[3]
        course.weeks.push(index)
        course.day = weekofday
        result.push(course)
      })
    })
  })
  let data = resolveCourseConflicts(result)
  return data
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-09-16 20:44:14
 * @LastEditTime: 2022-09-16 20:57:12
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\eurasia\西安欧亚学院\timer.js
 * @QQ: 357914968
 *
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
function getTimes(
  xJConf,
  dJConf,
  timeRangeConf = {
    summerBegin: '04/30',
    summerEnd: '10/01',
  }
) {
  //xJConf : 夏季时间配置文件
  //dJConf : 冬季时间配置文件
  //return : Array[{},{}]
  let summerBegin = timeRangeConf.summerBegin //夏令时开始时间 :'04/30'
  let summerEnd = timeRangeConf.summerEnd //夏令时结束时间:'10/01'

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
  let wuYi = new Date(year + '/' + summerBegin) //2020/05/01
  let jiuSanLing = new Date(year + '/' + summerEnd) //2020/09/30
  let xJTimes = getTime(xJConf)
  let dJTimes = getTime(dJConf)
  console.log('夏季时间:\n', xJTimes)
  console.log('冬季时间:\n', dJTimes)
  if (nowDate >= wuYi && nowDate <= jiuSanLing) {
    return xJTimes
  } else {
    return dJTimes
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
    forenoon: 6, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 4, // 晚间课程节数：[0, 10]之间的整数
    sections: [],
  }

  //夏令时配置
  let xJConf = {
    courseSum: 14,
    startTime: '900',
    oneCourseTime: 45,
    longRestingTime: 15,
    shortRestingTime: 0,
    longRestingTimeBegin: [2, 4, 6, 8, 10, 12],
    // lunchTime: { begin: 4, time: 0 },
    // dinnerTime: { begin: 8, time: 0 },
    // abnormalRestingTime: [{begin: 11, time: 5}, {begin: 12, time: 5}]
  }

  //    //冬季时间配置
  //    let dJConf = {
  //        courseSum: 11,
  //        startTime: '800',
  //        oneCourseTime: 45,
  //        longRestingTime: 20,
  //        shortRestingTime: 10,
  //        longRestingTimeBegin: [2,6],
  //        lunchTime: {begin: 4, time: 2 * 60 + 50},
  //        dinnerTime: {begin: 8, time: 60},
  //    //  abnormalClassTime: [{begin: 11, time: 40}],
  //    }

  //    //夏令时时间区间
  //    let timeRangeConf = {
  //        summerBegin:'03/01',
  //        summerEnd:'10/30'
  //    }

  //  timeJson.sections = getTimes(xJConf,dJConf,timeRangeConf) //分东夏零时
  timeJson.sections = getTimes(xJConf) //不分

  if (timeJson.sections.length == 0) timeJson = {}
  return timeJson
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

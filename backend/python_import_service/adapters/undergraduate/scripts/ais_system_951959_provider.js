// Source: 参考文件/aishedule-master/自研教务/山西工程科技职业大学/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-08-11 19:45:40
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\山西工程科技职业大学\provider.js
 * @QQ：357914968
 */

async function request(tag, data, url) {
  return await fetch(url, {
    method: tag,
    body: data,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  })
    .then((rp) => rp.json())
    .then((v) => v)
}
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
    let t = ['loading', 'loading.', 'loading..', 'loading...']
    if (count == 4) count = 0
    content.innerText = t[count++]
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
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  const OLD_ID = 'iframe123103'
  let kbjson = ''
  try {
    let ifs = document.getElementsByTagName('iframe')
    for (const i of ifs) {
      if (i.style.display !== 'none') {
        if (i.id === OLD_ID) {
          let Zxjxjhh = i.contentDocument.getElementById('Zxjxjhh').value
          kbjson = await request(
            'POST',
            'Zxjxjhh=' + Zxjxjhh,
            '/Tresources/A1Xskb/GetXsKb'
          )
        } else {
          kbjson = await request('POST', null, '/Tresources/A1Xskb/GetXsKb')
        }
      }
    }
  } catch (e) {
    console.error(e)
    try {
      kbjson = await request('POST', null, '/Tresources/A1Xskb/GetXsKb')
      // loadd.close()
    } catch (e) {
      await AIScheduleAlert(e)
    }
  }
  console.log(kbjson.rows)
  return JSON.stringify(kbjson.rows)
}

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-08-11 17:13:33
 * @LastEditTime: 2022-08-11 19:38:46
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\山西工程科技职业大学\parser.js
 * @QQ: 357914968
 */
/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-03-01 22:28:45
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\新正方教务\盐城师范学院\parser.js
 * @QQ：357914968
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
        if (tag == 1 || tag == 2)
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((f) => {
                return f % tag == 0
              })
          )
        else
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((v) => {
                return v % 2 != 0
              })
          )
      })
    return retWeek
  }
  Str = Str.replace(/\(|\)|\{|\}|\||第/g, '').replace(/到/g, '-')
  let reWeek = []
  let week1 = []
  while (Str.search(/周/) != -1) {
    let index = Str.search(/周/)
    if (Str[index + 1] == '单' || Str[index + 1] == '双') {
      week1.push(Str.slice(0, index + 2).replace('周', ''))
      index += 2
    } else {
      week1.push(Str.slice(0, index + 1).replace('周', ''))
      index += 1
    }

    Str = Str.slice(index)
    index = Str.search(/\d/)
    if (index != -1) Str = Str.slice(index)
    else Str = ''
  }
  if (Str.length != 0) week1.push(Str)

  week1.forEach((v) => {
    console.log(v)
    if (v.slice(-1) == '双') reWeek.push(...range(v, 2))
    else if (v.slice(-1) == '单') reWeek.push(...range(v, 3))
    else reWeek.push(...range(v + '全', 1))
  })
  return reWeek
}
function getSections(Str) {
  Str = Str.replace(/节/g, '').split(',')
  let res = []
  Str.forEach((ss) => {
    let arr = ss.split('-')
    for (let i = Number(arr[0]); i <= arr[arr.length - 1]; i++) {
      res.push(i)
    }
  })
  console.log(Str, res)
  return res
}
function scheduleHtmlParser(html) {
  //除函数名外都可编辑
  //传入的参数为上一步函数获取到的html
  //可使用正则匹配
  //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
  //以下为示例，您可以完全重写或在此基础上更改

  let result = []
  //   let $ = cheerio.load(html, { decodeEntities: false })
  //   let bbb = $('div[class = "tab-pane fade active in"]')
  let message = ''
  let kbjson = JSON.parse(html)
  try {
    for (const kb of kbjson) {
      let re = { sections: [], weeks: [] }
      re.name = kb.Kcm
      re.reacher = kb.Jsm
      re.day = kb.Skxq
      re.position = kb.Jxlm + kb.Jasm
      re.sections = [...Array(kb.Cxjc)].map((e, i) => i + kb.Skjc)
      kb.Skzc.split('').forEach((v, i) => {
        if (v === '1') re.weeks.push(i + 1)
      })
      console.log(re)
      result.push(re)
    }

    if (result.length == 0) message = '没有获取到课表'
    else result = resolveCourseConflicts(result)
  } catch (e) {
    message = e.message
  }
  if (message.length != 0) {
    result.length = 0
    result.push({
      name: '遇到错误,请加群:628325112,找开发者进行反馈',
      teacher: '开发者-萧萧',
      position: message,
      day: 1,
      weeks: [1],
      sections: [{ section: 1 }, { section: 2 }],
    })
  }

  console.info(result)
  return result
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-08-11 19:51:11
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\山西工程科技职业大学\timer.js
 * @QQ：357914968
 */
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
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 2, // 晚间课程节数：[0, 10]之间的整数
    sections: [],
  }
  //夏令时配置
  let xJConf = {
    courseSum: 10,
    startTime: '820',
    oneCourseTime: 45,
    longRestingTime: 20,
    shortRestingTime: 10,
    longRestingTimeBegin: [2, 6],
    lunchTime: { begin: 4, time: 2 * 60 },
    dinnerTime: { begin: 8, time: 80 },
    //  abnormalClassTime: [{begin: 10, time: 40}],
    abnormalRestingTime: [{ begin: 9, time: 20 }],
  }

  //冬季时间配置
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

  // timeJson.sections = getTimes(xJConf,dJConf,timeRangeConf) //分东夏零时
  timeJson.sections = getTimes(xJConf) //不分

  if (timeJson.sections.length == 0) timeJson = {}
  return timeJson
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

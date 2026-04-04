// Source: 参考文件/aishedule-master/自研教务/南京中医药大学/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-10-23 20:34:28
 * @LastEditTime: 2022-10-24 21:40:11
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\南京中医药大学\provider.js
 * @QQ: 357914968
 */

/**
 * loading函数
 * @param {*} param0
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
/**
 * 请求方法
 * @param {*} method
 * @param {*} data
 * @param {*} url
 * @param {*} text
 * @returns
 */
async function request(method, data, url, isJson, text) {
  let loading = null
  if (!!text) {
    loading = new AIScheduleLoading({ contentText: text })
    loading.show()
  }
  return await fetch(url, {
    method: method,
    body: data,
    headers: {
      'Content-Type': 'application/json',
    },
  })
    .then((v) => (isJson ? v.json() : v.text()))
    .then((v) => {
      !!loading && loading.close()
      return v
    })
    .catch((v) => {
      !!loading && loading.close()
      return v
    })
}

async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  //  alert("导入过程大概需要5秒左右，请点击确定开始导入")
  await loadTool('AIScheduleTools')

  let preUrl = location.href.match(/^http.*?(?:webvpn[\d\w]+)/)
  let cthtml = await request(
    'get',
    null,
    `${preUrl}/student/for-std/course-table`,
    false,
    '加载中'
  )
  // await AIScheduleAlert(cthtml)
  bizTypeId = cthtml.match(/(?<=const bizTypeId \= ).*?(?=;)/)[0]
  // alert(bizTypeId)
  let semesterId = cthtml.match(/(?<="selected" value=").*?(?="\>)/)[0]

  let stdPersonId = cthtml.match(/(?<=var personId \= ).*?(?=;)/)[0]
  // alert(stdPersonId)
  let studentId = cthtml.match(/(?<=var dataId = ).*?(?=;)/)[0]
  // alert(studentId)

  let kcjson = await request(
    'get',
    null,
    `${preUrl}/student/for-std/course-table/get-data?bizTypeId=${bizTypeId}&semesterId=${semesterId}`,
    true,
    '获取资源中'
  )

  let data = {
    lessonIds: kcjson.lessonIds,
    stdPersonId: Number(stdPersonId),
    studentId: studentId == 'null' ? null : studentId,
    weekIndex: null,
  }
  // console.log(kcjson)

  starTime = await request(
    'post',
    JSON.stringify({ timeTableLayoutId: kcjson.timeTableLayoutId }),
    `${preUrl}/student/ws/schedule-table/timetable-layout`,
    true,
    '获取节次信息中'
  )
  startTimeJson = starTime.result.courseUnitList

  let daum = await request(
    'post',
    JSON.stringify(data),
    `${preUrl}/student/ws/schedule-table/datum`,
    true,
    '获取课程信息中'
  )
  console.log(daum)

  return JSON.stringify({
    courseJson: daum.result,
    startTimeJson: startTimeJson,
  })
}

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-10-23 20:34:56
 * @LastEditTime: 2022-10-23 22:05:04
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\南京中医药大学\parser.js
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
  // console.info(allResultSet)
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

  // console.log(JSON.parse(JSON.stringify(finallyResult)))
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
  // console.log(finallyResult)
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
  // console.log(allJson)
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
    // console.log(vv)
    let re = { weeks: [], sections: [] }
    re.name = kcmap.get(vv.lessonId)
    re.teacher = vv.personName
    re.position = vv.room == null ? '' : vv.room.nameZh
    re.day = vv.weekday
    re.weeks.push(vv.weekIndex)
    re.sections = getjcc(vv.startTime, vv.periods, timeMap)
    result.push(re)
    //        console.log(re)
  })
  // console.log(result)
  // return result
  return resolveCourseConflicts(result)
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-10-23 20:35:15
 * @LastEditTime: 2022-10-23 20:35:16
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\南京中医药大学\timer.js
 * @QQ: 357914968
 */
/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer() {
  // 内嵌loadTool工具，传入工具名即可引用公共工具函数(暂未确定公共函数，后续会开放)
  //   await loadTool('AIScheduleTools')
  //   const { AIScheduleAlert } = AIScheduleTools()
  //   // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
  //   await AIScheduleAlert('liuwenkiii yyds!')
  //   // 支持异步操作 推荐await写法
  //   const someAsyncFunc = () => new Promise(resolve => {
  //     setTimeout(() => resolve(), 100)
  //   })
  //   await someAsyncFunc()
  // 返回时间配置JSON，所有项都为可选项，如果不进行时间配置，请返回空对象
  return {
    //     totalWeek: 20, // 总周数：[1, 30]之间的整数
    //     startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    //     startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    //     showWeekend: false, // 是否显示周末
    //     forenoon: 1, // 上午课程节数：[1, 10]之间的整数
    //     afternoon: 0, // 下午课程节数：[0, 10]之间的整数
    //     night: 0, // 晚间课程节数：[0, 10]之间的整数
    //     sections: [{
    //       section: 1, // 节次：[1, 30]之间的整数
    //       startTime: '08:00', // 开始时间：参照这个标准格式5位长度字符串
    //       endTime: '08:50', // 结束时间：同上
    //     }], // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

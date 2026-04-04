// Source: 参考文件/aishedule-master/自研教务/贵州工程应用技术学院/provider.js

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
  try{


    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    //  alert("导入过程大概需要5秒左右，请点击确定开始导入")
    await loadTool('AIScheduleTools')

    // let preUrl = location.href.match(/^http.*?(?:webvpn[\d\w]+)/)
    let preUrl = "https://jwxt.gues.edu.cn"

    let cthtml = await request(
        'get',
        null,
        `${preUrl}/student/for-std/course-table`,
        false,
        '加载中'
    )

    let jsonStr = cthtml.match(/(?<=var currentSemester = ).*?(?=;)/)[0].replace(/'/g,'"')

    // alert(JSON.parse(jsonStr).id)
    let localSemester = localStorage.getItem('sSemester');
    var semesterId = localSemester ? localSemester : JSON.parse(jsonStr).id;


    let time =  await request('get'
        ,null
        ,`${preUrl}/student/for-std/course-table/semester/${semesterId}/print-data?semesterId=${semesterId}&hasExperiment=true`,
        true,"获取课程表中")
    // alert(JSON.stringify(time))
    // startTimeJson = starTime.result.courseUnitList
    startTimeJson = time.studentTableVms[0].timeTableLayout.courseUnitList

    // alert(JSON.stringify( time.studentTableVms[0].activities))
    return JSON.stringify({
      courseJson: time.studentTableVms[0].activities,
      startTimeJson: startTimeJson,
    })
  }catch(e){
    alert(e)
  }
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
  let res = allJson.courseJson
  let result = []


  res.forEach((vv) => {
    console.log(vv)
    let re = { weeks: [], sections: [] }
    re.name = vv.courseName
    re.teacher = vv.teachers.join(',')
    re.position = vv.room
    re.day = vv.weekday
    re.weeks = vv.weekIndexes
    re.sections = Array(vv.endUnit + 1 - vv.startUnit).fill(vv.startUnit).map((x, y) => x + y)
    result.push(re)

  })

  return resolveCourseConflicts(result)
}

// Merged timer.js

/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer({providerRes}) {

  let allJson = JSON.parse(providerRes)
  let res = allJson.startTimeJson

  console.log(res)
  let result = []


  let morning = 0;
  let afternon = 0;
  let night = 0;




  res.forEach(re=>{
    switch(re.dayPart){
      case "MORNING": morning++;break;
      case "AFTERNOON": afternon++;break;
      case "EVENING": night++;break;
    }

    re.startTime =  '' +re.startTime

    re.endTime =  ''+re.endTime


    result.push({
      section:re.segmentIndex,
      startTime:re.startTime.length===3?'0'+re.startTime.slice(0,1)+':'+re.startTime.slice(1):re.startTime.slice(0,2)+':'+re.startTime.slice(2),
      endTime:re.endTime.length===3?'0'+re.endTime.slice(0,1)+':'+re.endTime.slice(1):re.endTime.slice(0,2)+':'+re.endTime.slice(2)
    })
  })

  return {
    'totalWeek': 20, // 总周数：[1, 30]之间的整数
    'startSemester': '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    'startWithSunday': false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    'showWeekend': false, // 是否显示周末
    'forenoon': morning, // 上午课程节数：[1, 10]之间的整数
    'afternoon': afternon, // 下午课程节数：[0, 10]之间的整数
    'night': night, // 晚间课程节数：[0, 10]之间的整数
    'sections':result, // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

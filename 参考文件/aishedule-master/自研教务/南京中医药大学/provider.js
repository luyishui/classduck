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

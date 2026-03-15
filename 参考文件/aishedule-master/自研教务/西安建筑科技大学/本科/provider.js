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

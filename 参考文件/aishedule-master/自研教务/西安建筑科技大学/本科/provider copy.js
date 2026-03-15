/**
 * @Author: xiaoxiao
 * @Date: 2022-08-09 20:58:54
 * @LastEditTime: 2022-08-09 20:58:55
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\西安建筑科技大学\本科\provider copy.js
 * @QQ: 357914968
 */
/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-08-09 20:57:00
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\西安建筑科技大学\本科\Provider.js
 * @QQ: 357914968
 */
function getjson(tag, data, url) {
  let ss = ''
  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if (
      (xhr.readyState == 4 && xhr.status == 200) ||
      xhr.status == 304 ||
      xhr.status == 302
    ) {
      // readyState == 4说明请求已完成
      //     fn.call(xhr.responseText)  //从服务器获得数据
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestHeader('Content-Type', 'application/json')
  xhr.send(data)
  return ss
}
function request(tag, data, url) {
  let ss = ''
  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if (
      (xhr.readyState == 4 && xhr.status == 200) ||
      xhr.status == 304 ||
      xhr.status == 302
    ) {
      // readyState == 4说明请求已完成
      //     fn.call(xhr.responseText)  //从服务器获得数据
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestHeader('Server', '************')
  xhr.send(data)
  return ss
}
function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  alert('导入过程大概需要5秒左右，请点击确定开始导入')
  let cthtml = request('get', null, '/student/for-std/course-table')
  bizTypeId = cthtml.match(/(?<=var bizTypeId \= ).*?(?=;)/)[0]
  semesterId =
    dom.getElementById('allSemesters') == null
      ? cthtml.match(/(?<=selected\="selected" value\=").*?(?="\>)/)[0]
      : dom.getElementById('allSemesters').value
  stdPersonId = cthtml.match(/(?<=data\['stdPersonId'\] = ).*?(?=;)/)[0]
  studentId = cthtml.match(/(?<=data\['studentId'\] = ).*?(?=;)/)[0]
  let res = getjson(
    'get',
    null,
    '/student/for-std/course-table/get-data?bizTypeId=' +
      bizTypeId +
      '&semesterId=' +
      semesterId
  )
  let kcjson = JSON.parse(res)
  let data = {
    lessonIds: kcjson.lessonIds,
    stdPersonId: Number(stdPersonId),
    studentId: studentId == 'null' ? null : studentId,
    weekIndex: null,
  }
  console.log(kcjson)

  starTime = getjson(
    'post',
    JSON.stringify({ timeTableLayoutId: kcjson.timeTableLayoutId }),
    '/student/ws/schedule-table/timetable-layout'
  )
  startTimeJson = JSON.parse(starTime).result.courseUnitList

  let daum = getjson(
    'post',
    JSON.stringify(data),
    '/student/ws/schedule-table/datum'
  )
  daum = JSON.parse(daum).result
  return JSON.stringify({ courseJson: daum, startTimeJson: startTimeJson })
}

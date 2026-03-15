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
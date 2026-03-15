/**
 * @Author: xiaoxiao
 * @Date: 2022-06-26 08:36:28
 * @LastEditTime: 2022-06-26 09:08:04
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\强智教务\iframe强智\山东大学\provider.js
 * @QQ：357914968
 */
function myRequest(tag, url, data) {
  let ss = ''
  let xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if ((xhr.readyState === 4 && xhr.status === 200) || xhr.status === 304) {
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
  xhr.send(data)
  return ss
}

function getUrl(dom) {

  var kbjcmss = dom.getElementsByName("kbjcmsid");
  var kbjcmsid = "";
  for (var i = 0; i < kbjcmss.length; i++) {
    if (kbjcmss[i].className == "layui-this") {
      kbjcmsid = kbjcmss[i].getAttribute("data-value");
    }
  }
  console.log(dom.getElementsByClassName('search'))
  let selects = dom.getElementsByClassName('search')[0].getElementsByTagName('select')[0]
  console.log(selects)
  let index = selects.selectedIndex
  let text = selects[index].outerText

  return "/jsxsd/framework/mainV_index_loadkb.htmlx?rq=all&sjmsValue=" + kbjcmsid + "&xnxqid=" + text + "&xswk=false"

}

async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')

  let tagType = document.getElementsByClassName('tag active')[0].getAttribute('data-code')
  if (tagType === 'GRZX') {
    tagType = (await AIScheduleSelect({
      titleText: '课表类型',
      contentText: '请选择需要导出的课表类型',
      selectList: ['0:首页课表（需要位于首页,无教师信息,稳定性未知）', '1:学期理论课表（需要位于学期理论课表页,准确度高）'],
    })).split(":")[0]
  } else {
    tagType = '1'
  }

  let result = { tag: tagType, htmlStr: "" }
  if (tagType=='1') {
    console.log("1")
    let html = ''
    let tag = true
    try {
      let ifs = document.getElementsByTagName('iframe')
      for (let index = 0; index < ifs.length; index++) {
        const doms = ifs[index]
        if (doms.src && doms.src.search('/jsxsd/xskb/xskb_list.do') != -1) {
          const currDom = doms.contentDocument
          html = currDom.getElementById('kbtable')
            ? currDom.getElementById('kbtable').outerHTML
            : currDom.getElementsByClassName('content_box')[0].outerHTML
          tag = false
        }
      }
      // console.log(ifs.length)
      if (tag) {
        // console.log(ifs.length)
        html = dom.getElementById('kbtable').outerHTML
      }
      result.htmlStr = html
    } catch (e) {
      console.error(e)
      let html = myRequest('get', '/jsxsd/xskb/xskb_list.do', null)
      dom = new DOMParser().parseFromString(html, 'text/html')
      result.htmlStr = dom.getElementById('kbtable')
        ? dom.getElementById('kbtable').outerHTML
        : dom.getElementsByClassName('content_box')[0].outerHTML
    }

  } else {
    console.log("2")
    let html =  myRequest('get',getUrl(document.getElementById('Frame0').contentDocument))
    dom = new DOMParser().parseFromString(html, 'text/html')
    result.htmlStr = dom.getElementsByTagName('table')[0].outerHTML
  }
  return JSON.stringify(result)
}

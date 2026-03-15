/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 18:47:45
 * @LastEditTime: 2022-08-26 21:48:54
 * @LastEditors: xiaoxiao
 * @Description: dom获取
 * @FilePath: \AISchedule\哈尔滨工业大学\本部\provider.js
 * @QQ：357914968
 */
function request(tag, url, data) {
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

function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  let html = ''
  try {
    let doms = dom.getElementsByTagName('iframe')[0].contentDocument
    let table = doms.getElementsByTagName('table')[1]
    console.log(table)
    return table.outerHTML
  } catch (e) {
    console.error(e)
  }
}

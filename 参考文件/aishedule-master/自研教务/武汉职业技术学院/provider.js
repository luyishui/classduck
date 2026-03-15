/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-10-05 14:31:56
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\武汉职业技术学院\provider.js
 * @QQ：357914968
 */
function request(tag, data, url) {
  let ss = ''
  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if ((xhr.readyState == 4 && xhr.status == 200) || xhr.status == 304) {
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
  xhr.send(data)
  return ss
}
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  let ts = `
  >>导入流程<<
  1、登录系统
  2、向左滑选择进首页(没有可以忽略)
  3、点击信息查询
  4、点击我的课表
  5、点击一键导入
  `
  await loadTool('AIScheduleTools')
  await AIScheduleAlert(ts)
  if (location.href.search('M1402') == -1) {
    await AIScheduleAlert(`当前可能不在课表页，请先到达课表页面
    ----------------------
    ${ts}
    ---------------------
    有问题加群 628325112，进行反馈
    `)
    return 'do not continue'
  }
  let ifrs = dom.getElementsByTagName('iframe')

  for (const ifr of ifrs) {
    if (ifr.src.search('queryKbForXsd') !== -1) {
      console.log(ifr.contentDocument)
      dom = ifr.contentDocument
      break
    }
  }

  return dom.getElementsByTagName('table')[0].outerHTML
}

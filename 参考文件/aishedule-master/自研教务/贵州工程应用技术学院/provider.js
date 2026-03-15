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

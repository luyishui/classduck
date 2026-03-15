/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-10-17 21:48:37
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\新正方教务\华中农业大学-本研一体化\provider.js
 * @QQ：357914968
 */

async function request(tag, data, url) {
  return await fetch(url, {
    method: tag,
    body: data,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  })
    .then((rp) => rp.text())
    .then((v) => v)
}
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
    let t = ['loading', 'loading.', 'loading..', 'loading...']
    if (count == 4) count = 0
    content.innerText = t[count++]
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
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  let ts = `
  导入失败，请确保当前位于课表页面!
   `
  //     alert(ts)

  await loadTool('AIScheduleTools')
  let loadd = new AIScheduleLoading()
  loadd.show()
  let htt = null
  let xnm = ''
  let xqm = ''
  let tag = 'json'

  let currentUrl = location.href
  if(currentUrl.search("index_initMenu")!==-1){
    // 在首页
    xqm = document.getElementById("dqxnxq").value;
    let xqxh = xqm.split("-");
    xnm = xqxh[0];
    xqm = xqxh[1];
     htt = JSON.parse(
        await request("post"
            ,"localeKey=zh_CN&xnm="+xnm+"&xqm="+xqm
            , "/kbcx/xskbcx_cxXsKb.html?gnmkdm=index")
    ).kbList
    tag = 'json'
  }else if(currentUrl.search("bjkbdy_cxBjkbdyIndex")!==-1){
    //在推荐课表查询页
    htt = dom.getElementById("ylkbTable").outerHTML
    tag = 'html'
  }else {
    await AIScheduleAlert("暂不支持此课表")
    loadd.close()
    return "do not continue"
  }
  loadd.close()

  console.log(htt)
  return JSON.stringify({ tag:tag,listArr: htt, xqm: xqm, xnm: xnm })
}

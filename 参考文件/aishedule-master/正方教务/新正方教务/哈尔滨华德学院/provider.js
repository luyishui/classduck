/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-09-18 21:04:43
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\新正方教务\山东师范大学\provider.js
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
导入失败，请确保当前位于【个人课表查询】页面!
或加q群：628325112 反馈
----------------------------------
       >>导入流程<<
    >>点击【选课】<<
    >>点击【个人课表查询】<<
     >>点击【一键导入】<<

 `
  //     alert(ts)

  await loadTool('AIScheduleTools')
  let loadd = new AIScheduleLoading()
  loadd.show()
  let htt = null
  let xnm = ''
  let xqm = ''
  let id = ''
  let xqhId = ""

  let url = location.href



  try {
    if(url.search("xskbcxMobile_cxXskbcxIndex")!=-1||url.search("xskbcxMobile_cxTimeTableIndex")!=-1){
      xnm = document.getElementById("xnm_hide").value
      xqm = document.getElementById("xqm_hide").value
  
      htt = JSON.parse( await request("post","xnm="+xnm+"&zs=1&doType=app&xqm="+xqm+"&kblx=2","/jwglxt/kbcx/xskbcxMobile_cxXsgrkb.html?sf_request_type=ajax"))
      console.log(htt)
    }else{
        let forms = dom.getElementById('ajaxForm')
      xnm = forms.xnm.value
      xqm = forms.xqm.value
      htt = JSON.parse(
        await request(
          'post',
          'xnm=' + xnm + '&xqm=' + xqm,
          '/jwglxt/kbcx/xskbcxMobile_cxXsKb.html'
        )
      )
    }

  
    loadd.close()
  } catch (e) {
    try {
      let arr = dom
        .getElementById('cdNav')
        .outerHTML.match(/(?<=clickMenu\().*?(?=\);)/g)
      for (i in arr) {
        if (arr[i].search('个人课表查询') != -1) {
          id = arr[i].split(',')[0].slice(1, -1)
          console.log(id)
          break
        }
      }
      //简写
      //id = arr.find(v=> v.search("学生课表查询") != -1).split(",")[0].slice(1, -1)

      let su = dom.getElementById('sessionUserKey').value
      let html = await request(
        'get',
        null,
        '/jwglxt/kbcx/xskbcxZccx_cxXskbcxIndex.html?gnmkdm=' + id
      )
      dom = new DOMParser().parseFromString(html, 'text/html')
      let form = dom.getElementById('ajaxForm')
      xnm = form.xnm.value
      xqm = form.xqm.value
      htt = JSON.parse(
        await request(
          'post',
          'xnm=' + xnm + '&xqm=' + xqm,
          '/jwglxt/kbcx/xskbcxMobile_cxXsKb.html'
        )
      )
      loadd.close()
    } catch (e) {
      loadd.close()
      await AIScheduleAlert(ts + e)
    }
  }
  console.log(htt)
  return JSON.stringify({ listArr: htt.kbList, xqm: xqm, xnm: xnm })
}

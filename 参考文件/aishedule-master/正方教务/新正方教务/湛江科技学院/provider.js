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
导入失败，请确保当前位于【学生课表查询】页面!
----------------------------------
       >>导入流程<<
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
  let xqh_id = ''
  let tag = 'json'

  let currentUrl = location.href
  try {
    if(currentUrl.search("bjkbdy_cxBjkbdyIndex")!==-1){
      let tableDom = dom.getElementById("ylkbTable");
      if(!tableDom){
        await AIScheduleAlert("请点击课程名称，打开课程表")
        return 'do not continue'
      }

      let form = document.getElementById("ajaxForm")
      xnm = form.xnm.value
      xqm = form.xqm.value
      xqh_id = form.xqh_id.value
      htt =tableDom.outerHTML
      tag = 'html'
    } else if(currentUrl.search("xskbcx_cxXskbcxIndex")!==-1) {
      let forms = dom.getElementById('ajaxForm')
      xnm = forms.xnm.value
      xqm = forms.xqm.value
      htt = JSON.parse(
          await request(
              'post',
              'xnm=' + xnm + '&xqm=' + xqm,
              '/kbcx/xskbcx_cxXsgrkb.html'
          )
      ).kbList
    }else {
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
            '/kbcx/xskbcxZccx_cxXskbcxIndex.html?gnmkdm=' + id
        )
        dom = new DOMParser().parseFromString(html, 'text/html')
        let form = dom.getElementById('ajaxForm')
        xnm = form.xnm.value
        xqm = form.xqm.value
        htt = JSON.parse(
            await request(
                'post',
                'xnm=' + xnm + '&xqm=' + xqm,
                '/kbcx/xskbcx_cxXsgrkb.html'
            )
        ).kbList

    }
  } catch (e) {
    await AIScheduleAlert(ts + e)
    return 'do not continue'
  }finally {
    loadd.close()
  }
  if(tag==='json' && htt.length && htt[0].xqh_id){
    xqh_id = htt[0].xqh_id
  }
  console.log(htt)
  return JSON.stringify({ tag:tag,listArr: htt, xqm: xqm, xnm: xnm ,xqh_id:xqh_id})
}

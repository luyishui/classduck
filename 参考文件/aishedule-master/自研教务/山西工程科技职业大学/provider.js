/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 22:04:08
 * @LastEditTime: 2022-08-11 19:45:40
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\自研教务\山西工程科技职业大学\provider.js
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
    .then((rp) => rp.json())
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
  const OLD_ID = 'iframe123103'
  let kbjson = ''
  try {
    let ifs = document.getElementsByTagName('iframe')
    for (const i of ifs) {
      if (i.style.display !== 'none') {
        if (i.id === OLD_ID) {
          let Zxjxjhh = i.contentDocument.getElementById('Zxjxjhh').value
          kbjson = await request(
            'POST',
            'Zxjxjhh=' + Zxjxjhh,
            '/Tresources/A1Xskb/GetXsKb'
          )
        } else {
          kbjson = await request('POST', null, '/Tresources/A1Xskb/GetXsKb')
        }
      }
    }
  } catch (e) {
    console.error(e)
    try {
      kbjson = await request('POST', null, '/Tresources/A1Xskb/GetXsKb')
      // loadd.close()
    } catch (e) {
      await AIScheduleAlert(e)
    }
  }
  console.log(kbjson.rows)
  return JSON.stringify(kbjson.rows)
}

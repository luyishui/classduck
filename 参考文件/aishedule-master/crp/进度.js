/**
 * @Author: xiaoxiao
 * @Date: 2022-02-15 20:55:02
 * @LastEditTime: 2022-09-01 09:08:46
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\crp\进度.js
 * @QQ：357914968
 */
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //函数名不要动
  // 以下可编辑
  await loadTool('AIScheduleTools')
  // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
  await AIScheduleAlert('这是测试')
  const AIScheduleLoading = ({
    titleText,
    contentText = 'AIScheduleConfirm V1.0.0',
    cancelText = '取消',
    confirmText = '确认',
  } = {}) =>
    new Promise((resolve) => {
      addMeta()
      const title =
        titleText &&
        titleText?.length &&
        titleText?.length <= 10 &&
        createTitle(titleText)
      const content = contentText && createContent(contentText)
      const confirmBtn = createBtn(confirmText, 'primary')
      const cancelBtn = createBtn(cancelText, 'info')
      const card = createCard([title, content, cancelBtn, confirmBtn])
      const mask = createMask(card)
      document.body.appendChild(mask)
      confirmBtn.onclick = () => {
        document.body.removeChild(mask)
        resolve(true)
      }
      cancelBtn.onclick = () => {
        document.body.removeChild(mask)
        resolve(false)
      }
    })
}

//无法与httpxmlrequest共存
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
    content.innerText = contentText + '.'.repeat(count)
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

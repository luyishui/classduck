/**
 * @Author: xiaoxiao
 * @Date: 2022-09-16 20:43:52
 * @LastEditTime: 2022-09-16 21:24:06
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\eurasia\西安欧亚学院\provider.js
 * @QQ: 357914968
 */
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')
  await AIScheduleAlert(`
  >>导入流程<<
  1.点击左上角9个点的logo（可能会被橙色警告窗遮住，请先关闭橙色警告窗）
  2.点击课表
  3.点击学期课表
  4.点击一键导入
  `)
  if (document.URL.search('OuterStudWeekOfTimeTable') === -1) {
    await AIScheduleAlert('请先定位到学期课表')
    return 'do not continue'
  }
  const ifrs = dom.getElementById(
    'ContentPlaceHolder1_ucTimetableInWeeks1_tabTimetableInWeek'
  )

  return ifrs.outerHTML
}

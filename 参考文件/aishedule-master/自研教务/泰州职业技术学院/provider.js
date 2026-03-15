async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {//函数名不要动
    await loadTool('AIScheduleTools')

    if (location.href.search('cx_kb_bjkb_bj') == -1) {
      await AIScheduleAlert('请去班级课表进行导入。。。')
      return 'do not continue'
    } 
    let tables = dom.getElementsByTagName("table")
    let table = tables[tables.length-1]
    
    return table.outerHTML
   }


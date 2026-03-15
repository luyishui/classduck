async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {//函数名不要动
    await loadTool('AIScheduleTools')
     let table =  window.frames['fnode24'].document.getElementById("ContentPanel1_DataGrid1").outerHTML
    console.log(table)
    return table;
   }
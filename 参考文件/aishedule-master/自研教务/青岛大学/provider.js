async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {//函数名不要动
    await loadTool('AIScheduleTools')
    let ifs = window.frames
     let result={}
     if(ifs.length!=0){
       try{
         dom = ifs[0].frames['mainFrame'].document
         result.course = dom.getElementsByClassName("infolist_tab")[0].outerHTML
         result.time = dom.getElementsByClassName("infolist_tab")[1].outerHTML
         result.tag = "LIST"
       }catch(e){
        
         await AIScheduleAlert('遇到错误，可能是未处于课表页面，请在课表页面导入或进群（812150996）联系开发者；错误：'+e)
         return "do not continue"
       }
       
     }else{
       result.tag=tag = location.href.split("=").pop()
       result.course = dom.getElementsByClassName("content_tab")[0].outerHTML
       
       // console.log(dom)
     }
    if(result.tag == "COMBINE"){
     await AIScheduleAlert('当前页面暂未适配，请切换其他课表页面')
     return "do not continue"
     
    }
    // localStorage.setItem("JSON",JSON.stringify(result))
     return JSON.stringify(result);
   }
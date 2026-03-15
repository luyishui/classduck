
let req = async (method,data,url)=>{
return await fetch(url,{method:method,body:data}).then(re=>re.json()).then(v=>v)
}
async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
  //  alert("即将开始导入，导入时长受网络影响，请等待。。。。")
    let resuslt={}
    try{
        let token =location.href.split("=")[1]
        if(!token){
            let scr = dom.getElementsByTagName("script")
            token = scr[scr.length-1].outerHTML.match(/(?<=api_token:').*?(?=')/)[0]
        }
        let xqurl = "http://jwxt.sddfvc.cn/mobile/student/mobile_kcb_xq?api_token="+token       
        let xqdom = dom.getElementsByTagName("select")
        let xqid = !xqdom.length?(await req("get",null,xqurl)).data.xq_current.id:xqdom[0].value
        console.log(xqid)
        let kburl = "http://jwxt.sddfvc.cn/mobile/student/mobile_kcb?api_token="+token+"&xq="+xqid
       resuslt = await req("get",null,kburl)
    }catch(e){
        resuslt.error = e.message
    }

    return JSON.stringify(resuslt)   
}
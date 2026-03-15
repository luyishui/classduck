function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    alert("请处于查询本学期课表状态，导入完成后请去设置调整课程节数和时间")
    let page = dom.getElementsByClassName("page unitBox")
    let str =""
    Array.from(page).forEach(v=>{
        if(v.style.display =="block"){
            str = v.getElementsByTagName("iframe")[0].contentWindow.document.getElementById("form1").outerHTML
        }
    })
    return str

}
function request(tag,url,data)
{
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        console.log(xhr.readyState+" "+xhr.status)
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText
        }

    };
    xhr.open(tag, url,false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    xhr.send(data)
    return ss;
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let htmls = ''
    let fram1 = window.frames["Frame1"]
    if(fram1 != undefined && fram1.location.pathname.search('/jsxsd/xskb/xskb_list.do')!=-1){
        let dom = window.frames["Frame1"].document
        htmls = dom.getElementById('kbtable').outerHTML
        // console.log(htmls)
        console.info(1)
    }
    else{
        let html = request('get','/jsxsd/xskb/xskb_list.do',null)
        let dom = new DOMParser().parseFromString(html, 'text/html')
        // console.info(dom.getElementsByClassName('content_box')[0])
        htmls = dom.getElementById('kbtable').outerHTML
        console.log(htmls)
    }
    return htmls
}
/**
 * @Author: xiaoxiao
 * @Date: 2022-03-02 19:43:41
 * @LastEditTime: 2022-03-02 20:14:34
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\强智教务\iframe强智\武汉信息传播职业技术学院\provider.js
 * @QQ：357914968
 */
function request(tag, url, data) {
    let ss = "";
    let xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status)
        if (xhr.readyState === 4 && xhr.status === 200 || xhr.status ===304) {
            ss = xhr.responseText;
        }
    };
    xhr.open(tag, url, false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.send(data);
    return ss;
}
function AIScheduleLoading({
    titleText='加载中',
    contentText = 'loading...',
}={}
){
    console.log("start......")
    AIScheduleComponents.addMeta()
    const title = AIScheduleComponents.createTitle(titleText)
    const content = AIScheduleComponents.createContent(contentText)
    const card = AIScheduleComponents.createCard([title, content])
    const mask = AIScheduleComponents.createMask(card)
    
    let dyn 
    let count = 0
    function dynLoading(){
        let t = ['loading','loading.','loading..','loading...']
        if(count==4) count=0
        content.innerText = t[count++]
    }

    this.show=()=>{ 
        console.log("show......")
        document.body.appendChild(mask)
        dyn = setInterval(dynLoading,1000);
    }
    this.close=()=>{
        document.body.removeChild(mask)
        clearInterval(dyn)
    }
    }
async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    await loadTool("AIScheduleTools")
    let load = new AIScheduleLoading()
    load.show()
    let html = '';
    try {
        if (window.frames["Frame1"].document) {
            let dom = window.frames["Frame1"].document;
            html = dom.getElementById('kbtable') ? dom.getElementById('kbtable').outerHTML : dom.getElementsByClassName('content_box')[0].outerHTML;
        } else {
            html = dom.getElementById('kbtable').outerHTML;
        }
        return html;
    } catch (e) {
        let html = request("get", "/xskb/xskb_list.do", null);
        dom = new DOMParser().parseFromString(html, "text/html");
        return dom.getElementById("kbtable") ? dom.getElementById("kbtable").outerHTML : dom.getElementsByClassName('content_box')[0].outerHTML;
    }
}
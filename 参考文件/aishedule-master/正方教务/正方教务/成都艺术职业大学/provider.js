/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-03-14 14:57:00
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\正方教务\成都艺术职业大学\provider.js
 * @QQ：357914968
 */
function request(tag,data,url)
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
    let htmlDom = window.frames["zhuti"].document
    let kbUrl = "xskbcx.aspx"+dom.getElementById("navxl").outerHTML.match(/(?<=xskbcx\.aspx).*?(?=")/)[0].replace(/&amp;/g,"&")

    try{
        if(!htmlDom.getElementById("Table1")){
            let kbHTMLText = request("get",null,kbUrl)
            htmlDom = new DOMParser().parseFromString(kbHTMLText,"text/html")
        }
    }catch{
     let kbHTMLText = request("get",null,kbUrl)
     htmlDom = new DOMParser().parseFromString(kbHTMLText,"text/html")
    }
  
   // let data = "xnd=2021-2022&xqd=2"
  
    let table = htmlDom.getElementById("Table1");
    console.log(table)
    return table.outerHTML
}
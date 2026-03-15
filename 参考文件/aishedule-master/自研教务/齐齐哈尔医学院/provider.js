/**
 * @Author: xiaoxiao
 * @Date: 2022-03-14 15:04:44
 * @LastEditTime: 2022-03-14 15:06:44
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\自研教务\齐齐哈尔医学院\provider.js
 * @QQ：357914968
 */
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
                                
 dom = window.frames["rightFrame"].document
 let tables = dom.getElementsByTagName("table")
return tables[tables.length-1].outerHTML;
}
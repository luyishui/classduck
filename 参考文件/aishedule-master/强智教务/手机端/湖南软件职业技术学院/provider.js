/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:50
 * @LastEditTime: 2022-03-08 14:08:43
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\强智教务\手机端\湖南软件职业技术学院\provider.js
 * @QQ：357914968
 */
function request(tag, data, url,token) {
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, false);
    //xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.setRequestHeader("token", token);
    xhr.send(data);
    return ss;
}



function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    
    

    let baseUrl = "http://222.243.161.213:81/hnrjzyxyhd"
    let token = sessionStorage.getItem('Token')

    let kbjcmsid = request("post",null,baseUrl+"/Get_sjkbms",token)
    kbjcmsid = JSON.parse(kbjcmsid).data[0].kbjcmsid
    console.log(kbjcmsid)

    let teachingWeek = request("post",null,baseUrl+"/teachingWeek",token)
    teachingWeek = JSON.parse(teachingWeek).data
    console.log(teachingWeek)

    let courses=new Set()
    teachingWeek.forEach(week=>{
        let data = request("post",null,baseUrl+"/student/curriculum?week="+week.week+"&kbjcmsid="+kbjcmsid,token)
        data = JSON.parse(data).data[0].item
        data.forEach(v=>{
            courses.add(JSON.stringify(v))
        })
    })
    return "["+Array.from(courses).toString()+"]"

}
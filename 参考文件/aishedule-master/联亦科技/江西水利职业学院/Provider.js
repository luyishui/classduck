function request(tag,url,data){
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        console.log(xhr.readyState+" "+xhr.status)
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText
        }

    };
    xhr.open(tag, url,false);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
    xhr.send(data)
    return ss;
}

function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改


    let id = dom.getElementsByTagName("body")[0].outerText.replace(/\n|\s/g, "").match(/(?<=学号:).*?(?=姓名)/)
    if (id) {
        let currentUrl = "api/baseInfo/semester/selectCurrentXnXq"
        let timeTag = parseInt(+new Date() / 1000)
        let xqJsonText = request("get", currentUrl + "?_t=" + timeTag, null)
        let semester = JSON.parse(xqJsonText).data.semester

        let data = {
            "semester": semester,
            "weeks": [...new Array(31).keys()].slice(1),
            "studentId": id[0],
            "source": "xs",
            "oddOrDouble": 1,
            "startWeek": "1",
            "stopWeek": "30"
        }
        console.log(data)
        let kcText = request("post", "/api/arrange/CourseScheduleAllQuery/studentCourseSchedule" + "?_t=" + timeTag, JSON.stringify(data))
        return JSON.stringify({html: kcText, tag: "json"})

    } else {
        let divs = dom.getElementsByClassName("ant-spin-container")[0];
        divs = divs.getElementsByTagName("table")[0]
        return JSON.stringify({html: divs.outerHTML, tag: "html"})
    }
}

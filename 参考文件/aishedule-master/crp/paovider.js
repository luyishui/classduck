function requestkc(data) {
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status)
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) { // readyState == 4说明请求已完成
            //     fn.call(xhr.responseText)  //从服务器获得数据
            ss = xhr.responseText
        }

    };
    xhr.open("POST", "http://218.200.73.44/st/student/st_p.aspx", false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    xhr.send(data)
    return ss;
}

function getJieci(jcStr) {
    let rejc = [];
    let jc = jcStr.split(",")[1].replace(/第|节/g, "").split('-').filter(function (s) { return s && s.trim(); });
    for (let y = Number(jc[0]); y <= jc[jc.length - 1]; y++) {
        rejc.push(y);
    }
    return rejc;
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    console.log("begin")
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let form = dom.getElementById("form1")
    let view = encodeURIComponent(form['__VIEWSTATE'].value)
    let event = encodeURIComponent(form['__EVENTVALIDATION'].value)
    let xn = encodeURIComponent(form['cbo_学年学期'].value)
    data = "__EVENTTARGET=LinkButton_%E4%B8%8B%E4%B8%80%E5%91%A8&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=" + view + "&__EVENTVALIDATION=" + event + "&cbo_%E5%AD%A6%E5%B9%B4%E5%AD%A6%E6%9C%9F=" + xn
    let htmstr = requestkc(data)
    let result = []
    let zs = prompt("求输入本学期有总共有多少周？(默认22)", "22")
    if (zs == null) zs = 22
    let tag = confirm("即将进行导入...\n请确保当页面为第0周！！\n不是请改正！！\n此过程大概需要30秒\n导入时会出现假死，不要进行任何操作\n请耐心等待，导入完成后将会自动跳转...\n完成后，请去设置调整课表节数和时间\n点击确定开始进行导入")
    if (tag) {
        for (let i = 0; i < zs; i++) {
            console.log("正在获取第" + (i + 1) + "周")
            let formDom = new DOMParser().parseFromString(htmstr, "text/html")

            let trs = formDom.getElementsByTagName("table")[2].getElementsByTagName("tr")
            let form = formDom.getElementById("form1")

            for (j = 1; j <= 5; j++) {
                let tds = trs[j].getElementsByTagName("td")
                for (k = 1; k <= 7; k++) {
                    kcsText = tds[k].getElementsByTagName("span")[0].innerHTML.replace(/\s/g, "").split(/<br><br>/).slice(0, -1)
                    kcsText.forEach(v => {
                        kcarr = v.split("<br>")
                        let re = { weeks: [], sections: [] };
                       
                        kcarr.forEach(con => {
                            let cons = con.split("：") 
                            console.log(cons)
                            switch (cons[0]) {
                                case "时间":
                                    if (j != 5) {
                                        re.sections = getJieci(cons[1])
                                    }
                                    else {
                                        re.sections = getJieci(",第1-10节")
                                    }
                                    break;
                                case "课程名称": re.name = cons[1]; break
                                case "任课老师": re.teacher = cons[1].replace(/老师/g, ""); break
                                case "课室": re.position = cons[1].split("(")[0]; break
                            }
                        })
                        re.weeks.push(i + 1)
                        re.day = k
                        console.log(re)
                        result.push(re)
                    }
               )

            }
        }
            view = encodeURIComponent(form['__VIEWSTATE'].value)
            event = encodeURIComponent(form['__EVENTVALIDATION'].value)
            data = "__EVENTTARGET=LinkButton_%E4%B8%8B%E4%B8%80%E5%91%A8&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=" + view + "&__EVENTVALIDATION=" + event + "&cbo_%E5%AD%A6%E5%B9%B4%E5%AD%A6%E6%9C%9F=" + xn
            htmstr = requestkc(data)
        }
        console.log(result)
        return JSON.stringify(result);
    }

}
function parsetodom(str,dom){
    var div = dom.createElement("div");
    if(typeof str == "string")
        div.innerHTML = str;
    return div;
}

function req(tag,url,data = null)
{
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function()
    {
        console.log(xhr.readyState+" "+xhr.status)
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304)
        {
            ss = xhr.responseText
        }

    };
    xhr.open(tag, url,false);
    xhr.setRequestHeader("Content-Type","application/x-www-form-urlencoded; charset=UTF-8")
    xhr.send(data)
    return ss;
}

function getWeeks(weekStr){
    // 第1-3周,5-9周,11-15周
    // 第6-7周,10-18周
    //第7-9(单周),10-18周

    weekss =  weekStr.replace(/第|\(|\)/g,"")
    let week1 = []
    while(weekss.search(/周/) != -1)
    {
        zindex= weekss.search(/周/)
        week1.push(weekss.slice(0,zindex+1).replace("周",""));
        if(weekss[zindex+1] == undefined)
        {
            weekss = "";
        }
        else
        {
            weekss = weekss.slice(zindex+2);
            weekss = weekss.slice(weekss.search(/\d/));
        }
    }
    week1.push(weekss)
    let reweek = [];
    week1.filter(function (s) {return s && s.trim();}).forEach(v =>{

        if(v.substring(v.length-1)== "双")
        {
            v.substring(0,v.length-1).split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1]  && z<=20; z++)
                {
                    if(z%2==0)
                    {
                        reweek.push(z)
                    }
                }
            })
        }
        else if(v.substring(v.length-1)== "单")
        {
            v.substring(0,v.length-1).split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] && z<=20; z++)
                {
                    if(z%2!=0)
                    {
                        reweek.push(z)
                    };
                }
            })
        }
        else{
            v.split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1]  && z<=20; z++)
                {
                    reweek.push(z);
                }
            })
        }
    });
    return reweek;
}
function getWeek(week){
    console.log(week)
    switch(week){
        case 'mon' : return 1;
        case 'tue' : return 2;
        case 'wed' : return 3;
        case 'thu' : return 4;
        case 'fri' : return 5;
        case 'sat' : return 6;
        case 'sun' : return 7;
    }

}
function getJieci(be,end){
    let rejc = [];

    for(let y =  Number(be);y<=end;y++){
        rejc.push({section:y});
    }
    return rejc;
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    alert("点击确定后开始导入\n导入完成后，请去设置更改课表节数和时间\n导入完成后将会自动跳转，请等待....")
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    //更新周数限制最大20
    //更新时间函数
    let kbHtmlurl = "/jedu/edu/core/eduStudent/scheduleAll.do"
    let kburl = "/jedu/edu/core/eduScheduleInfo/getScheduleNew.do"
    let scheduleAllHtml = req("get",kbHtmlurl)
    let stuId = scheduleAllHtml.match(/(stuId\s=\s")(\d+)(";)/)[2]
    let semid = dom.getElementById('semId$value').value
    let data = "semId="+semid+"&stuId="+stuId+"&checkType=student"
    let kcjson = req("post",kburl,data)
    console.log(semid +" "+stuId)
    let result = []
    kcjson = JSON.parse(kcjson)
    kcjson.data.schedule.forEach(content =>{
        let re = { sections: [], weeks: [] }
        re.name = content.courseName
        re.teacher = content.teacherName
        re.position = content.eduPlace.placeName
        re.day = getWeek(content.week)
        re.weeks = getWeeks(content.weekList)
        re.sections = getJieci(content.eduLesson.startLesson,content.eduLesson.endLesson)
        result.push(re)
    })
    return JSON.stringify(result);
}
// Source: 参考文件/aishedule-master/AIC智能校园/武汉警官职业学院/Provider.js

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

// Merged parser.js

function getTimes(xJConf,dJConf){
    //xJConf : 夏季时间配置文件
    //dJConf : 冬季时间配置文件
    //return : Array[{},{}]
    dJConf = dJConf ===undefined ? xJConf : dJConf;
    function getTime(conf){
        let courseSum = conf.courseSum;  //课程节数 : 12
        let startTime  = conf.startTime; //上课时间 :800
        let oneCourseTime = conf.oneCourseTime;  //一节课的时间
        let shortRestingTime = conf.shortRestingTime;  //小班空

        let longRestingTimeBegin=conf.longRestingTimeBegin; //大班空开始位置
        let longRestingTime  = conf.longRestingTime;   //大班空
        let lunchTime  = conf.lunchTime;     //午休时间
        let dinnerTime = conf.dinnerTime;    //下午休息
        let abnormalClassTime = conf.abnormalClassTime;      //其他课程时间长度
        let abnormalRestingTime = conf.abnormalRestingTime;    //其他休息时间

        let result = [];
        let studyOrRestTag = true;
        let timeSum = startTime.slice(-2)*1+startTime.slice(0,-2)*60;

        let classTimeMap = new Map();
        let RestingTimeMap = new Map();
        if(abnormalClassTime !== undefined) abnormalClassTime.forEach(time=>{classTimeMap.set(time.begin,time.time)});
        if(longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time=>RestingTimeMap.set(time,longRestingTime));
        if(lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin,lunchTime.time);
        if(dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin,dinnerTime.time);
        if(abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => {RestingTimeMap.set(time.begin,time.time)});

        for(let i = 1, j=1; i<=courseSum*2; i++){
            if(studyOrRestTag){
                let startTime = ("0"+Math.floor(timeSum/60)).slice(-2)+':'+('0'+timeSum%60).slice(-2);
                timeSum+=classTimeMap.get(j)===undefined?oneCourseTime:classTimeMap.get(j);
                let endTime = ("0"+Math.floor(timeSum/60)).slice(-2)+':'+('0'+timeSum%60).slice(-2);
                studyOrRestTag=false;
                result.push({
                    section:j++,
                    startTime:startTime,
                    endTime:endTime
                })
            }
            else {
                timeSum += RestingTimeMap.get(j-1) === undefined?shortRestingTime:RestingTimeMap.get(j-1);
                studyOrRestTag = true;
            }
        }
        return result;
    }

    let nowDate = new Date();
    let year = nowDate.getFullYear();                       //2020
    let wuYi = new Date(year+"/"+'05/01');           //2020/05/01
    let jiuSanLing = new Date(year+"/"+'09/30');     //2020/09/30
    let shiYi = new Date(year+"/"+'10/01');          //2020/10/01
    let nextSiSanLing = new Date((year+1)+"/"+'04/30');    //2021/04/30
    let previousShiYi = new Date((year-1)+"/"+'10/01');     //2019/10/01
    let siSanLing = new Date(year+"/"+'04/30');         //2020/04/30
    let xJTimes = getTime(xJConf);
    let dJTimes = getTime(dJConf);
    console.log("夏季时间:\n",xJTimes)
    console.log("冬季时间:\n",dJTimes)
    if(nowDate >= wuYi && nowDate <= jiuSanLing){
        return xJTimes;
    }
    else if(nowDate >= shiYi && nowDate <= nextSiSanLing || nowDate >= previousShiYi && nowDate <= siSanLing){
        return dJTimes;
    }
}

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9


    console.log(eval(html))
    return { courseInfos: eval(html),sectionTimes:
            getTimes({
                courseSum : 10,     //课程节数 : int :必选
                startTime : '820', //第一节上课时间 : String : 必选 : 例："8:00"=>'800',"10:30"=>'1030'
                oneCourseTime : 45, //一节课时间,单位：min : int : 必选
                shortRestingTime : 10, //小班空, 单位：min : int : 必选
                longRestingTime : 20, //大班空， 单位：min : int : 可选
                longRestingTimeBegin : [2],//大班空的开始节数 : Array[int] : 可选
                lunchTime  : {begin:4,time:120}, //午休时间:{begin:Number//开始的节数,time:number//时长}:单位：min:可选
                dinnerTime : {begin:8,time:90},   //晚餐时间 :{begin:Number//开始的节数,time:number//时长}:单位：min:可选
                //    abnormalClassTime : [{begin:11,time:120}],    //其他的课程时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
                //    abnormalRestingTime : [{begin:6,time:15},{begin:10,time:0}]   //其他休息时间时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
            })}
}

// Source: 参考文件/aishedule-master/联亦科技/江西水利职业学院/Provider.js

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


// function changeNum(Str){
//   switch(Str){
//     case '1': return 1;break;
//     case '2': return 2;break;
//     case '3': return 3;break;
//     case '4': return 4;break;
//     case '课外一':return '5,6';break;
//     case '5':return 7;break;
//     case '6':return 8;break;
//     case '7':return 9;break;
//     case '8':return 10;break;
//     case '课外二':return '11,12';break;
//     case '晚上' : return '13,14';break;


//   }
// }
function getSection(Str){
    Str = Str.replace(/第|节|\(|\)/g,"").split(",")
    let re = []
    Str.forEach(v=>{
        re.push({section : Number(v)})
//       if(v != null && v.search(/课外一|课外二|晚上/)!=-1){
//         changeNum(v).split(",").forEach(vv=>{
//            re.push({section : Number(vv)})
//         })
//      }
//      else{
//         re.push({section:changeNum(v)})
//      }
    })
    return re
}
function getWeeks(Str) {
    function range(con, tag) {
        let retWeek=[]
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag == 1 || tag == 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag==0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 != 0    }))
        })
        return retWeek
    }
    Str = Str.replace(/\(|\)|\{|\}|\||第/g, "").replace(/到/g, "-")
    let reWeek = [];
    let week1 = []
    while (Str.search(/周/) != -1) {
        let index = Str.search(/周/)
        if (Str[index + 1] == '单' || Str[index + 1] == '双') {
            week1.push(Str.slice(0, index + 2).replace("周", ""));
            index += 2
        } else {
            week1.push(Str.slice(0, index + 1).replace("周", ""));
            index += 1
        }

        Str = Str.slice(index)
        index = Str.search(/\d/)
        if (index != -1) Str = Str.slice(index)
        else Str = ""

    }
    if (Str.length != 0) week1.push(Str)

    week1.forEach(v => {
        console.log(v)
        if (v.slice(-1) == "双") reWeek.push(...range(v, 2))
        else if (v.slice(-1) == "单") reWeek.push(...range(v, 3))
        else reWeek.push(...range(v+"全", 1))
    });
    return reWeek;
}


function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
    let result = []
    let kcData = JSON.parse(html)
    if(kcData.tag == "html"){
        let $ = cheerio.load(kcData.html,{decodeEntities: false})
        let trs = $('tr')
        trs.each(function(index,em){
            let tds = $(this).find('td')
            tds.each(function(index1,em1){
                if(index1>0){
                    let divs = $(this).find('div')
                    divs.each(function(index2,em2){
                        let re = {weeks:[],sections:[]}
                        re.day = index1
                        let sigledivd = $(this).find('div')
                        sigledivd.each(function(index3,em3){
                            if(index3==0){
                                re.name = $(this).text().replace(/\s/g,"")
                            }
                            else{
                                let tagtxt = $(this).find('img').attr('alt')
                                switch(tagtxt){
                                    case '地点': re.position = $(this).text().replace(/\(\d{5,}?\)/g,"");break;
                                    case '教师': re.teacher = $(this).text();break;
                                    case '时间': let sj_zc = $(this).find('span')
                                        sj_zc.each(function(index4,em4){
                                            if(index4 == 0){
                                                re.weeks = getWeeks($(this).text().replace(/\s/g,""))

                                            }
                                            else if(index4 == 1){
                                                re.sections = getSection($(this).text().replace(/\s/g,""))
                                            }
                                        })
                                        break;
                                }
                            }
                        })
                        if(!re.name) return
                        result.push(re)
                    })
                }
            })
        })
    }
    else if(kcData.tag == "json"){
        let kcJson = JSON.parse(kcData.html).data
        kcJson.forEach(con=>{
            con.courseList.forEach(kc=>{
                let re = {weeks:[],sections:[]}
                re.name = kc.courseName;
                re.teacher = kc.teacherName;
                re.position = kc.classroomName;
                re.weeks=getWeeks(kc.weeks);
                re.day = kc.dayOfWeek-1==0?7:kc.dayOfWeek-1;
                re.sections = getSection(kc.time);
                result.push(re)
            })


        })
    }

    let dJConf={
        courseSum: 10,
        startTime: '820',
        oneCourseTime: 45,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2,6],
        lunchTime: {begin: 4, time: 2 * 60},
        dinnerTime: {begin: 8, time: 60+20},
        abnormalClassTime:[{begin:10,time:65}],
    }
    console.log(result)
    return { courseInfos: result,
        sectionTimes: getTimes(dJConf) }
}

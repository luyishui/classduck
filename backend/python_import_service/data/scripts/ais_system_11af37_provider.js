// Source: 参考文件/aishedule-master/正方教务/新正方教务/太原科技大学/Provider.js

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
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let ts =
        `
           >>导入流程<<
        >>点击【新教务系统】<<
        >>选择【信息查询】<<
       >>点击【学生课表查询】<<
        >>点击【一键导入】<<
        
    >>提示:校外使用可能需要挂vpn<<
`
    alert(ts)

    let dJConf ={
        courseSum : 10,
        startTime  : '800',
        oneCourseTime : 50,
        longRestingTime  : 20,
        shortRestingTime : 10,
        longRestingTimeBegin:[2],
        lunchTime  : {begin:4,time:2*60+10},
        dinnerTime : {begin:8,time:70},
        //abnormalClassTime:[],
        //abnormalRestingTime:[]
    };
    let xJConf =  {
        courseSum : 10,
        startTime  : '800',
        oneCourseTime : 50,
        longRestingTime  : 20,
        shortRestingTime : 10,
        longRestingTimeBegin:[2],
        lunchTime  : {begin:4,time:2*60+40},
        dinnerTime : {begin:8,time:70},
        //abnormalClassTime:[],
        //abnormalRestingTime:[]
    }
    let htt = dom.getElementById("ylkbTable").outerHTML
    return JSON.stringify({html:htt,sj:getTimes(xJConf,dJConf)})

}

// Merged parser.js

function getWeeks(Str){
    Str = Str.replace(/\(|\)/g,"")
    let week1 = []
    while(Str.search(/周/) != -1){
        let index = Str.search(/周/)
        if(Str[index+1]=='单'||Str[index+1]=='双'){
            week1.push(Str.slice(0,index+2).replace("周",""));
            if(Str[index+1] == undefined){
                Str = "";
            }
            else{
                Str = Str.slice(index+2)
                Str = Str.slice(Str.search(/\d/))
            }
        }
        else{
            week1.push(Str.slice(0,index+1).replace("周",""));
            if(Str[index+1] == undefined){
                Str = "";
            }
            else{
                Str = Str.slice(index+1)
                Str = Str.slice(Str.search(/\d/))
            }
        }
    }
    week1.push(Str)
    let reweek = [];
    week1.filter(function (s) {return s && s.trim();}).forEach(v =>{

        if(v.substring(v.length-1)== "双"){
            v.substring(0,v.length-1).split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                    if(z%2==0){reweek.push(z)};
                }
            })
        }
        else if(v.substring(v.length-1)== "单"){
            v.substring(0,v.length-1).split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                    if(z%2!=0){reweek.push(z)};
                }
            })
        }
        else{
            v.split(',').forEach(w =>{
                let tt = w.split('-').filter(function (s) {return s && s.trim();});
                for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                    reweek.push(z);
                }
            })
        }
    });
    return reweek;
}
function getSections(Str){
    Str = Str.replace(/节/g,"").split(",")
    let res = []
    Str.forEach(ss=>{
        let arr = ss.split("-")
        for(let i = Number(arr[0]);i<=arr[arr.length-1];i++){
            res.push({section:i})
        }
    })
    console.log(Str,res)
    return res
}
function cutOutStringByteLength(str,long) {
    let seeString = [];
    let countByteLength = 0;
    for(let i=0;i<str.length;i++){
        let charCode = str.charCodeAt(i);
        if (charCode >= 0 && charCode <= 128){
            countByteLength += 1;
        }else{
            countByteLength += 2;
        }
        if (countByteLength <= long){
            seeString.push(str[i]);
        }else {
            break;
        }
    }
    return seeString.join("");
}
function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改

    let jss = JSON.parse(html)
    let result = []
    let $ = cheerio.load(jss.html,{decodeEntities: false})
    let bbb = $('div[class = "tab-pane fade active in"]')
    if(bbb.attr('id') == 'table1' ){
        let trs = bbb.find('table tbody tr')
        trs.each(function(index,em){
            if(index>=2){ //跳过表头
                $(this).find('.td_wrap').each(function(__,em1){
                    let weekday=$(this).attr('id').slice(0,1)
                    $(this).find('div').each(function(index2,em2){
                        let re = {weeks:[],sections:[]}
                        re.day = Number(weekday);
                        re.name = $(this).find('span[class="title"]').length != 0?$(this).find('span[class="title"]').text() : $(this).find('u').text()//处理调课
                        // re.name = re.name.slice(0,-1)
                        re.name = cutOutStringByteLength(re.name,50)
                        $(this).children('p').each(function(inn,em){
                            let text = $(this).find('span').attr('title')
                            switch(text){
                                case '节/周':
                                    let tt = $(this).text();
                                    re.sections = getSections(tt.match(/(?<=\().*?(?=\))/)[0])
                                    re.weeks = getWeeks(tt.match(/(?<=节\)).*?$/)[0])
                                    console.log($(this).text());
                                    break;
                                case '上课地点': re.position = $(this).text().replace(/晋城校区|主校区|南校区|南社校区/g,"").trim();
                                    re.position = cutOutStringByteLength(re.position,50);
                                    break;
                                case '教师': re.teacher = $(this).text().replace(/\(.*?\)/g,"").trim();
                                    re.teacher = cutOutStringByteLength(re.teacher,50);
                                    break;
                            }
                        })
//                         if(re.weeks.length == 0||re.sections.length == 0){
//                             return
//                         }
                        result.push(re)
                    })
                })
            }
        })
    }
    if(bbb.attr('id') == 'table2' ){
        let tbs = bbb.find('table tbody')
        tbs.each(function(index,em){
            if($(this).attr('id')!=undefined){  //跳过表头
                let re = {weeks:[],sections:[]}
                re.day = Number($(this).attr('id').replace('xq_',""))
                let tag = true
                $(this).children('tr').each(function(index1,em1){
                    re.weeks = []
                    if(index1>0){   //跳过星期列
                        let tds = $(this).find('td')
                        let sp_tr = null;
                        if(tds.length ==2) {
                            re.sections = getSections(tds.eq(0).text())
                            sp_tr = tds.eq(1).find('div')
                        }else {
                            sp_tr = tds.eq(0).find('div')
                        }
                        re.name = $(this).find('span[class="title"]').length != 0?$(this).find('span[class="title"]').text() : $(this).find('u').text()
                        //  re.name = re.name.slice(0,-1)
                        re.name = cutOutStringByteLength(re.name,50)
                        sp_tr.find('p font').each(function(index2,em2){
                            switch($(this).find('span').last().attr('class')){
                                case 'glyphicon glyphicon-calendar': re.weeks = getWeeks($(this).text().replace("周数：","").trim());break;
                                case 'glyphicon glyphicon-map-marker':re.position=$(this).text().replace(/校区：|校本部|晋城校区|主校区|南校区|南社校区|上课地点：/g,"").trim();
                                    re.position = cutOutStringByteLength(re.position,50)
                                    break;
                                case 'glyphicon glyphicon-user':re.teacher = $(this).text().replace(/教师：|\(.*?\)/g,"").trim();
                                    re.teacher = cutOutStringByteLength(re.teacher,50);
                                    break;
                            }
                        })
                        tag = false
                        console.log(re)
                    }
                    if(tag) return;
                    result.push(JSON.parse(JSON.stringify(re)))
                })
            }
        })
    }


    console.info(result)
    return { courseInfos: result,sectionTimes:jss.sj }
}

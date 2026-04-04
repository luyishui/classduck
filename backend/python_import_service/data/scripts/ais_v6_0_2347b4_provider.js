// Source: 参考文件/aishedule-master/教务管理系统V6.0/长春师范大学/Provider.js

function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    alert("请处于查询本学期课表状态，导入完成后请去设置调整课程节数和时间")
    let page = dom.getElementsByClassName("page unitBox")
    let str =""
    Array.from(page).forEach(v=>{
        if(v.style.display =="block"){
            str = v.getElementsByTagName("iframe")[0].contentWindow.document.getElementById("form1").outerHTML
        }
    })
    return str

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

function pd(or,inn){
    //   console.log(or,inn)
    if(or.length == inn.length){
        if(or.sort().toString()==inn.sort().toString()){
            return true
        }
        else{
            return false
        }
    }
    else return false;
}
function getweeks(Str){
    Str = Str.replace(/(?<=周),(?=单)|(?<=周),(?=双)/g,"")

//    console.log(1+" "+Str)
    weekss =  Str.replace(/第|\(|\)/g,"");
//    console.log(2+weekss)
    let week1 = [];
    while(weekss.search(/双|单/) != -1){
        let zindex = weekss.search(/双|单/);
        let z_12 = weekss.slice(zindex,zindex+1);
        if(z_12 =='双' || z_12=='单' ){
            week1.push(weekss.slice(0,zindex+1));
            if(weekss[zindex+2] == undefined){
                weekss = "";
            }
            else {
                weekss = weekss.slice(zindex+1);
                weekss = weekss.slice(weekss.search(/\d/));
            }
        }
    }
    week1.push(weekss);
    let reweek = [];
    week1.filter(function (s) {return s && s.trim();}).forEach(v =>{
        //          console.log(3+v)
        v = v.replace("周","")
        if(v.length > 0){
            if(v.substring(v.length-1)== "双"){
                v.substring(0,v.length-1).split(',').forEach(w =>{
                    let tt = w.split('-').filter(function (s) {return s && s.trim();});
                    for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                        if(z%2==0){reweek.push(z);}
                    }
                })
            }
            else if(v.substring(v.length-1)== "单"){
                v.substring(0,v.length-1).split(',').forEach(w =>{
                    let tt = w.split('-').filter(function (s) {return s && s.trim();});
                    for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                        if(z%2!=0){reweek.push(z);}
                    }
                })
            }
            else{
                v.split(',').forEach(w =>{
                    //  console.log(w)
                    let tt = w.split('-').filter(function (s) {return s && s.trim();});
                    //  console.log(Number(tt[0]) <= tt[tt.length-1])
                    for(let z =  Number(tt[0]) ; z <= tt[tt.length-1] ; z++){
                        reweek.push(z);
                    }
                })
            }
        }

    });
    return reweek;
}

function getjc(Str){
    let jc=[];
    let jcar = Str.split("-")
    for(i=Number(jcar[0]);i<=jcar[jcar.length-1];i++){
        jc.push({section:i})
    }
    return jc
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
    let $ = cheerio.load(html,{decodeEntities: false})
    let sc = $('script[type="text/javascript"]')
    let result= []
    let morear= new Map()
    sc.each(function(index,em){
        let ss = $(this).html().match(/(?<=setContentArray\().*?\d(?=\))/)
        if(ss != null) {
            console.info(ss)
            let ar = []
            let id = ss[0].split("'")[2].slice(1)
            let con = ss[0].split("'")[1]
            if(morear.has(id)){
                ar= morear.get(id)
                ar.push(con)
                morear.set(id,ar)
            }
            else{
                ar.push(con)
                morear.set(id,ar)
            }
        }


    })

    let tr = $("tbody","#TableLCRoomOccupy").find("tr")
    tr.each(function(index,em){
        let cell= $(this).find(".PuTongCell")
        let xq = 0
        cell.each(function(ind,emm){
            xq++
            let nr = $(this).html().split("<br>")
            if(nr.length!=1&&nr[1].search("网上") == -1 ){
                let re = {weeks:[],sections:[]}
                re.name = nr[0].match(/(?<=\>).*?(?=\<)/).toString()
                re.teacher  =nr[1].match(/(?<=\>).*?(?=\<)/g).toString()
                re.position  =nr[2]
                re.sections=getjc(nr[3].match(/(?<=\[).*?(?=\])/g).toString().replace("节",""))
                re.weeks = getweeks(nr[3].split("[")[0])
                re.day = xq
                result.push(JSON.parse(JSON.stringify(re)))
                if(nr[5] != undefined){
                    id = nr[5].match(/(?<=showMoreInfomation\(').*?(?='\))/).toString()
                    console.info(id)
                    morear.get(id).forEach(cc =>{

                        let morecon = cc.split("^")
                        if(morecon[1].search("网上") == -1 ){
                            console.log(morecon)
                            re.name = morecon[0]
                            re.teacher = morecon[1]
                            re.position = morecon[2]
                            re.weeks = getweeks(morecon[4].match(/(?<=\[).*?(?=\])/g)[0])
                            re.sections = getjc(morecon[4].match(/(?<=\[).*?(?=\])/g)[1].replace("节",""))
                            re.day = xq
                            result.push(JSON.parse(JSON.stringify(re)))
                        }
                    })
                }
            }
        })
    })
    let data = result;
    for(let i = 0 ;i<data.length;i++){
        data[i].name = cutOutStringByteLength(data[i].name,40)
        data[i].teacher = cutOutStringByteLength(data[i].teacher,40)
        data[i].position = cutOutStringByteLength(data[i].position,40).replace(/\[.*?\]/,"")
        for(let j = i+ 1 ;j<data.length;j++){
            if(data[j]!= undefined && data[i] != undefined){
                if(data[i].name == data[j].name){
                    if(data[i].day == data[j].day){
                        if(pd(data[i].weeks,data[j].weeks)){
                            if(data[i].teacher == data[j].teacher){
                                if(data[i].position == data[j].position){
                                    data[j].sections.forEach(vvv=>{
                                        data[i].sections.push(vvv)
                                    })
                                }
                            }
                        }
                    }
                }
            }

        }
    }
    data =data.filter(function (s) { return s && s != undefined});

    let xJConf ={
        courseSum : 11,     //课程节数 : int :必选
        startTime : '800', //第一节上课时间 : String : 必选 : 例："8:00"=>'800',"10:30"=>'1030'
        oneCourseTime : 45, //一节课时间,单位：min : int : 必选
        shortRestingTime : 5, //小班空, 单位：min : int : 必选
        longRestingTime : 20, //大班空， 单位：min : int : 可选
        longRestingTimeBegin : [2],//大班空的开始节数 : Array[int] : 可选
        lunchTime  : {begin:4,time:60+50}, //午休时间:{begin:Number//开始的节数,time:number//时长}:单位：min:可选
        dinnerTime : {begin:8,time:40},   //晚餐时间 :{begin:Number//开始的节数,time:number//时长}:单位：min:可选
        abnormalClassTime : [{begin:11,time:120}],    //其他的课程时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
        abnormalRestingTime : [{begin:6,time:15},{begin:10,time:0}]   //其他休息时间时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
    };
    let dJConf = {
        courseSum : 11,     //课程节数 : int :必选
        startTime : '800', //第一节上课时间 : String : 必选
        oneCourseTime : 45, //一节课时间,单位：min : int : 必选
        shortRestingTime : 5, //小班空, 单位：min : int : 必选
        longRestingTime : 20, //大班空， 单位：min : int : 可选
        longRestingTimeBegin : [2],//大班空的开始节数 : Array[int] : 可选
        lunchTime  : {begin:4,time:60+20}, //午休时间:{begin:Number//开始的节数,time:number//时长}:单位：min:可选
        dinnerTime : {begin:8,time:40},   //晚餐时间 :{begin:Number//开始的节数,time:number//时长}:单位：min:可选
        abnormalClassTime : [{begin:11,time:120}],    //其他的课程时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
        abnormalRestingTime : [{begin:6,time:15},{begin:10,time:0}]   //其他休息时间时间 : Array[{},{}] : {begin:Number//开始的节数,time:number//时长} : 单位：min : 可选
    };
    return { courseInfos: data,sectionTimes: getTimes(xJConf,dJConf) }
}

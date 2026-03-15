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
function request(tag, data, url) {
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.send(data);
    return ss;
}

function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let ts =
        `
导入失败，请确保当前位于【学生课表查询】页面!
----------------------------------
       >>导入流程<<
    >>点击【学生课表查询】<<
     >>点击【一键导入】<<

 `
//     alert(ts)

    let dJConf ={
        courseSum : 10,
        startTime  : '800',
        oneCourseTime : 45,
        longRestingTime  : 20,
        shortRestingTime : 10,
        longRestingTimeBegin:[2,6],
        lunchTime  : {begin:4,time:2*60+20},
        dinnerTime : {begin:8,time:80},
        // abnormalClassTime:[{begin:1,time:40}],
        //abnormalRestingTime:[]
    };

    let xJConf ={
        courseSum : 10,
        startTime  : '800',
        oneCourseTime : 45,
        longRestingTime  : 20,
        shortRestingTime : 10,
        longRestingTimeBegin:[2,6],
        lunchTime  : {begin:4,time:2*60+50},
        dinnerTime : {begin:8,time:65},
        // abnormalClassTime:[{begin:1,time:40}],
        //abnormalRestingTime:[]
    };
    let htt;

    try{
        htt = dom.getElementById("ylkbTable").outerHTML
    }catch(e){
        try{
            let id;
            let arr = dom.getElementById("cdNav").outerHTML.match(/(?<=clickMenu\().*?(?=\);)/g)
            for(i in arr){
                if(arr[i].search("学生课表查询")!=-1){
                    id = arr[i].split(",")[0].slice(1,-1)
                    console.log(id)
                    break;
                }
            }
            //简写
            //id = arr.find(v=> v.search("学生课表查询") != -1).split(",")[0].slice(1, -1)

            let su = dom.getElementById("sessionUserKey").value
            let html = request("get",null,"/jwglxt/kbcx/xskbcx_cxXskbcxIndex.html?gnmkdm="+id)
            dom = new DOMParser().parseFromString(html,"text/html")
            let form =dom.getElementById("ajaxForm")
            htt = JSON.stringify(JSON.parse(request("post","xnm="+form.xnm.value+"&xqm="+form.xqm.value,"/jwglxt/kbcx/xskbcx_cxXsKb.html")).kbList)
        }catch(e){
            alert(ts+e)
        }

    }
    return JSON.stringify({html:htt,sj:getTimes(xJConf,dJConf)})

}
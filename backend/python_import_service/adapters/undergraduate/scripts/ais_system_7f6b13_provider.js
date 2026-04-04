// Source: 参考文件/aishedule-master/自研教务/齐齐哈尔医学院/provider.js

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

// Merged parser.js

function resolveCourseConflicts(result) {
    let splitTag="&"
//将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach(singleCourse => {
        singleCourse.weeks.forEach(week => {
            singleCourse.sections.forEach(value => {
                let course = {sections: [], weeks: []}
                course.name = singleCourse.name;
                course.teacher = singleCourse.teacher==undefined?"":singleCourse.teacher;
                course.position = singleCourse.position==undefined?"":singleCourse.position;
                course.day = singleCourse.day;
                course.weeks.push(week);
                course.sections.push(value);
                allResultSet.add(JSON.stringify(course));
            })
        })
    })
    let allResult = JSON.parse("[" + Array.from(allResultSet).toString() + "]").sort(function (a, b) {
        //return b.day - e.day;
        return (a.day - b.day)||(a.sections[0]-b.sections[0]);
    })

    //将冲突的课程进行合并
    let contractResult = [];
    while (allResult.length !== 0) {
        let firstCourse = allResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
     //   console.log(firstCourse)
        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0] === allResult[i].sections[0]) {
                    let index = firstCourse.name.split(splitTag).indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += splitTag + allResult[i].name;
                        firstCourse.teacher += splitTag + allResult[i].teacher;
                        firstCourse.position += splitTag + allResult[i].position;
                       // firstCourse.position = firstCourse.position.replace(/undefined/g, '')
                        allResult.splice(i, 1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split(splitTag);
                        let position = firstCourse.position.split(splitTag);
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join(splitTag);
                        firstCourse.position = position.join(splitTag);
                       // firstCourse.position = firstCourse.position.replace(/undefined/g, '');
                        allResult.splice(i, 1);
                        i--;
                    }

                }
            }
        }
        contractResult.push(firstCourse);
    }
    //将每一天内的课程进行合并
    let finallyResult = []
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.weeks[0] === contractResult[i].weeks[0] && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                if (firstCourse.sections[firstCourse.sections.length - 1] + 1 === contractResult[i].sections[0]) {
                    firstCourse.sections.push(contractResult[i].sections[0]);
                    contractResult.splice(i, 1);
                    i--;
                } else break
                // delete (contractResult[i])
            }
        }
        finallyResult.push(firstCourse);
    }
    //将课程的周次进行合并
    contractResult = JSON.parse(JSON.stringify(finallyResult));
    finallyResult.length = 0;
    while (contractResult.length != 0) {
        let firstCourse = contractResult.shift();
        if (firstCourse == undefined) continue;
        let weekTag = firstCourse.day;
        for (let i = 0; contractResult[i] !== undefined && weekTag === contractResult[i].day; i++) {
            if (firstCourse.sections.sort((a,b)=>a-b).toString()=== contractResult[i].sections.sort((a,b)=>a-b).toString() && firstCourse.name === contractResult[i].name && firstCourse.position === contractResult[i].position && firstCourse.teacher === contractResult[i].teacher) {
                firstCourse.weeks.push(contractResult[i].weeks[0]);
                contractResult.splice(i, 1);
                i--;
            }
        }
        finallyResult.push(firstCourse);
    }
    console.log(finallyResult);
    return finallyResult;
}

function getWeeks(Str) {
    function range(con, tag) {
        if(con.length==1) return [];
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
    Str = Str.replace(/\(|\)|\{|\}|\||第/g, "").replace(/到/g, "-").replace(/\./g,",")
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
    console.log(reWeek)
    return reWeek;
}

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
    let result = []
    let $ = cheerio.load(html,{decodeEntities: false})
    let trs = $('tr','tbody')
    trs = trs.slice(3,-1)
    let message =""
    try{
       trs.each(function(index,_){
       let tds = $(this).children('td')
       tds.slice(1).each(function(week,__){
          if($(this).text().length<=1) return
           console.log($(this).text(),"index:",index)
           let coursesHTML = $(this).html()
           let courses = coursesHTML.split(/<br.*?>/)
           console.log(courses)
           for (let i = 0;i<courses.length;i=i+4){
               let course = {sections:[],weeks:[] }
               course.name = courses[i]
               course.teacher = courses[i+1]
               course.position = courses[i+2]
               course.weeks = getWeeks(courses[i+3].split(/\s/)[0])
               course.day = week+1
               course.sections=[(index+1)*2-1,(index+1)*2]
               result.push(course)
           }
       })
    })
    
    if(result.length ==0 ) message="未获取到课表"
    else{
           result = resolveCourseConflicts(result)
        }
   
    }catch(e){
        console.log(e)
       message=e.message.slice(0,50)
    }
    if(message.length!=0){
        result.length=0;
        result.push({name:"遇到错误,请加群:628325112,找开发者进行反馈",teacher:"开发者-萧萧",position:message,day:1,weeks:[1],sections:[{section:1},{section:2}]})
    }

    console.log(result)
    return result 
}

// Merged timer.js

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
  /**
   * 时间配置函数，此为入口函数，不要改动函数名
   */
  async function scheduleTimer() {
  //   let time1 = {
  //     courseSum: 12,
  //     startTime: '0810',
  //     oneCourseTime: 45,
  //     longRestingTime: 25,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 3 * 60-15 },
  //     dinnerTime: { begin: 10, time: 10 },
  //     abnormalClassTime:[{begin:3,time:40},{begin:4,time:40}],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:5,time:10},{begin:6,time:15},{begin:8,time:10}]
  // }
  // let time2 = {
  //     courseSum: 12,
  //     startTime: '0810',
  //     oneCourseTime: 45,
  //     longRestingTime: 35,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 2 * 60+15 },
  //     dinnerTime: { begin: 10, time: 10 },
  //     abnormalClassTime:[],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:10},{begin:5,time:10},{begin:6,time:15},{begin:8,time:10}]
  // }
  // let time3 = {
  //     courseSum: 12,
  //     startTime: '0830',
  //     oneCourseTime: 45,
  //     longRestingTime: 30,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 1 * 60+50 },
  //     dinnerTime: { begin: 10, time: 20 },
  //     abnormalClassTime:[],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:5},{begin:5,time:5},{begin:6,time:20},{begin:8,time:60}]
  // }
  // let time4 = {
  //     courseSum: 12,
  //     startTime: '0830',
  //     oneCourseTime: 45,
  //     longRestingTime: 20,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 1 * 60+75 },
  //     dinnerTime: { begin: 10, time: 20 },
  //     abnormalClassTime:[{begin:3,time:40},{begin:4,time:40}],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:0},{begin:5,time:5},{begin:6,time:20},{begin:8,time:60}]
  // }
  
    // 内嵌loadTool工具，传入工具名即可引用公共工具函数(暂未确定公共函数，后续会开放)
    await loadTool('AIScheduleTools')
    const { AISchedulePrompt } = AIScheduleTools()
  //   // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
  //   await AIScheduleAlert('liuwenkiii yyds!')
  //   // 支持异步操作 推荐await写法
  //   const someAsyncFunc = () => new Promise(resolve => {
  //     setTimeout(() => resolve(), 100)
  //   })  
  //   await someAsyncFunc()
    // 返回时间配置JSON，所有项都为可选项，如果不进行时间配置，请返回空对象
  //   let mess =
  //   `
  // 时间一（1）: 天河-9#,10#,12#,图书馆,加工车间,公路楼,汽车实训楼
  // 时间一（1）: 花都-1#,图书馆
  // 时间二（2）: 天河-2#,运动场
  // 时间二（2）: 花都-10#,15#,16#,运动场
  // 时间三（3）: 清远-立业16#,求是18#,笃实19#,运动场
  // 时间四（4）: 清远-融创13#,创新17#
  
   // `
  //  let tag =  await AISchedulePrompt({titleText:"请选择时间",tipText:mess,defaultText:"1",validator:value=>{if(value ==1||value ==2||value ==3||value ==4) return false;else return "请输入1,2,3,4"}})
  //  let times; 
  //  console.log
  //  switch(Number(tag)){
  //    case 1:times = getTimes(time1);break;
  //    case 2:times = getTimes(time2);break;
  //    case 3:times = getTimes(time3);break;
  //    case 4:times = getTimes(time4);break;
  //    default: console.error(tag);
  //  }
    return {
      totalWeek: 20, // 总周数：[1, 30]之间的整数
      startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
      startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
      showWeekend: false, // 是否显示周末
      forenoon: 4, // 上午课程节数：[1, 10]之间的整数
      afternoon: 4, // 下午课程节数：[0, 10]之间的整数
      night: 4, // 晚间课程节数：[0, 10]之间的整数
      sections: getTimes({
        courseSum: 12,
        startTime: '800',
        oneCourseTime: 45,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2],
        lunchTime: {begin: 4, time: 2 * 60 - 10},
        dinnerTime: {begin: 8, time: 60},
    }), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
    }
    // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
  }

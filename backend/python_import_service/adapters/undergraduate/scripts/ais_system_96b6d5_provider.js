// Source: 参考文件/aishedule-master/自研教务/泉州师范学院/provider.js

async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {//函数名不要动
    await loadTool('AIScheduleTools')
    let ifs = window.frames
     let result={}
     if(ifs.length!=0){
       try{
         dom = ifs[0].frames['mainFrame'].document
         result.course = dom.getElementsByClassName("infolist_tab")[0].outerHTML
         result.time = dom.getElementsByClassName("infolist_tab")[1].outerHTML
         result.tag = "LIST"
       }catch(e){
        
         await AIScheduleAlert('遇到错误，可能是未处于课表页面，请在课表页面导入或进群（812150996）联系开发者；错误：'+e)
         return "do not continue"
       }
       
     }else{
       result.tag=tag = location.href.split("=").pop()
       result.course = dom.getElementsByClassName("content_tab")[0].outerHTML
       
       // console.log(dom)
     }
    if(result.tag == "COMBINE"){
     await AIScheduleAlert('当前页面暂未适配，请切换其他课表页面')
     return "do not continue"
     
    }
    // localStorage.setItem("JSON",JSON.stringify(result))
     return JSON.stringify(result);
   }
   //window.frames[0].frames['mainFrame'].document

// Merged parser.js

function resolveCourseConflicts(result) {
    //将课拆成单节，并去重
        let allResultSet = new Set()
        result.forEach(singleCourse => {
            singleCourse.weeks.forEach(week => {
                singleCourse.sections.forEach(value => {
                    let course = {sections: [], weeks: []}
                    course.name = singleCourse.name;
                    course.teacher = singleCourse.teacher;
                    course.position = singleCourse.position;
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
    
            for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
                if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                    if (firstCourse.sections[0] === allResult[i].sections[0]) {
                        let index = firstCourse.name.split('|').indexOf(allResult[i].name);
                        if (index === -1) {
                            firstCourse.name += "|" + allResult[i].name;
                            firstCourse.teacher += "|" + allResult[i].teacher;
                            firstCourse.position += "|" + allResult[i].position;
                            firstCourse.position = firstCourse.position.replace(/undefined/g, '')
                            allResult.splice(i, 1);
                            i--;
                        } else {
                            let teacher = firstCourse.teacher.split("|");
                            let position = firstCourse.position.split("|");
                            teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                            position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                            firstCourse.teacher = teacher.join("|");
                            firstCourse.position = position.join("|");
                            firstCourse.position = firstCourse.position.replace(/undefined/g, '');
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
        // contractResult = contractResult.sort(function (a, b) {
        //     return (a.day - b.day)||(a.sections[0]-b.sections[0]);
        // })
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
        // contractResult = contractResult.sort(function (a, b) {
        //     return a.day - b.day;
        // })
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
    
    
    let getWeeks = (Str)=> {
      console.log(Str)
        function range(con, tag) {
            if(con.length==0) return [];
            let retWeek=[]
            let tt = con.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag === 1 || tag === 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag===0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 !== 0    }))
            return retWeek
        }
        Str = Str.replace(/[(){}|第周\[\]]/g, "").replace(/到/g, "-")
        let reWeek = [];
        let week1 = []
        week1 = Str.split(/[,、]/)
      console.log(week1)
        week1.forEach(v => {
            if (v.search("双") != -1) reWeek.push(...range(v.replace("双",""), 2))
            else if (v.search("单") != -1) reWeek.push(...range(v.replace("单",""), 3))
            else reWeek.push(...range(v, 1))
        });
      console.log(reWeek)
        return reWeek;
    }
    
    
    let getWeek = (weekStr) => {
      let weeks = ["","一","二","三","四","五","六","七","日"]
      let week = weeks.indexOf(weekStr)
      return week==8?week-1:week;
    }
    let getSectionMap = (sectionStr) => {
      let $$ = cheerio.load(sectionStr);
      let trs = $$(".infolist_common")
      let secMap = new Map();
      trs.each((v,tr)=>{
        let tds = $$(tr).children("td")
        let key = tds.eq(1).text().trim()
        let weekArr = tds.eq(2).text().replace(/[第节]/g,"").trim().split(" ")
        weekArr = weekArr.map(v=>{
          if(v=='午间1') return 5;
          else if(v=='午间2') return 6;
          else if(Number(v)>=5) return Number(v)+2;
         // else if(Number(v)>=9&&Number(v)<=11) return Number(v)+2
          else return Number(v)
        })
        secMap.set(key,weekArr)
      })
      return secMap;
    }
    function scheduleHtmlParser(json) {
      //除函数名外都可编辑
      //传入的参数为上一步函数获取到的html
      //可使用正则匹配
      //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://cnodejs.org/topic/5203a71844e76d216a727d2e
      let providerJSON = JSON.parse(json)
      let result = []
      if(providerJSON.tag=="LIST"){
        let $ = cheerio.load(providerJSON.course, {decodeEntities: false});
        let trs = $(".infolist_common") 
        let sectionMap = getSectionMap(providerJSON.time);
        console.log(sectionMap)
        trs.each((v,tr)=>{
          let re = {}
          let tds = $(tr).children("td")
          let courseTimePosTab =  tds.eq(9).children("table")
          if(!courseTimePosTab.length) return;
          re.name = tds.eq(2).text().trim()
          re.teacher = tds.eq(3).html().replace(/<a.*?>|<\/a>/g,"").replace(/<br>/g," ").trim()
          let CTPtrs = courseTimePosTab.find("tr")
          CTPtrs.each((vv,CTPtr)=>{
            
            let CTPtds = $(CTPtr).children("td").filter((i,el)=>{return $(el).text().trim().length})
            if(CTPtds.length==1) return
            re.day = getWeek(CTPtds.eq(1).text().trim().slice(-1))
            re.position = CTPtds.eq(3).text().trim()
            re.sections = sectionMap.get(CTPtds.eq(2).text().trim())
            re.weeks = getWeeks(CTPtds.eq(0).text().trim())
            
           result.push(JSON.parse(JSON.stringify(re)))
          })
        })
      }else if(providerJSON.tag=="BASE"){
        let $ = cheerio.load(providerJSON.course, {decodeEntities: false});
        let trs = $(".infolist_hr").eq(0).find(".infolist_hr_common")
        trs.each((index,tr)=>{
          let tds = $(tr).children("td")
          tds.each((ind,td)=>{
            let text=$(td).html()
            console.log(text)
            let tds = $(td).html().replace(/\<wbr\>/g,"").replace(/&gt;&gt;|\>\>|&nbsp;|\s/g,"").split(/&lt;&lt;|\<\</).filter(Boolean)
            if(!tds.length) return;
            tds.forEach(v=>{
              let info = v.split("<br>").filter(v=>{return v.length})
              console.log(info)
              let tag = 0;
              if(info.length == 5 || info[3].search(/[第\-周]/)!=-1) tag = 0
              else if(info.length == 4) tag = 1;
                result.push({
                  "name":info[0].split(";")[0],
                  "position":!tag?info[1]:"",
                  "teacher":info[2-tag],
                  "weeks":getWeeks(info[3-tag]),
                  "day":Number($(td).attr("id").split("-")[0]),
                  "sections":[Number($(td).attr("id").split("-")[1])]
                })
            })
          })
        })
        
      }
    
    //return result;
      return resolveCourseConflicts(result)
    }

// Merged timer.js

/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
 async function scheduleTimer() {

  let providerJSON = JSON.parse(providerRes)
 // alert(providerJSON.tag)
 // let providerJSON = JSON.parse(localStorage.getItem("JSON"))
  let doms;
   // let sections = []
    let timeJson = {
      totalWeek: 30, // 总周数：[1, 30]之间的整数
      startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
      startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
      showWeekend: true, // 是否显示周末
      forenoon: 4, // 上午课程节数：[1, 10]之间的整数
      afternoon: 6, // 下午课程节数：[0, 10]之间的整数
      night: 0, // 晚间课程节数：[0, 10]之间的整数
      sections: []
  }
  let readAsText = (blob, encoding) => {
    return new Promise((resolve, reject) => {
        const fr = new FileReader();
        fr.onload = event => {
            resolve(fr.result);
        };

        fr.onerror = err => {
            reject(err);
        };

        fr.readAsText(blob, encoding);
    });
};
  let arr = ['','1','2','3','4','午间1','午间2','5','6','7','8','9','10','11']
  if(providerJSON.tag == "LIST"){   
    let url = window.frames[0].frames['mainFrame'].document.getElementsByClassName("button")[0].getAttribute("onclick").match(/'.*?'/)[0].replace(/'/g,"").replace("../../","")
     doms = await (new DOMParser().parseFromString(await fetch(url).then(re=>re.blob().then(v=>readAsText(v,'gbk'))).then(v=>v),"text/html"))
  }
  else if(providerJSON.tag == "BASE"){
     doms = new DOMParser().parseFromString(providerJSON.course,"text/html")
   }
    let trs = doms.getElementsByClassName("infolist_hr")[0].getElementsByClassName("infolist_hr_common")
    console.log(trs.length)
    for(let i=0;i<trs.length;i++){
      let th = trs[i].getElementsByTagName("th")[0]
      let timearr = th.innerHTML.replace(/[第节]/g,"").split("<br>")
      console.log(timearr)
     let sec = arr.indexOf(timearr[0])
      if(sec!=-1){
        timeJson.sections.push({
          "section": sec,
          "startTime": timearr[1],
          "endTime":timearr[3]
        })
      }
      timeJson.night=timeJson.sections.length-10
  }
 if(timeJson.sections.length==0) timeJson = {}
  return timeJson
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

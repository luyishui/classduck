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
     // console.log(week1)
        week1.forEach(v => {
            if (v.search("双") != -1) reWeek.push(...range(v.replace("双",""), 2))
            else if (v.search("单") != -1) reWeek.push(...range(v.replace("单",""), 3))
            else reWeek.push(...range(v, 1))
        });
    //  console.log(reWeek)
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
          if(v=='T1') return 5;
          else if(v=='T2') return 10;
          else if(Number(v)>=5&&Number(v)<=8) return Number(v)+1;
          else if(Number(v)>=9&&Number(v)<=11) return Number(v)+2
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
       // console.log(sectionMap)
        trs.each((v,tr)=>{
          let re = {}
          let tds = $(tr).children("td")
          let courseTimePosTab =  tds.eq(9).children("table")
          if(!courseTimePosTab.length) return;
          re.name = tds.eq(2).text().trim()
          re.teacher = tds.eq(3).html().replace(/<a.*?>|<\/a>/g,"").replace(/<br>/g," ").trim()
          let CTPtrs = courseTimePosTab.find("tr")
          CTPtrs.each((vv,CTPtr)=>{
            let CTPtds = $(CTPtr).children("td")
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
            //console.log(text)
            let tds = $(td).html().replace(/&gt;&gt;|\>\>|&nbsp;|\s/g,"").split(/&lt;&lt;|\<\</).filter(Boolean)
            if(!tds.length) return;
            tds.forEach(v=>{
              let info = v.split("<br>").filter(v=>{return v.length})
              console.log(info)
              if(info.length == 5){
                result.push({
                  "name":info[0].split(";")[0],
                  "position":info[1],
                  "teacher":info[2],
                  "weeks":getWeeks(info[3]),
                  "day":Number($(td).attr("id").split("-")[0]),
                  "sections":[Number($(td).attr("id").split("-")[1])]
                })
              }
              else if(info.length == 4){
                result.push({
                  "name":info[0].split(";")[0],
                  "position":"",
                  "teacher":info[1],
                  "weeks":getWeeks(info[2]),
                  "day":Number($(td).attr("id").split("-")[0]),
                  "sections":[$(td).attr("id").split("-")[1]]
                })
              }
              else{
                result.push({
                  "name":info[0].split(";")[0],
                  "position":""+tds.length,
                  "teacher":""+info.length,
                  "weeks":[30],//getWeeks(info[2]),
                  "day":Number($(td).attr("id").split("-")[0]),
                  "sections":[$(td).attr("id").split("-")[1]]
                })
              }
            })
    
                //      result.push({
                //   "name":text,
                //   "position":"",
                //   "teacher":"1",
                //   "weeks":[1],
                //   "day":1,
                //   "sections":[1]
                // })
          })
        })
        
      }
    
    //return result;
      return resolveCourseConflicts(result)
    }
    
    
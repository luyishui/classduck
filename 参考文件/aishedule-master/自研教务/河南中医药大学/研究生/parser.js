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
    
  

    let getSections = (start,rowspan)=>{
      let sections = [];
      for (let index = 0; index <rowspan; index++) {
          sections.push(start+index)
      }
      return sections;
    }
    function scheduleHtmlParser(html) {
      //除函数名外都可编辑
      //传入的参数为上一步函数获取到的html
      //可使用正则匹配
      //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://cnodejs.org/topic/5203a71844e76d216a727d2e
      let result = []
        let $ = cheerio.load(html, {decodeEntities: false});
        let trs = $("tr").slice(1)
        for (let index = 0; index < 7; index++) {
          console.log("------------day----"+index  +"--------------------")
          for(let i=0;i<trs.length;i++){
            console.log("----"+i)
          let tds = trs.eq(i).children("td[align!='center']")
          let rowspan = tds.eq(0).attr("rowspan")
          let start = i;
          if(rowspan){
            i = i+Number(rowspan)-1
          }
          let html = tds.eq(0).html()
          if(!tds.eq(0).text().trim()) {
            tds.eq(0).remove()
            continue
          }
          tds.eq(0).remove()
          let cours = html.split("<br><br>").filter(v=>v&&v.trim())
          cours.forEach(course=>{
            let re = {}
            let sin = course.split("<br>")
            re.name = sin[0].replace("课程:","")
            re.position = sin[2]
            re.weeks = getWeeks(sin[3])
            re.teacher = sin[4].replace("主讲教师:","")
            re.day = index+1;
            re.sections = getSections(start+1,rowspan?Number(rowspan):1)
            console.log(sin[0])
            console.log(sin[2])
            console.log(sin[3])
            console.log(sin[4])
            result.push(JSON.parse(JSON.stringify(re)))
          })
        }
        }
      return resolveCourseConflicts(result)
    }
    
    
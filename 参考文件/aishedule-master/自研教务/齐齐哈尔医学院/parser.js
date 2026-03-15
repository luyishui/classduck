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
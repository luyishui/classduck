// Source: 参考文件/aishedule-master/金窗教务/四川科技职业学院/provider.js

function scheduleHtmlProvider(
    iframeContent = '',
    frameContent = '',
    dom = document
) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    const table = dom.getElementsByTagName("table")[1]
    return table.outerHTML
}

// Merged parser.js

/**
 * @desc 尝试将冲突课程进行合并
 * @param result {object} 原始课程JSON
 * @returns {Array[]} 合并后JSON
 */
function resolveCourseConflicts(result) {
    let splitTag="&" //重复课程之间的分割标识
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
        for (let i = 0; allResult[i] !== undefined && weekTag === allResult[i].day; i++) {
            if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
                if (firstCourse.sections[0] === allResult[i].sections[0]) {
                    let index = firstCourse.name.split(splitTag).indexOf(allResult[i].name);
                    if (index === -1) {
                        firstCourse.name += splitTag + allResult[i].name;
                        firstCourse.teacher += splitTag + allResult[i].teacher;
                        firstCourse.position += splitTag + allResult[i].position;
                        allResult.splice(i, 1);
                        i--;
                    } else {
                        let teacher = firstCourse.teacher.split(splitTag);
                        let position = firstCourse.position.split(splitTag);
                        teacher[index] = teacher[index] === allResult[i].teacher ? teacher[index] : teacher[index] + "," + allResult[i].teacher;
                        position[index] = position[index] === allResult[i].position ? position[index] : position[index] + "," + allResult[i].position;
                        firstCourse.teacher = teacher.join(splitTag);
                        firstCourse.position = position.join(splitTag);
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
/**
 * @desc 以周或空格为界，进行分割，且分割符号前后有单双周标记，没有默认为全周
 * @param Str : String : 如：1-6,7-13周(单)
 * @returns {Array[]} : 返回数组
 * @example
 * getWeeks("1-6,7-13周(单)")=>[1,3,5,7,9,11,13]
 */
function getWeeks(Str) {
    function range(con, tag) {
        let retWeek = [];
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-');
            let start = parseInt(tt[0]);
            let end = parseInt(tt[tt.length - 1]);
            if (tag === 1 || tag === 2) retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f => {
                return f % tag === 0;
            }))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {
                return v % 2 !== 0;
            }))
        })
        return retWeek;
    }

    Str = Str.replace(/[(){}|第\[\]]/g, "").replace(/到/g, "-");
    let reWeek = [];
    let week1 = [];
    while (Str.search(/周|\s/) !== -1) {
        let index = Str.search(/周|\s/);
        if (Str[index + 1] === '单' || Str[index + 1] === '双') {
            week1.push(Str.slice(0, index + 2).replace(/周|\s/g, ""));
            index += 2;
        } else {
            week1.push(Str.slice(0, index + 1).replace(/周|\s/g, ""));
            index += 1;
        }

        Str = Str.slice(index);
        index = Str.search(/\d/);
        if (index !== -1) Str = Str.slice(index);
        else Str = "";

    }
    if (Str.length !== 0) week1.push(Str);
    console.log(week1);
    week1.forEach(v => {
        console.log(v);
        if (v.slice(-1) === "双") reWeek.push(...range(v, 2));
        else if (v.slice(-1) === "单") reWeek.push(...range(v, 3));
        else reWeek.push(...range(v + "全", 1));
    });
    return reWeek;
}

// function getSections(sectionText){
//     console.log("------------"+sectionText)
//     let result = []
//     let numberText = sectionText.replace(/\D/g,"")
//     let numbers =[]
//     while (true){
//         const index = numberText.slice(2).search("0")
//         if(index===-1) {
//             numbers.push(numberText)
//             break
//         }
//         numbers.push(numberText.slice(0,index+1))
//         numberText = numberText.slice(index+1)
//     }
//     numbers.forEach(num=>{
//         let nums = num.split("")
//         if(nums.length===1||(nums.length===2&&nums[1]==="0")){
//             result.push(Number(num))
//         }
//         else if(nums[0]===nums[2]){
//             for (let i = 0; i < nums.length; i+=2) {
//                 result.push(Number(nums[i]+""+nums[i+1]))
//             }
//         }else {
//             nums.forEach(v=>result.push(Number(v)))
//         }
//     })
//     console.log(numbers)
//     return result
// }

function scheduleHtmlParser(html) {
    let $ = cheerio.load(html,{decodeEntities:false});
    let trs = $("tbody").children("tr")
    let result = []
    trs.slice(1).each(function (tr_i,_) {
        let tds = $(this).children("td[valign=top]")
        tds.each(function (td_i,_){
            console.log(td_i)
            let courseHtml = $(this).html()
            let courseArr = courseHtml.split("<br>").slice(0,-1)
            // console.log(courseArr)
            for (let i = 0; i < courseArr.length; i+=5) {
                let re = {weeks: [], sections: []};
                let sectionText = courseArr[i+1].replace(/^\(|\)$/g,"")
                let tag = sectionText.match(/单|双/)
                re.name = courseArr[i]
                re.teacher = courseArr[i+2]
                re.position = courseArr[i+3]
                re.weeks = getWeeks(tag===null?courseArr[i+4]:courseArr[i+4]+tag[0])
                // re.sections = getSections(sectionText)
                re.sections = [(tr_i+1)*2-1,(tr_i+1)*2]
                re.day = Number(td_i)+1
                result.push(re)
            }
        })
    })
    return resolveCourseConflicts(result)
}

// Merged timer.js

async function scheduleTimer() {
    return {}
}

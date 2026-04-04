// Source: 参考文件/aishedule-master/青果教务/陇东学院_新版/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2021-11-10 20:00:51
 * @LastEditTime: 2022-08-14 18:07:44
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\青果教务\陇东学院_新版\provider.js
 * @QQ：357914968
 */
async function request(tag, encod, url) {
  let formatText = (text, encoding) => {
    return new Promise((resolve, reject) => {
      const fr = new FileReader()
      fr.onload = (event) => {
        resolve(fr.result)
      }

      fr.onerror = (err) => {
        reject(err)
      }

      fr.readAsText(text, encoding)
    })
  }
  return await fetch(url, { method: tag })
    .then((rp) => rp.blob().then((v) => formatText(v, encod)))
    .then((v) => v)
    .catch((er) => er)
}
function base64Encode(input) {
  var _keys =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
  //if (this.is_unicode) input = this._u2a(input);
  var output = ''
  var chr1,
    chr2,
    chr3 = ''
  var enc1,
    enc2,
    enc3,
    enc4 = ''
  var i = 0
  do {
    chr1 = input.charCodeAt(i++)
    chr2 = input.charCodeAt(i++)
    chr3 = input.charCodeAt(i++)
    enc1 = chr1 >> 2
    enc2 = ((chr1 & 3) << 4) | (chr2 >> 4)
    enc3 = ((chr2 & 15) << 2) | (chr3 >> 6)
    enc4 = chr3 & 63
    if (isNaN(chr2)) {
      enc3 = enc4 = 64
    } else if (isNaN(chr3)) {
      enc4 = 64
    }
    output =
      output +
      _keys.charAt(enc1) +
      _keys.charAt(enc2) +
      _keys.charAt(enc3) +
      _keys.charAt(enc4)
    chr1 = chr2 = chr3 = ''
    enc1 = enc2 = enc3 = enc4 = ''
  } while (i < input.length)
  return output
}
async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  //alert("当【二维表】或【格式一】模式导入失败时，\n请尝试使用【列表】或【格式二】模式")
  //console.log(window.frames["frmDesk"].document.getElementById("frame_1").contentWindow.document)
  let kbdom
  let id
  let ht = ''
  try {
    dom = window.frames['frmDesk']
    if (
      dom.document.getElementById('xnxq') &&
      dom.frames['frmReport'] == undefined
    ) {
      let xnxq = dom.document.getElementById('xnxq').value.split('-')
      let html = await request(
        'post',
        'utf8',
        '/frame/desk/showLessonScheduleInfosV14.action?xn=' +
          xnxq[0] +
          '&xq=' +
          xnxq[1]
      )
      dom = new DOMParser().parseFromString(html, 'text/html')
      console.log(dom)
      return JSON.stringify({
        htm: dom.getElementById('lessonSchedule-content').outerHTML,
        bz: 'index',
      })
    } else if (dom.document.getElementById('cxfs_ewb') != undefined) {
      kbdom = dom.frames['frmReport'].document
      dom1 = dom.document
      let lb = dom1.getElementById('cxfs_lb').checked
      let ewb = dom1.getElementById('cxfs_ewb').checked
      if (lb) id = '列表'
      else if (ewb) id = '二维表'
    } else if (dom.document.getElementById('selGS') != undefined) {
      kbdom = dom.frames['frmReport'].document
      id = dom.document.getElementById('selGS').value
    } else {
      let info = JSON.parse(
        await request('get', 'gbk', '/jw/common/showYearTerm.action')
      )
      let courseTable = await request(
        'get',
        'gbk',
        '/student/wsxk.xskcb10319.jsp?params=' +
          base64Encode(
            'xn=' + info.xn + '&xq=' + info.xqM + '&xh=' + info.userCode
          )
      )
      kbdom = new DOMParser().parseFromString(courseTable, 'text/html')
      id = '二维表'
    }
    console.log(kbdom)
    let tables = kbdom.getElementsByTagName('table')

    for (i = 0; i < tables.length; i++) {
      ht += tables[i].outerHTML
    }
  } catch (e) {
    try {
      let info = JSON.parse(
        await request('get', 'gbk', '/jw/common/showYearTerm.action')
      )
      ht = await request(
        'get',
        'gbk',
        '/student/wsxk.xskcb10319.jsp?params=' +
          base64Encode(
            'xn=' + info.xn + '&xq=' + info.xqM + '&xh=' + info.userCode
          )
      )
      id = '二维表'
    } catch (error) {
      console.error(e)
      bz = e.message.slice(0, 50)
    }
  }

  return JSON.stringify({ htm: ht, bz: id })
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
                course.teacher = course.teacher.replace(/&nbsp;/g,",")
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
    Str = Str.replace(/\(|\)|\{|\}|\||第|\[|\]/g, "").replace(/到/g, "-")
    let reWeek = [];
    let week1 = []
    while (Str.search(/周|\s/) != -1) {
        let index = Str.search(/周|\s/)
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

function cton(str) {
    let arr = ["","一","二","三","四","五","六","七","日"]
    return arr.indexOf(str)==8?arr.indexOf(str)-1:arr.indexOf(str);

}

function getjc(Str) {
    let jc = [];
    let jcar = Str.replace(/节|\[|\]/g, "").split("-").filter(Boolean)
    for (i = Number(jcar[0]); i <= jcar[jcar.length - 1]; i++) {
        jc.push(i)
    }
    return jc
}
function getre(v, day) {
    let re = {position: "", weeks: [], sections: []}
    re.day = day

    let ddkcar = v.split(/\s/).filter(vv => {
        return vv && vv.trim()
    }).filter(v => {
        return v.search(/新校区/) == -1
    })
    re.name = ddkcar[0]
    re.teacher = ddkcar[2]
    ddkcar = ddkcar.slice(3)
    if (ddkcar[ddkcar.length - 2].search(/节|周/) == -1 && ddkcar[ddkcar.length - 1].search(/\D/) == -1) ddkcar.pop()
    if (ddkcar[ddkcar.length - 1].search("节") != -1 ||( ddkcar[ddkcar.length - 2].search(/周|单|双/) != -1 && ddkcar[ddkcar.length - 1].search("-") != -1)) {
        re.sections = getjc(ddkcar[ddkcar.length - 1])
        ddkcar.pop()
        re.weeks = getWeeks(ddkcar.join(""))
    } else if (ddkcar[ddkcar.length - 1].search(/周|\[|\]/) != -1) return
    else {
        while (ddkcar[ddkcar.length - 1].search("节") == -1) {
            console.log(ddkcar[ddkcar.length - 1]), re.position = re.position + ddkcar[ddkcar.length - 1];
            ddkcar.pop()
        }
        re.sections = getjc(ddkcar[ddkcar.length - 1])
        ddkcar.pop()
        re.weeks = getWeeks(ddkcar.join(""))
    }
    console.log(re)
    return re
}

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改
    html = JSON.parse(html)
    let bz = html.bz
    let $ = cheerio.load(html.htm, {decodeEntities: false})
    let result = []
    if (bz == "index") {
        let courses = $("div .weeklesson")
        courses.each(function (index, _) {
            let dayjie = $(this).attr("id").replace("weekly", "").split("_")
            let course = $(this).children("ul").html().split("<br>")
            course.forEach(lesson => {
                $ = cheerio.load(lesson, {decodeEntities: false})
                let re = {weeks: [], sections: []}

                $("li").each(function (index, __) {

                    let con = $(this).text()
                    switch (con.split("：")[0]) {
                        case "课程名称":
                            re.name = $(this).children("b").text();
                            break;
                        case "任课教师":
                            re.teacher = $(this).children("b").text();
                            break;
                        case "上课地点":
                            re.position = $(this).children("b").text();
                            break;
                        case "上课时间":
                            re.day = parseInt(dayjie[0]);
                            let temp = $(this).children("b").text();
                            re.sections = getjc(temp.match(/\[.*?\]/g)[1]);
                            re.weeks = getWeeks(temp.match(/\[.*?\]/g)[0]+temp.match(/\(.*?\)/g));
                            break;
                    }
                })
                result.push(JSON.parse(JSON.stringify(re)))
            })
        })
    } 
  else if (bz == 1) {
        $('tr').each(function (index, em) {
            let tds = $(this).find('td[class="td"]')
            tds.each(function (index1, emm) {
                let div = $(this).find('div')
                div.each(function (ind, e) {
                    if ($(this).text().trim().length == 0) return
                    let font = $(this).find('font')
                    if (font.length != 0 && font.eq(font.length - 1).attr('title') != undefined) {
                        let text = font.eq(font.length - 1).attr('title')
                        text = text.split(/\n/).filter(vv => {
                            return vv && vv.trim()
                        })
                        text.forEach(v => {
                            console.log(v)
                            let re = getre(v, index1 + 1)
                            if (re.sections.length == 0) return
                            result.push(re)
                        })


                    } else {
                        let font = $(this).find('font')
                        if (font.length != 1) font = $(this)

                        let coursearr = font.html().split("<br>").filter(vv => {
                            return vv && vv.trim()
                        })
                        coursearr.forEach(v => {
                            console.log(v)
                            let re = getre(v, index1 + 1)
                            if (re.sections.length == 0) return
                            result.push(re)
                        })
                    }
                })
            })
        })
    } else if (bz == 2) {
        //  console.log(html.htm)
        let trs = $('tr')
        trs.each(function (index, em) {
            let td = $(this).find("td")
            let re = {weeks: [], sections: []}
            if (td.length > 4 && td.eq(0).text() != '校区') {
                re.name = td.eq(4).text().split("]")[1]
                re.teacher = td.eq(13).text()
                re.weeks = getWeeks(td.eq(16).text() + "周" + td.eq(17).text())
                re.sections = getjc(td.eq(18).text().match(/(?<=\[).*?(?=\])/)[0])
                re.day = cton(td.eq(18).text().split("[")[0])
                re.position = td.eq(19).text()
            }
            if (re.weeks.length == 0 || re.sections.length == 0) return;
            result.push(re)
        })
    } 
    else if (bz == "列表") {
        $('tr').each(function (index, em) {
            let tds = $(this).find('td[style!="display: none"]')
            //    console.log(tds.length )
            if (tds.eq(0).text().slice(0, 1).search(/\d/) == -1 || tds.length != 10 || tds.eq(8).text().search(/未排课/) != -1) return;
            let re = {weeks: [], sections: []}
            let names = tds.eq(1).text().split("]")
            let teacher = tds.eq(5).text().split("]")
            let dd = tds.eq(8).text().split(/\(\d+\),?|\s{1},/).filter(function (v) {
                return v && v.trim()
            })
            console.log(dd)
            re.name = names[names.length - 1]
            if (re.name.search(/网络课/) != -1) return;
            re.teacher = teacher[teacher.length - 1]
            dd.forEach(con => {
                arr = con.split(" ").filter(function (v) {
                    return v && v.trim()
                })
                re.weeks = getWeeks(arr[0])
                re.day = cton(arr[1].slice(0, 1))
                re.sections = getjc(arr[1].match(/(?<=\[).*?(?=\])/)[0])
                re.position = arr[2]
                result.push(JSON.parse(JSON.stringify(re)))
            })

        })
    } else if (bz == "二维表") {

        let trs = $('tr[class!="H"]')
        trs.each(function (index, em) {
            let td = $(this).find(".td")
            let i = 1
            td.each(function (ind, emm) {
                let div = $(this).find("div")
                div.each(function (indd, emmm) {
                    let re = {weeks: [], sections: []}
                    if ($(this).text().trim() != 0) {
                        let content = $(this).html().split("<br>")
                        let jc = content[2].match(/(?<=\[).*?(?=\])/)[0]
                        let week = content[2].split("[")[0]
                        re.name = $(this).find("font").eq(0).text()
                        if (re.name.search(/网络课/) != -1) return;
                        re.teacher = content[1]
                        re.position = content[3]
                        re.sections = getjc(jc)
                        re.weeks = getWeeks(week)
                        re.day = i
                        result.push(re)
                    }
                })
                i++;
            })
        })
    }else{
        result.length==0
        result.push({name:"遇到错误,请加群:628325112,找开发者进行反馈",teacher:"开发者-萧萧",position:bz,day:1,weeks:[1],sections:[1,2,3,4]})
    }
    if(result.length==0) result.push({name:"遇到错误,请加群:628325112,找开发者进行反馈",teacher:"开发者-萧萧",position:"未获取到课表",day:1,weeks:[1],sections:[1,2,3,4]})
    result = resolveCourseConflicts(result)
    return  result
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-03-09 20:24:40
 * @LastEditTime: 2022-03-09 20:31:52
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\青果教务\陇东学院\timer.js
 * @QQ：357914968
 */
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
  

  return {
    'totalWeek': 20, // 总周数：[1, 30]之间的整数
    'startSemester': '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    'startWithSunday': false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    'showWeekend': false, // 是否显示周末
    'forenoon': 4, // 上午课程节数：[1, 10]之间的整数
    'afternoon': 4, // 下午课程节数：[0, 10]之间的整数
    'night': 2, // 晚间课程节数：[0, 10]之间的整数
    'sections':getTimes({
        courseSum: 10,
        startTime: '800',
        oneCourseTime: 50,
        longRestingTime: 30,
        shortRestingTime: 10,
        longRestingTimeBegin: [2],
        lunchTime: {begin: 4, time: 2 * 60 + 40},
        dinnerTime: {begin: 8, time: 50},
        // abnormalRestingTime:[{begin:9,time:0}],
        // abnormalRestingTime: [{begin: 11, time: 5}, {begin: 12, time: 5}]
    }), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

// Source: 参考文件/aishedule-master/强智教务/iframe强智/南宁师范大学/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-06-26 08:36:28
 * @LastEditTime: 2022-06-26 09:08:04
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\强智教务\iframe强智\山东大学\provider.js
 * @QQ：357914968
 */
function request(tag, url, data) {
  let ss = ''
  let xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if ((xhr.readyState === 4 && xhr.status === 200) || xhr.status === 304) {
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')
  xhr.send(data)
  return ss
}

function getUrl(dom) {

  var kbjcmss = dom.getElementsByName("kbjcmsid");
  var kbjcmsid = "";
  for (var i = 0; i < kbjcmss.length; i++) {
    if (kbjcmss[i].className == "layui-this") {
      kbjcmsid = kbjcmss[i].getAttribute("data-value");
    }
  }
  console.log(dom.getElementsByClassName('search'))
  let selects = dom.getElementsByClassName('search')[0].getElementsByTagName('select')[0]
  console.log(selects)
  let index = selects.selectedIndex
  let text = selects[index].outerText

  return "/jsxsd/framework/mainV_index_loadkb.htmlx?rq=all&sjmsValue=" + kbjcmsid + "&xnxqid=" + text + "&xswk=false"

}

async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')

  let tagType = document.getElementsByClassName("current")[0].getElementsByTagName("span")[0].getAttribute("id")
  if (tagType !== 'span_NEW_XSD_PYGL_WDKB_XQLLKB') {
      await AIScheduleAlert("请位于学期理论课表");
      return "do not continue"
  }
  tagType = '1';
  // if (tagType !== 'span_NEW_XSD_PYGL_WDKB_XQLLKB') {
  //   tagType = (await AIScheduleSelect({
  //     titleText: '课表类型',
  //     contentText: '请选择需要导出的课表类型',
  //     selectList: ['0:首页课表（需要位于首页,无教师信息,稳定性未知）', '1:学期理论课表（准确度高）'],
  //   })).split(":")[0]
  // } else {
  //   tagType = '1'
  // }

  let result = { tag: tagType, htmlStr: "" }
  if (tagType=='1') {
    console.log("1")
    let html = ''
    let tag = true
    try {
      let ifs = document.getElementsByTagName('iframe')
      for (let index = 0; index < ifs.length; index++) {
        const doms = ifs[index]
        if (doms.src && doms.src.search('/jsxsd/xskb/xskb_list.do') != -1) {
          const currDom = doms.contentDocument
          html = currDom.getElementById('kbtable')
            ? currDom.getElementById('kbtable').outerHTML
            : currDom.getElementsByClassName('content_box')[0].outerHTML
          tag = false
        }
      }
      // console.log(ifs.length)
      if (tag) {
        // console.log(ifs.length)
        html = dom.getElementById('kbtable').outerHTML
      }
      result.htmlStr = html
    } catch (e) {
      console.error(e)
      let html = request('get', '/jsxsd/xskb/xskb_list.do', null)
      dom = new DOMParser().parseFromString(html, 'text/html')
      result.htmlStr = dom.getElementById('kbtable')
        ? dom.getElementById('kbtable').outerHTML
        : dom.getElementsByClassName('content_box')[0].outerHTML
    }
  } else {
    console.log("2")
    let html =  request('get',getUrl(document.getElementById('Frame0').contentDocument))
    dom = new DOMParser().parseFromString(html, 'text/html')
    result.htmlStr = dom.getElementsByTagName('table')[0].outerHTML
  }
  return JSON.stringify(result)
}

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-06-26 08:36:38
 * @LastEditTime: 2022-06-26 08:36:39
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\强智教务\iframe强智\山东大学\parseer.js
 * @QQ：357914968
 */

/**
 * @desc 以周或空格为界，进行分割，且分割符号前后有单双周标记，没有默认为全周
 * @param Str : String : 如：1-6,7-13周(单)
 * @returns {Array[]} : 返回数组
 * @example
 * getWeeks("1-6,7-13周(单)")=>[1,3,5,7,9,11,13]
 */
function getWeeks(Str) {
  function range(con, tag) {
    let retWeek = []
    con
      .slice(0, -1)
      .split(',')
      .forEach((w) => {
        let tt = w.split('-')
        let start = parseInt(tt[0])
        let end = parseInt(tt[tt.length - 1])
        if (tag === 1 || tag === 2)
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((f) => {
                return f % tag === 0
              })
          )
        else
          retWeek.push(
            ...Array(end + 1 - start)
              .fill(start)
              .map((x, y) => x + y)
              .filter((v) => {
                return v % 2 !== 0
              })
          )
      })
    return retWeek
  }

  Str = Str.replace(/[(){}|第\[\]]/g, '').replace(/到/g, '-')
  let reWeek = []
  let week1 = []
  while (Str.search(/周|\s/) !== -1) {
    let index = Str.search(/周|\s/)
    if (Str[index + 1] === '单' || Str[index + 1] === '双') {
      week1.push(Str.slice(0, index + 2).replace(/周|\s/g, ''))
      index += 2
    } else {
      week1.push(Str.slice(0, index + 1).replace(/周|\s/g, ''))
      index += 1
    }

    Str = Str.slice(index)
    index = Str.search(/\d/)
    if (index !== -1) Str = Str.slice(index)
    else Str = ''
  }
  if (Str.length !== 0) week1.push(Str)
  console.log(week1)
  week1.forEach((v) => {
    console.log(v)
    if (v.slice(-1) === '双') reWeek.push(...range(v, 2))
    else if (v.slice(-1) === '单') reWeek.push(...range(v, 3))
    else reWeek.push(...range(v + '全', 1))
  })
  return reWeek
}

/**
 * @param Str : String : 如: 1-4节 或 1-2-3-4节
 * @returns {Array[]}
 * @example
 * getSection("1-4节")=>[1,2,3,4]
 */
function getSection(Str) {
  let reJc = []
  let strArr = Str.replace('节', '').trim().split('-')
  if (strArr.length <= 2) {
    for (
      let i = Number(strArr[0]);
      i <= Number(strArr[strArr.length - 1]);
      i++
    ) {
      reJc.push(Number(i))
    }
  } else {
    strArr.forEach((v) => {
      reJc.push(Number(v))
    })
  }
  return reJc
}

/**
 * @desc 尝试将冲突课程进行合并
 * @param result {object} 原始课程JSON文件
 * @returns {Array[]} 合并后文件JSON
 */
function resolveCourseConflicts(result) {
  //将课拆成单节，并去重
  let allResultSet = new Set()
  result.forEach((singleCourse) => {
    singleCourse.weeks.forEach((week) => {
      singleCourse.sections.forEach((value) => {
        let course = { sections: [], weeks: [] }
        course.name = singleCourse.name
        course.teacher = singleCourse.teacher
        course.position = singleCourse.position
        course.day = singleCourse.day
        course.weeks.push(week)
        course.sections.push(value)
        allResultSet.add(JSON.stringify(course))
      })
    })
  })
  let allResult = JSON.parse(
    '[' + Array.from(allResultSet).toString() + ']'
  ).sort(function (a, b) {
    //return b.day - e.day;
    return a.day - b.day || a.sections[0] - b.sections[0]
  })

  //将冲突的课程进行合并
  let contractResult = []
  while (allResult.length !== 0) {
    let firstCourse = allResult.shift()
    if (firstCourse == undefined) continue
    let weekTag = firstCourse.day

    for (
      let i = 0;
      allResult[i] !== undefined && weekTag === allResult[i].day;
      i++
    ) {
      if (firstCourse.weeks[0] === allResult[i].weeks[0]) {
        if (firstCourse.sections[0] === allResult[i].sections[0]) {
          let index = firstCourse.name.split('|').indexOf(allResult[i].name)
          if (index === -1) {
            firstCourse.name += '|' + allResult[i].name
            firstCourse.teacher += '|' + allResult[i].teacher
            firstCourse.teacher = firstCourse.teacher.replace(
              /undefined/g,
              ''
            )
            firstCourse.position += '|' + allResult[i].position
            firstCourse.position = firstCourse.position.replace(
              /undefined/g,
              ''
            )
            allResult.splice(i, 1)
            i--
          } else {
            let teacher = firstCourse.teacher.split('|')
            let position = firstCourse.position.split('|')
            teacher[index] =
              teacher[index] === allResult[i].teacher
                ? teacher[index]
                : teacher[index] + ',' + allResult[i].teacher
            position[index] =
              position[index] === allResult[i].position
                ? position[index]
                : position[index] + ',' + allResult[i].position
            firstCourse.teacher = teacher.join('|')
            firstCourse.position = position.join('|')
            firstCourse.position = firstCourse.position.replace(
              /undefined/g,
              ''
            )
            allResult.splice(i, 1)
            i--
          }
        }
      }
    }
    contractResult.push(firstCourse)
  }
  //将每一天内的课程进行合并
  let finallyResult = []
  // contractResult = contractResult.sort(function (a, b) {
  //     return (a.day - b.day)||(a.sections[0]-b.sections[0]);
  // })
  while (contractResult.length != 0) {
    let firstCourse = contractResult.shift()
    if (firstCourse == undefined) continue
    let weekTag = firstCourse.day
    for (
      let i = 0;
      contractResult[i] !== undefined && weekTag === contractResult[i].day;
      i++
    ) {
      if (
        firstCourse.weeks[0] === contractResult[i].weeks[0] &&
        firstCourse.name === contractResult[i].name &&
        firstCourse.position === contractResult[i].position &&
        firstCourse.teacher === contractResult[i].teacher
      ) {
        if (
          firstCourse.sections[firstCourse.sections.length - 1] + 1 ===
          contractResult[i].sections[0]
        ) {
          firstCourse.sections.push(contractResult[i].sections[0])
          contractResult.splice(i, 1)
          i--
        } else break
        // delete (contractResult[i])
      }
    }
    finallyResult.push(firstCourse)
  }
  //将课程的周次进行合并
  contractResult = JSON.parse(JSON.stringify(finallyResult))
  finallyResult.length = 0
  // contractResult = contractResult.sort(function (a, b) {
  //     return a.day - b.day;
  // })
  while (contractResult.length != 0) {
    let firstCourse = contractResult.shift()
    if (firstCourse == undefined) continue
    let weekTag = firstCourse.day
    for (
      let i = 0;
      contractResult[i] !== undefined && weekTag === contractResult[i].day;
      i++
    ) {
      if (
        firstCourse.sections.sort((a, b) => a - b).toString() ===
        contractResult[i].sections.sort((a, b) => a - b).toString() &&
        firstCourse.name === contractResult[i].name &&
        firstCourse.position === contractResult[i].position &&
        firstCourse.teacher === contractResult[i].teacher
      ) {
        firstCourse.weeks.push(contractResult[i].weeks[0])
        contractResult.splice(i, 1)
        i--
      }
    }
    finallyResult.push(firstCourse)
  }
  console.log(finallyResult)
  return finallyResult
}

function scheduleHtmlParser(html) {
  //除函数名外都可编辑
  //传入的参数为上一步函数获取到的html
  //可使用正则匹配
  //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
  //以下为示例，您可以完全重写或在此基础上更改
  let json = JSON.parse(html)
  let $ = cheerio.load(json.htmlStr, { decodeEntities: false })
  let result = []
  let message = ''
  try {
    if (json.tag === '1') {
      $('tbody tr').each(function (jcIndex, _) {
        $(this)
          .children('td')
          .each(function (day, _) {
            let kc = $(this).children('div[class="kbcontent"]')
            if (kc.text().length <= 6) {
              return
            }
           console.log(kc.html())
            kc.html().split(/-{4,}/).forEach(v => {
              let re = { weeks: [], sections: [] }
              // let kcco = kc.html().split(/<br>/)
              let kcco = v.split(/<br>/)
              let nameTag = true //判断课程名是否使用
              let nameAfter = 1 //判断课程名后面是否为干扰项
              kcco.forEach((con) => {
                console.log(con)
                $ = cheerio.load(con, { decodeEntities: false })
                console.log('%c %s', 'color:pink;', $.html())
                re.day = day + 1
                if ($.text().length == 0) return;
                let font = $('body').children('font')
                if (font.length > 1) {
                  //处理教室名中教学楼名重复
                  if (font.eq(0).attr('title') == '教学楼') {
                    let jxlName = font.eq(0).text().replace(/【|】/g, '')
                    console.log(jxlName)
                    console.log(font.eq(1).text().slice(jxlName.length))
                    if (
                      font.eq(1).text().slice(jxlName.length).search(jxlName) !== -1
                    ) {
                      font.eq(1).text(font.eq(1).text().slice(jxlName.length))
                    }
                  }

                  font = $('font').filter('[style!="display:none;"]')
                  console.log(font.length)
                  /**
                   * 过滤不显示的font 如：
                   * ...
                   * <br>
                   * <font title="教学楼" name="jxlmc" style="display:none;">【三教学楼】</font>
                   * <font title="教室">J3-205</font>
                   * <br>
                   * ...
                   */
                } else if (font.length === 1 && font.attr('style') !== undefined) {
                  /**
                   * 过滤干扰 font
                   * ...
                   * <br>
                   * <font name="xsks" color="black" style="display:none;">(理论:16,实践:16)</font>
                   * <br>
                   * ...
                   */
                  return
                }
                console.log(
                  '%c %s : %s',
                  'color:#0f0;',
                  !font.attr('title') ? '课程' : font.attr('title'),
                  $('body').text()
                )
                nameAfter += 1
                switch (
                !font.attr('title') && nameAfter > 1 ? '课程' : font.attr('title')
                ) {
                  case '课程':
                    if (nameTag) {
                      re.name = $('body').text()
                      re.name = re.name.replace(/\([a-z]+\d+.*?\)/, '')
                      nameTag = false
                      nameAfter = 0
                    } else {
                      // result.push(JSON.parse(JSON.stringify(re)))
                      // re = { weeks: [], sections: [] }
                      // nameTag = true
                    }

                    break
                  case '老师':
                    re.teacher = font.text()
                    break
                  case '教师':
                    re.teacher = font.text()
                    break
                  case '教室':
                    re.position = font.text()
                    break
                  case '教学楼':
                    re.position = font.text()
                    break
                  case '周次(节次)':
                    re.weeks = getWeeks(font.text().split('[')[0])
                    let jcStr = font.text().match(/(?<=\[).*?(?=\])/g)
                    //console.log(jcStr)
                    if (jcStr) re.sections = getSection(jcStr[0])
                    else {
                      for (let jie = jcIndex * 2 - 1; jie <= jcIndex * 2; jie++) {
                        //                                     let sec = {};
                        //                                     sec.section = jie;
                        re.sections.push(jie)
                      }
                    }
                    break
                }
              })
              result.push(JSON.parse(JSON.stringify(re)))
            })
          })
      })
    } else {

      $('tbody tr').each(function (jcIndex, _) {
        $(this)
          .children('td[align=left]')
          .each(function (day, _) {
            console.log("----------------------------")
            let div = $(this).children('div');
            let courseSize = div.children('p').length
            if (courseSize === 0) return;
            for (let i = 0; i < courseSize; i++) {
              let re = {}
              re.name = div.children('p').eq(i).text()
              console.log(div.children('p').eq(i).text())
              let sec = div.children('.tch-name').eq(i).children('span').eq(-1).text()
              re.sections = sec.replace(/节/g, '').split('~').map(v => Number(v))
              console.log(div.children('.tch-name').eq(i).children('span').eq(-1).text())

              let pos = div.children('.tch-name').eq(i).next().children('span').eq(0).text()
              re.position = !pos ? '' : pos.split('-').pop()
              console.log(div.children('.tch-name').eq(i).next().children('span').eq(0).text())
              let weekStr = div.children('.tch-name').eq(i).next().children('span').eq(1).text()
              let weeks = weekStr.split(' ')
              re.weeks = getWeeks(weeks[0])
              re.day = day + 1
              console.log(div.children('.tch-name').eq(i).next().children('span').eq(1).text())
              result.push(JSON.parse(JSON.stringify(re)))
            }
          })
      })
    }
    console.log(result)
    if (result.length === 0) message = '未获取到课表'
    else result = resolveCourseConflicts(result)
  } catch (err) {
    console.error(err)
    message = err.message.slice(0, 50)
  }
  if (message.length !== 0) {
    result.length = 0
    result.push({
      name: '遇到错误，请加qq群：628325112进行反馈',
      teacher: '开发者-萧萧',
      position: message,
      day: 1,
      weeks: [1],
      sections: [{ section: 1 }, { section: 2 }, { section: 3 }],
    })
  }

  console.log(result)
  return result
}

// Merged timer.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-06-26 08:37:03
 * @LastEditTime: 2022-06-26 08:37:03
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\强智教务\iframe强智\山东大学\timer.js
 * @QQ：357914968
 */
/**
 * @param  {object} xJConf 夏季时间
 * @param  {object} [dJConf] 冬季时间 可选参数
 * @returns {Array[{section:Number, startTime:String, endTime:String}]} 返回时间数组
 * @example
 *let Conf=
 {
       courseSum: 11,
       startTime: '800',
       oneCourseTime: 45,
       longRestingTime: 20,
       shortRestingTime: 10,
       longRestingTimeBegin: [2],
       lunchTime: {begin: 4, time: 2 * 60 + 50},
       dinnerTime: {begin: 8, time: 60},
       abnormalClassTime:[{begin:11,time:40}]
      }

 =>  getTimes(Conf) =>

 [
 { section: 1, startTime: '08:00', endTime: '08:45' },
 { section: 2, startTime: '08:55', endTime: '09:40' },
 { section: 3, startTime: '10:00', endTime: '10:45' },
 { section: 4, startTime: '10:55', endTime: '11:40' },
 { section: 5, startTime: '14:30', endTime: '15:15' },
 { section: 6, startTime: '15:25', endTime: '16:10' },
 { section: 7, startTime: '16:20', endTime: '17:05' },
 { section: 8, startTime: '17:15', endTime: '18:00' },
 { section: 9, startTime: '19:00', endTime: '19:45' },
 { section: 10, startTime: '19:55', endTime: '20:40' },
 { section: 11, startTime: '20:50', endTime: '21:30' }
 ]
 */
 function getTimes(xJConf, dJConf) {
  //xJConf : 夏季时间配置文件
  //dJConf : 冬季时间配置文件
  //return : Array[{},{}]
  dJConf = dJConf === undefined ? xJConf : dJConf;

  function getTime(conf) {
      let courseSum = conf.courseSum;  //课程节数 : 12
      let startTime = conf.startTime; //上课时间 :800
      let oneCourseTime = conf.oneCourseTime;  //一节课的时间
      let shortRestingTime = conf.shortRestingTime;  //小班空

      let longRestingTimeBegin = conf.longRestingTimeBegin; //大班空开始位置
      let longRestingTime = conf.longRestingTime;   //大班空
      let lunchTime = conf.lunchTime;     //午休时间
      let dinnerTime = conf.dinnerTime;    //下午休息
      let abnormalClassTime = conf.abnormalClassTime;      //其他课程时间长度
      let abnormalRestingTime = conf.abnormalRestingTime;    //其他休息时间

      let result = [];
      let studyOrRestTag = true;
      let timeSum = startTime.slice(-2) * 1 + startTime.slice(0, -2) * 60;

      let classTimeMap = new Map();
      let RestingTimeMap = new Map();
      if (abnormalClassTime !== undefined) abnormalClassTime.forEach(time => {
          classTimeMap.set(time.begin, time.time)
      });
      if (longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time => RestingTimeMap.set(time, longRestingTime));
      if (lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin, lunchTime.time);
      if (dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin, dinnerTime.time);
      if (abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => {
          RestingTimeMap.set(time.begin, time.time)
      });

      for (let i = 1, j = 1; i <= courseSum * 2; i++) {
          if (studyOrRestTag) {
              let startTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
              timeSum += classTimeMap.get(j) === undefined ? oneCourseTime : classTimeMap.get(j);
              let endTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
              studyOrRestTag = false;
              result.push({
                  section: j++,
                  startTime: startTime,
                  endTime: endTime
              })
          } else {
              timeSum += RestingTimeMap.get(j - 1) === undefined ? shortRestingTime : RestingTimeMap.get(j - 1);
              studyOrRestTag = true;
          }
      }
      return result;
  }

  let nowDate = new Date();
  let year = nowDate.getFullYear();                       //2020
  let wuYi = new Date(year + "/" + '05/01');           //2020/05/01
  let jiuSanLing = new Date(year + "/" + '09/30');     //2020/09/30
  let shiYi = new Date(year + "/" + '10/01');          //2020/10/01
  let nextSiSanLing = new Date((year + 1) + "/" + '04/30');    //2021/04/30
  let previousShiYi = new Date((year - 1) + "/" + '10/01');     //2019/10/01
  let siSanLing = new Date(year + "/" + '04/30');         //2020/04/30
  let xJTimes = getTime(xJConf);
  let dJTimes = getTime(dJConf);
  console.log("夏季时间:\n", xJTimes)
  console.log("冬季时间:\n", dJTimes)
  if (nowDate >= wuYi && nowDate <= jiuSanLing) {
      return xJTimes;
  } else if (nowDate >= shiYi && nowDate <= nextSiSanLing || nowDate >= previousShiYi && nowDate <= siSanLing) {
      return dJTimes;
  }
}
/**
* 时间配置函数，此为入口函数，不要改动函数名
*/
async function scheduleTimer() {



  let xJConf = {
      'courseSum': 12,
      'startTime': '800',
      'oneCourseTime': 50,
      'longRestingTime': 20,
      'shortRestingTime': 10,
      'longRestingTimeBegin': [2,6],
      'lunchTime': {begin: 4, time: 2 * 60},
      'dinnerTime': {begin: 8, time: 60}
//         'abnormalClassTime': [{begin: 10, time: 40}],
//         'abnormalRestingTime': [{begin: 11, time: 5}, {begin: 12, time: 5}]
  }
//     let dJConf = {
//         'courseSum': 11,
//         'startTime': '800',
//         'oneCourseTime': 45,
//         'longRestingTime': 20,
//         'shortRestingTime': 10,
//         'longRestingTimeBegin': [2],
//         'lunchTime': {begin: 4, time: 2 * 60 + 50},
//         'dinnerTime': {begin: 8, time: 60},
//         'abnormalClassTime': [{begin: 11, time: 40}],
//     }



return {
  totalWeek: 30, // 总周数：[1, 30]之间的整数
  startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
  startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
  showWeekend: false, // 是否显示周末
  forenoon: 5, // 上午课程节数：[1, 10]之间的整数
  afternoon: 4, // 下午课程节数：[0, 10]之间的整数
  night: 3, // 晚间课程节数：[0, 10]之间的整数
  sections: getTimes(xJConf), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
}
}
// PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人

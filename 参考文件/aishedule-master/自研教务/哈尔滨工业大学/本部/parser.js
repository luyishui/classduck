/**
 * @Author: xiaoxiao
 * @Date: 2022-08-26 21:18:41
 * @LastEditTime: 2022-08-27 00:48:46
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\哈尔滨工业大学\本部\parser.js
 * @QQ: 357914968
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
      .split('，')
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
  while (Str.search(/周|\s|,/) !== -1) {
    let index = Str.search(/周|\s|,/)
    if (Str[index + 1] === '单' || Str[index + 1] === '双') {
      week1.push(Str.slice(0, index + 2).replace(/周|\s|,/g, ''))
      index += 2
    } else {
      week1.push(Str.slice(0, index + 1).replace(/周|\s|,/g, ''))
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
 * @desc 尝试将冲突课程进行合并
 * @param result {object} 原始课程JSON
 * @returns {Array[]} 合并后JSON
 */
function resolveCourseConflicts(result) {
  let splitTag = '&' //重复课程之间的分割标识
  //将课拆成单节，并去重
  let allResultSet = new Set()
  result.forEach((singleCourse) => {
    singleCourse.weeks
      .sort((a, b) => a - b)
      .forEach((week) => {
        singleCourse.sections.forEach((value) => {
          let course = { sections: [], weeks: [] }
          course.name = singleCourse.name
          course.teacher =
            singleCourse.teacher == undefined ? '' : singleCourse.teacher
          course.position =
            singleCourse.position == undefined ? '' : singleCourse.position
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
          let index = firstCourse.name
            .split(splitTag)
            .indexOf(allResult[i].name)
          if (index === -1) {
            firstCourse.name += splitTag + allResult[i].name
            firstCourse.teacher += splitTag + allResult[i].teacher
            firstCourse.position += splitTag + allResult[i].position
            allResult.splice(i, 1)
            i--
          } else {
            let teacher = firstCourse.teacher.split(splitTag)
            let position = firstCourse.position.split(splitTag)
            teacher[index] =
              teacher[index] === allResult[i].teacher
                ? teacher[index]
                : teacher[index] + ',' + allResult[i].teacher
            position[index] =
              position[index] === allResult[i].position
                ? position[index]
                : position[index] + ',' + allResult[i].position
            firstCourse.teacher = teacher.join(splitTag)
            firstCourse.position = position.join(splitTag)
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
      }
    }
    finallyResult.push(firstCourse)
  }
  //将课程的周次进行合并
  contractResult = JSON.parse(JSON.stringify(finallyResult))
  finallyResult.length = 0
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

  let $ = cheerio.load(html, { decodeEntities: false })
  let result = []
  let message = ''
  try {
    $('tbody tr')
      .slice(1)
      .each(function (jcIndex, _) {
        $(this)
          .children('td')
          .slice(2)
          .each(function (day, _) {
            // console.log($(this).html())
            let kc = $(this)
            // if (kc.text().length <= 6) {
            //   return
            // }
            let re = { weeks: [], sections: [] }
            let kcco = kc
              .html()
              .split(/<br>/)
              .map((v) =>
                v
                  .replace(/\s/g, '')
                  .replace(/(<([^>]+)>)/gi, '')
                  .replace(/[\r\n]/g, '')
              )
              .filter((v) => v)
            console.log(kcco.length)
            let isName = true

            let isWeek = false
            let isJs = false
            kcco.forEach((con) => {
              if (isName) {
                console.log('课程名', con)
                re.name = con
                isName = false
                isWeek = true
              } else if (isWeek) {
                re.day = day + 1
                re.sections.push(2 * (jcIndex + 1))
                re.sections.push(2 * (jcIndex + 1) - 1)
                isWeek = false
                let weeks = con.match(/\[.*?\]/g)
                console.log('上课', getWeeks(weeks.toString()))
                re.weeks = getWeeks(weeks.toString())
                let isTeacher = con.split('[')[0]
                console.log('教师', isTeacher)
                re.teacher = isTeacher
                let mayBeJs = con.split('周')
                if (mayBeJs.length > 1 && !!mayBeJs[mayBeJs.length - 1]) {
                  console.log('教室', mayBeJs[mayBeJs.length - 1])
                  re.position = mayBeJs[mayBeJs.length - 1]
                  result.push(re)
                  re = { weeks: [], sections: [] }
                  isName = true
                } else {
                  isJs = true
                }
              } else if (isJs) {
                isJs = false
                let conLen = con.length
                let cons = con.split('')
                let endStr = cons[conLen - 1]
                if (
                  (endStr.search(/\d/) !== -1 && con.search(/\d{2,}/) !== -1) ||
                  endStr === '楼' ||
                  endStr === '室'
                ) {
                  console.log('教室', con)
                  re.position = con
                  result.push(re)
                  re = { weeks: [], sections: [] }
                  isName = true
                } else {
                  result.push(re)
                  re = { weeks: [], sections: [] }
                  re.name = con
                  console.log('课程名', con)
                  isWeek = true
                }
              }
            })
            if (re.weeks.length != 0) result.push(re)
          })
      })
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

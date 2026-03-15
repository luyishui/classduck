/**
 * @Author: xiaoxiao
 * @Date: 2022-09-18 19:57:55
 * @LastEditTime: 2022-09-18 21:14:14
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\新正方教务\山东师范大学\parser.js
 * @QQ: 357914968
 */
function resolveCourseConflicts(result) {
    let splitTag = '&'
    //将课拆成单节，并去重
    let allResultSet = new Set()
    result.forEach((singleCourse) => {
      singleCourse.weeks.forEach((week) => {
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
      //   console.log(firstCourse)
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
              // firstCourse.position = firstCourse.position.replace(/undefined/g, '')
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
              // firstCourse.position = firstCourse.position.replace(/undefined/g, '');
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
          // delete (contractResult[i])
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

function request(tag, data, url,anys) {
    if (anys==null) anys = false
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        console.log(xhr.readyState + " " + xhr.status);
        if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
            ss = xhr.responseText;
        }

    };
    xhr.open(tag, url, anys);
    xhr.setRequestHeader("X-Requested-With", "XMLHttpRequest");
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
    xhr.send(data);
    return ss;
}
function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    let message =""
    let result = []
    try{
        let studentId =  window.localStorage["ls.platformSysUserId"].replace(/"/g,"")
        let systemIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/portal/queryServiceTypes.htm"
        let systemId = JSON.parse(request("get",null,systemIdUrl)).result.filter(v=>{return v.name == "教务教学"})[0].serviceLevelMenuList.filter(v=>{return v.name == "查看课表"})[0].id
        let menuIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/portal/queryMenusOfService.htm?serviceId="+systemId
        let menuId = JSON.parse(request("get",null,menuIdUrl)).result.children.filter(v=>{return v.name =="我的课表"})[0].id
        let teamIdUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/commonDropDownListController/queryAllUseAbleTerms.htm"
        let termId = JSON.parse(request("get",null,teamIdUrl)).result.filter(v=>{return v.typeDesc=="当前学期"})[0].id


        let courseUrl = "http://dytyzj.aixiaoyuan.cn/ynedut/schoolTimetable/studentTimetable/getStudentTimetableData.htm"
        alert("准备就绪，受网络影响本次导入大概需要一些10s左右，点击确定开始导入，请等待！！！")
        for(let i = 1;i<=30;i++){
            console.log(i)
            let data = "termId="+termId+"&week="+i+"&studentId="+studentId+"&systemId="+systemId+"&menuId="+menuId
            let jsonText = request("post",data,courseUrl)
            let list = JSON.parse(jsonText).result.timeTableTimeTypeProcessVOList
            let jc=0
            list.forEach(con=>{
                let secs = con.timePeriodProcessVOList
                secs.forEach((sec,secIndex)=>{
                    jc++;
                    let courses = sec.knobProcessVOList
                    courses.forEach((weeks,weekIndx)=>{
                        if(!weeks.detailVOList) return
                        let couseInfo=weeks.detailVOList[0]
                        //                     console.log(jc,weekIndx+1,couseInfo)
                        result.push({
                            name:couseInfo.courseName,
                            teacher:couseInfo.teacherNames,
                            position:!couseInfo.classRoomNames?"":couseInfo.classRoomNames,
                            day:weekIndx+1,
                            sections:[jc],
                            weeks:[i]
                        })
                    })
                })
            })
            if(i==15) alert("已解析到第15周，点击确定继续解析。。。。")
        }
        if(result.length==0) message = "课表获取失败"
        else result = resolveCourseConflicts(result)
    } catch (err) {
        message = err.message.slice(0, 50);
    }
    if (message.length !== 0) {
        result.length = 0;
        result.push({
            name: "遇到错误，请加qq群：628325112进行反馈",
            teacher: "开发者-萧萧",
            position: message,
            day: 1,
            weeks: [1],
            sections: [1, 2,  3]
        });
    }
    return JSON.stringify(result)
}
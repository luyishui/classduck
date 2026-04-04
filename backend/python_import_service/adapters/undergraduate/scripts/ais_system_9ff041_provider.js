// Source: 参考文件/aishedule-master/树维/安徽科技学院/provider.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-09-01 08:47:07
 * @LastEditTime: 2022-09-13 18:08:32
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\树维\辅修-班级provider.js
 * @QQ: 357914968
 */
/**
 * loading函数
 * @param {*} param0
 */
function AIScheduleLoading({
  titleText = '加载中',
  contentText = 'loading...',
} = {}) {
  console.log('start......')
  AIScheduleComponents.addMeta()
  const title = AIScheduleComponents.createTitle(titleText)
  const content = AIScheduleComponents.createContent(contentText)
  const card = AIScheduleComponents.createCard([title, content])
  const mask = AIScheduleComponents.createMask(card)

  let dyn
  let count = 0
  function dynLoading() {
    if (count == 4) count = 0
    content.innerText = contentText + '.'.repeat(count++)
    // console.log(contentText + '.'.repeat(count))
  }

  this.show = () => {
    console.log('show......')
    document.body.appendChild(mask)
    dyn = setInterval(dynLoading, 1000)
  }
  this.close = () => {
    document.body.removeChild(mask)
    clearInterval(dyn)
  }
}
/**
 * 请求方法
 * @param {*} method
 * @param {*} data
 * @param {*} url
 * @param {*} text
 * @returns
 */
async function request(method, data, url, text) {
  let loading = null
  if (!!text) {
    loading = new AIScheduleLoading({ contentText: text })
    loading.show()
  }
  return await fetch(url, {
    method: method,
    body: data,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  })
    .then((v) => v.text())
    .then((v) => {
      !!loading && loading.close()
      return v
    })
    .catch((v) => {
      !!loading && loading.close()
      return v
    })
}
/*******
 * @description: 加载工具函数
 * @param {*} 需要加载工具的网址
 * @return {*}
 */
let loadTools = async (url) => {
  let jsStr = await request('get', null, url)
  console.log(jsStr)
  window.eval(jsStr)
}

function encrypt(content, key) {
  var sKey = AesJS.enc.Utf8.parse(key)
  var sContent = AesJS.enc.Utf8.parse(content)
  var encrypted = AesJS.AES.encrypt(sContent, sKey, {
    mode: AesJS.mode.ECB,
    padding: AesJS.pad.Pkcs7,
  })
  return encrypted.toString()
}

/*******
 * @description: 将html字符串转化为DOM
 * @param {*} text HTML字符串
 * @return {*} DOM
 */
let textToDom = (text) => {
  let parser = new DOMParser()
  return parser.parseFromString(text, 'text/html')
}

/*******
 * @description: 获取验证码,并将验证码添加到AISchedulePrompt中
 * @param {*} url 验证码url
 */
let addImg = (url) => {
  let addInterval = setInterval(addFun, '100')
  function addFun() {
    let aiDiv = document.getElementsByTagName('ai-schedule-div')
    if (aiDiv.length != 0) {
      let img = document.createElement('img')
      img.src = url
      img.style.cssText =
        'display: block; width: 50%; max-width: 200px; min-height: 11vw; max-height: 6vh; position: relative; overflow: auto; margin-top:0vh; padding: 2vw;'
      img.setAttribute('onclick', "this.src='" + url + "'")
      aiDiv[2].appendChild(img)
      clearInterval(addInterval)
    }
  }
}

/*******
 * @description: 登录教务
 * @param {*} sha sha加密密钥
 * @param {*} aes aes加密密钥
 * @param {*} dom 首页dom
 * @param {*} prul 网址前缀
 * @param {*} urls 网址配置
 * @return {*}
 */
async function doLogin(sha, aes, dom, prul, urls) {
  let username = ''
  let pas = ''

  if (!!document.getElementById('username')) {
    username = document.getElementById('username').value
    pas = document.getElementById('password').value
  }

  username = !username
    ? await AISchedulePrompt({
        titleText: '请输入用户名',
        tipText: '',
        defaultText: '',
        validator: (username) => {
          if (!username) return '用户名输入有误'
          else return false
        },
      })
    : username
  pas = !pas
    ? await AISchedulePrompt({
        titleText: '请输入密码',
        tipText: '',
        defaultText: '',
        validator: (password) => {
          if (!password) return '密码输入有误'
          else return false
        },
      })
    : pas
  pas = CryptoJS.SHA1(sha + pas)
  //username = encrypt(username,aes)
  let data =
    'username=' +
    username +
    '&password=' +
    pas +
    '&pwd=' +
    pas +
    '&encodedPassword=' +
    '&session_locale=zh_CN'

  let vim = dom.getElementsByClassName('verity-image')
  let cr = dom.getElementsByClassName('captcha_response')
  if (vim.length != 0 || cr.length != 0) {
    addImg(
      !vim.length ? cr[0].nextElementSibling.src : vim[0].childNodes[0].src
    )
    data +=
      '&captcha_response=' +
      (await AISchedulePrompt({
        titleText: '请输入页面验证码',
        tipText: '',
        defaultText: '',
        validator: (yzm) => {
          if (!yzm) return '验证码输入有误'
          else return false
        },
      }))
  }

  let logRe = await request('post', data, prul + urls.login, '登录中')
  console.log(logRe)
  let tdom = textToDom(logRe)
  let errtext = tdom.getElementsByClassName('actionError')
  if (!!errtext.length) {
    await AIScheduleAlert({
      contentText: errtext[0].innerText + '>>>请退出重新进入<<<',
      titleText: '错误',
      confirmText: '确认',
    })
    return ''
  }
  console.info('登录中。。。')
  return getSjarr(prul)
}

function sleep(timeout) {
  for (let t = Date.now(); Date.now() - t <= timeout * 1000; );
}

/*******
 * @description: 获取学期ID
 * @param {*} preUrl 网址前缀
 * @param {*} courseTableCon 含有tagid的html
 * @return {*} 含有当前年份的学期，被选择学期的index
 */
async function getSemestersId(preUrl, courseTableCon) {
  let semesterIds = []
  let mess = ''
  let xqurl = preUrl + '/dataQuery.action'

  let data =
    'tagId=' +
    'semesterBar' +
    courseTableCon.match(/(?<=semesterBar).*?(?=Semester)/)[0] +
    'Semester' +
    '&dataType=semesterCalendar&value=' +
    courseTableCon.match(/(?<=value:").*?(?=")/)[0] +
    '&empty=false'

  let currentYear = new Date().getFullYear()
  let semesters = eval(
    '(' + (await request('post', data, xqurl, '加载学期中')) + ')'
  ).semesters
  let count = 0
  let semesterIndexTag = 0
  let selectList = []
  console.log(semesters)

  for (key in semesters) {
    if (semesters[key][0].schoolYear.search(currentYear) != -1) {
      for (let key1 in semesters[key]) {
        let semId = semesters[key][key1]
        selectList.push(
          semesterIndexTag++ +
            ':' +
            semId['schoolYear'] +
            '学年' +
            semId['name'] +
            '学期'
        )
        semesterIds.push(semesters[key][key1]['id'])
      }
      if (++count == 2) break
    }
  }

  let semesterIndex = (
    await AIScheduleSelect({
      titleText: '学期',
      contentText: '请选择当前学期',
      selectList: selectList,
    })
  ).split(':')[0]

  console.log(semesterIndex)
  return {
    semesterIds: semesterIds,
    semesterIndex: semesterIndex,
  }
}
/**
 * 判断是否有辅修
 * @param {*} courseTableCon
 */
async function isFx(preUrl) {
  let fxs = await request(
    'get',
    null,
    preUrl + '/dataQuery.action',
    '检查是否有辅修课程'
  )
  let doms = textToDom(fxs)
  let ops = doms.getElementsByTagName('option')
  if (ops.length <= 1) {
    return ops[0].value
  } else {
    let selectList = []
    for (let i = 0; i < ops.length; i++) {
      selectList.push(ops[i].value + ':' + ops[i].innerText)
    }
    let kbIndex = (
      await AIScheduleSelect({
        titleText: '课表',
        contentText: '请选择需要导出的课表',
        selectList: selectList,
      })
    ).split(':')[0]
    return kbIndex
  }
}

/*******
 * @description: 解析出课程信息
 * @param {*} preUrl 网址前缀
 * @return {*} 课程数组
 */
async function getSjarr(preUrl) {
  sleep(0.35)
  let kbIndx = await isFx(preUrl)
  let fxurl =
    preUrl +
    '/courseTableForStd!index.action?projectId=' +
    kbIndx +
    '&_=' +
    new Date().getTime()
  // let idurl = preUrl + '/courseTableForStd.action'
  let idurl =
    preUrl +
    '/courseTableForStd!innerIndex.action?projectId=' +
    kbIndx +
    '&_=' +
    new Date().getTime()

  // 用来解决无法切换课表
  await request('get', null, fxurl)

  let courseTableCon = await request('get', null, idurl, '加载课表中')

  console.info('获取学期中。。。')
  let semIdsJson = await getSemestersId(preUrl, courseTableCon)
  console.log(semIdsJson.semesterIds)

  let ids = courseTableCon.match(
    /(?<=bg.form.addInput\(form,"ids",").*?(?="\);)/g
  )
  console.log(ids)
  let kbTypeIndex = 0
  if (ids.length == 2) {
    kbTypeIndex = (
      await AIScheduleSelect({
        titleText: '课表类型',
        contentText: '请选择需要导出的课表类型',
        selectList: ['0:学生课表', '1:班级课表'],
      })
    ).split(':')[0]
  }
  console.info('获取ids中。。。')
  if (ids == null) {
    alert('ids匹配有误')
    return
  }
  console.info('获取到ids', ids[kbTypeIndex])

  let courseArr = []
  let i = semIdsJson.semesterIndex
  while (courseArr.length <= 1 && i >= 0) {
    sleep(0.4)
    console.info('正在查询课表', semIdsJson.semesterIds[i])
    let kbType = ['std', 'class']

    let data1 = `ignoreHead=1&setting.kind=${kbType[kbTypeIndex]}&startWeek=&semester.id=${semIdsJson.semesterIds[i]}&ids=${ids[kbTypeIndex]}`

    let url = preUrl + '/courseTableForStd!courseTable.action'
    courseArr = (await request('post', data1, url, '解析课表中')).split(
      /var teachers = \[.*?\];/
    )

    /**
     * 版本二
     */
    // courseArr = (await request("post", data2, url)).split(/activity = new /);
    i--
  }
  return courseArr
}

function distinct(arr) {
  return Array.from(new Set(arr))
}

async function scheduleHtmlProvider(
  iframeContent = '',
  frameContent = '',
  dom = document
) {
  let tags = 0
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  await loadTool('AIScheduleTools')
  let warning = `
  >>>导入流程<<<
  1、通过统一身份认证平台登录系统
  2、在空白页面，点击一键导入
  3、大概需要等待5秒左右，导入完成后会自动跳转
  注意：导入完成后，注意检查时间和课程是否正确！！！      
  `
  await AIScheduleAlert(warning)

  let message = ''
  //alert("请确保你已经连接到校园网！！")
  let urlar = location.href.split('/')
  !urlar[urlar.length - 1] && urlar.pop()
  let verTag = urlar.pop()
  let preUrl = urlar.slice(0, urlar.indexOf('eams') + 1).join('/') //处理不在主页
  let urls1 = {
    home: '/homeExt.action',
    login: '/loginExt.action',
    loginTableClassName: 'login-table',
  }
  let urls2 = {
    home: '/home.action',
    login: '/login.action',
    loginTableClassName: 'logintable',
  }
  /**
   * 在首页时，会没有登录标识，会导致登录失败
   * 需要去解决
   */
  let urls = verTag.search('Ext') === -1 ? urls2 : urls1
  let courseArr = []
  let arr = []
  try {
    //验证是否登录
    let homeText = await request('get', null, preUrl + urls.home, '登录验证中')
    let homeDom = textToDom(homeText)
    let logintag = homeDom.getElementsByClassName(
      urls.loginTableClassName
    ).length

    sleep(0.5)
    if (location.href.search('sso/login') != -1) {
      await AIScheduleAlert('请登录。。。')
      return 'do not continue'
    } else if (!logintag && location.href.search(preUrl + urls.login) == -1) {
      arr = await getSjarr(preUrl)
    } else {
      await loadTools('/eams/static/scripts/sha1.js')
      //  await loadTools("/eams/static/scripts/aes.min.js")

      let sha = homeText.match(/(?<=CryptoJS\.SHA1\(').*?(?=')/)[0]
      let aes = null
      //  let aes =  homeText.match(/(?<=encrypt\(username,').*?(?=')/)[0];

      arr = await doLogin(sha, aes, homeDom, preUrl, urls)
      if (!arr) {
        return 'do not continue'
      }
    }
    if (arr.length >= 1) {
      arr.slice(1).forEach((courseText) => {
        let course = { weeks: [], sections: [] }
        console.log(courseText)
        let orArr = courseText.match(
          /(?<=actTeacherName.join\(','\),).*?(?=\);)/g
        )
        let day = distinct(courseText.match(/(?<=index \=).*?(?=\*unitCount)/g))
        let section = distinct(courseText.match(/(?<=unitCount\+).*?(?=;)/g))
        let teacher = distinct(courseText.match(/(?<=name:").*?(?=")/g))
        console.log(orArr, day, section, teacher)
        let courseCon = orArr[0].split(/(?<="|l|e),(?="|n|a)/)
        console.log(courseCon)
        course.courseName = courseCon[1].replace(/"/g, '')
        course.roomName = courseCon[3].replace(/"/g, '')
        course.teacherName = teacher.join(',')
        courseCon[4] = courseCon[4].split(',')[0].replace('"', '')
        courseCon[4].split('').forEach((em, index) => {
          if (em == 1) course.weeks.push(index)
        })
        course.day = Number(day) + 1
        section.forEach((con) => {
          course.sections.push(Number(con) + 1)
        })
        console.log(course)
        courseArr.push(course)
      })

      /**
       * 版本二
       */
      // arr.slice(1).forEach(courseText => {
      //     let course = { weeks: [], sections: [] };
      //     console.log(courseText)
      //     let orArr = courseText.match(/(?<=TaskActivity\().*?(?=\);)/g);
      //     let day = distinct(courseText.match(/(?<=index \=).*?(?=\*unitCount)/g));
      //     let section = distinct(courseText.match(/(?<=unitCount\+).*?(?=;)/g));
      //     let courseCon = orArr[0].split(/","/)
      //     console.log(orArr, day, section, courseCon[1])
      //     console.log(courseCon)
      //     course.courseName = courseCon[3]
      //     course.roomName = courseCon[5]
      //     course.teacherName =courseCon[1]
      //     courseCon[6] = courseCon[6].replace('"', "")
      //     courseCon[6].split("").forEach((em, index) => {
      //         if (em == 1) course.weeks.push(index);
      //     })
      //     course.day = Number(day) + 1;
      //     section.forEach(con => {
      //         course.sections.push(Number(con) + 1)
      //     })
      //     console.log(course)
      //     courseArr.push(course)
      // })

      if (courseArr.length == 0) message = '未获取到课表'
    } else {
      message = '未获取到课表'
    }
  } catch (e) {
    console.log(e)
    message = e.message.slice(0, 50)
  }
  if (message.length != 0) {
    courseArr.length = 0
    let errText = `
      遇到错误，请凭此页面截图，加群:628325112,找开发者进行反馈
      错误：${message},
      url:${preUrl}
      `
    AIScheduleAlert({
      contentText: errText,
      titleText: '错误',
      confirmText: '我已知晓',
    })
    return 'do not continue'
  }
  // console.log(courseArr)
  // alert("provider执行成功")
  //处理特殊字符
  return JSON.stringify(courseArr).replace(/`/g, '')
}

// Merged parser.js

/**
 * @Author: xiaoxiao
 * @Date: 2022-06-10 11:57:49
 * @LastEditTime: 2022-06-10 11:57:50
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\树维\广州工商学院\parser.js
 * @QQ：357914968
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
  ).sort(function (b, e) {
    // return b.day - e.day;
    return b.day - e.day || b.sections[0] - e.sections[0]
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
  //  contractResult = contractResult.sort(function (a, b) {
  //      return (a.day - b.day)||(a.sections[0]-b.sections[0]);
  //   })
  // console.log("111111111", JSON.parse(JSON.stringify(contractResult)))
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
  //  console.log("合并后", JSON.parse(JSON.stringify(finallyResult)))
  contractResult = JSON.parse(JSON.stringify(finallyResult))
  finallyResult.length = 0
  //    contractResult = contractResult.sort(function (a, b) {
  //        return a.day - b.day;
  //    })
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
        firstCourse.sections
          .sort((a, b) => {
            return a - b
          })
          .toString() ===
          contractResult[i].sections
            .sort((a, b) => {
              return a - b
            })
            .toString() &&
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
  let result = []
   let jss =  JSON.parse(html)   
   console.log(jss)
  jss.forEach(v =>{
      let re = {weeks:[],sections:[]} ; 
      re.name = v.courseName.split("(")[0];
      re.position = v.roomName;
      re.day = v.day
      re.teacher = v.teacherName
      re.weeks = v.weeks
      re.sections = v.sections
      result.push(re)
  })
 return  resolveCourseConflicts(result)
 // return { courseInfos: result}
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
  // 内嵌loadTool工具，传入工具名即可引用公共工具函数(暂未确定公共函数，后续会开放)
  await loadTool('AIScheduleTools')
  const { AIScheduleAlert } = AIScheduleTools()
  // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
//  await AIScheduleAlert('liuwenkiii yyds!')
//   // 支持异步操作 推荐await写法
//   const someAsyncFunc = () => new Promise(resolve => {
//     setTimeout(() => resolve(), 100)
//   })  
//   await someAsyncFunc()
  // 返回时间配置JSON，所有项都为可选项，如果不进行时间配置，请返回空对象
  return {
    totalWeek: 30, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: true, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 4, // 晚间课程节数：[0, 10]之间的整数
    sections: getTimes({
                        courseSum : 12,
                        startTime  : '0800',
                        oneCourseTime : 45,
                        longRestingTime  : 20,
                        shortRestingTime : 10,
                        longRestingTimeBegin:[2,6],
                        lunchTime  : {begin:4,time:2*60+20},
                        dinnerTime : {begin:8,time:80},
                    //     abnormalClassTime:[],
                    //     abnormalRestingTime:[]
                      }), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

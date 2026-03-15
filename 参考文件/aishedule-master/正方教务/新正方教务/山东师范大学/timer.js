/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function timeRequest (tag, data, url) {
  return await fetch(url, {
    method: tag,
    body: data,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  })
    .then((rp) => rp.json())
    .then((v) => v)
}
async function scheduleTimer ({ providerRes, parserRes } = {}) {
  try {
    let res = JSON.parse(providerRes)
    if (res.xnm && !res.xqm) {
      console.log(res.xnm)
      return {}
    } else {
      let times = await timeRequest(
        'post',
        'xnm=' +
        res.xnm +
        '&xqm=' +
        res.xqm +
        '&xqh_id=' +
        res.listArr[0].xqh_id,
        '/jwglxt/jzgl/skxxMobile_cxRsdjc.html'
      )

      let timeJson = {
        totalWeek: 24, // 总周数：[1, 30]之间的整数
        startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
        startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
        showWeekend: true, // 是否显示周末
        forenoon: 4, // 上午课程节数：[1, 10]之间的整数
        afternoon: 4, // 下午课程节数：[0, 10]之间的整数
        night: 2, // 晚间课程节数：[0, 10]之间的整数
        sections: [],
      }
      times.forEach((element) => {
        timeJson.sections.push({
          section: element.jcmc,
          startTime: element.qssj.slice(0, -3),
          endTime: element.jssj.slice(0, -3),
        })
      })
      timeJson.night = times.length - timeJson.forenoon - timeJson.afternoon

      console.log(timeJson)
      if (timeJson.sections.length == 0) timeJson = {}
      return timeJson
    }
  } catch (e) {
    console.error(e)
    return {}
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

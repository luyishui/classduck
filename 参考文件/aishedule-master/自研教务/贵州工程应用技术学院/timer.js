/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer({providerRes}) {

  let allJson = JSON.parse(providerRes)
  let res = allJson.startTimeJson

  console.log(res)
  let result = []


  let morning = 0;
  let afternon = 0;
  let night = 0;




  res.forEach(re=>{
    switch(re.dayPart){
      case "MORNING": morning++;break;
      case "AFTERNOON": afternon++;break;
      case "EVENING": night++;break;
    }

    re.startTime =  '' +re.startTime

    re.endTime =  ''+re.endTime


    result.push({
      section:re.segmentIndex,
      startTime:re.startTime.length===3?'0'+re.startTime.slice(0,1)+':'+re.startTime.slice(1):re.startTime.slice(0,2)+':'+re.startTime.slice(2),
      endTime:re.endTime.length===3?'0'+re.endTime.slice(0,1)+':'+re.endTime.slice(1):re.endTime.slice(0,2)+':'+re.endTime.slice(2)
    })
  })

  return {
    'totalWeek': 20, // 总周数：[1, 30]之间的整数
    'startSemester': '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    'startWithSunday': false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    'showWeekend': false, // 是否显示周末
    'forenoon': morning, // 上午课程节数：[1, 10]之间的整数
    'afternoon': afternon, // 下午课程节数：[0, 10]之间的整数
    'night': night, // 晚间课程节数：[0, 10]之间的整数
    'sections':result, // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

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
        'courseSum': 13,
        'startTime': '800',
        'oneCourseTime': 45,
        'longRestingTime': 20,
        'shortRestingTime': 5,
        'longRestingTimeBegin': [2, 7],
        'lunchTime': {begin: 5, time: 50},
        'dinnerTime': {begin: 10, time: 50},
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
        afternoon: 5, // 下午课程节数：[0, 10]之间的整数
        night: 3, // 晚间课程节数：[0, 10]之间的整数
        sections: getTimes(xJConf), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
    }
// PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}

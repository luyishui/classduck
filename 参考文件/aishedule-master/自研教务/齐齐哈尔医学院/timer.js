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
  //   let time1 = {
  //     courseSum: 12,
  //     startTime: '0810',
  //     oneCourseTime: 45,
  //     longRestingTime: 25,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 3 * 60-15 },
  //     dinnerTime: { begin: 10, time: 10 },
  //     abnormalClassTime:[{begin:3,time:40},{begin:4,time:40}],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:5,time:10},{begin:6,time:15},{begin:8,time:10}]
  // }
  // let time2 = {
  //     courseSum: 12,
  //     startTime: '0810',
  //     oneCourseTime: 45,
  //     longRestingTime: 35,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 2 * 60+15 },
  //     dinnerTime: { begin: 10, time: 10 },
  //     abnormalClassTime:[],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:10},{begin:5,time:10},{begin:6,time:15},{begin:8,time:10}]
  // }
  // let time3 = {
  //     courseSum: 12,
  //     startTime: '0830',
  //     oneCourseTime: 45,
  //     longRestingTime: 30,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 1 * 60+50 },
  //     dinnerTime: { begin: 10, time: 20 },
  //     abnormalClassTime:[],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:5},{begin:5,time:5},{begin:6,time:20},{begin:8,time:60}]
  // }
  // let time4 = {
  //     courseSum: 12,
  //     startTime: '0830',
  //     oneCourseTime: 45,
  //     longRestingTime: 20,
  //     shortRestingTime: 0,
  //     longRestingTimeBegin: [2],
  //     lunchTime: { begin: 4, time: 1 * 60+75 },
  //     dinnerTime: { begin: 10, time: 20 },
  //     abnormalClassTime:[{begin:3,time:40},{begin:4,time:40}],
  //     abnormalRestingTime: [{begin:1,time:5},{begin:3,time:0},{begin:5,time:5},{begin:6,time:20},{begin:8,time:60}]
  // }
  
    // 内嵌loadTool工具，传入工具名即可引用公共工具函数(暂未确定公共函数，后续会开放)
    await loadTool('AIScheduleTools')
    const { AISchedulePrompt } = AIScheduleTools()
  //   // 只要大声喊出 liuwenkiii yyds 就可以保你代码不出bug
  //   await AIScheduleAlert('liuwenkiii yyds!')
  //   // 支持异步操作 推荐await写法
  //   const someAsyncFunc = () => new Promise(resolve => {
  //     setTimeout(() => resolve(), 100)
  //   })  
  //   await someAsyncFunc()
    // 返回时间配置JSON，所有项都为可选项，如果不进行时间配置，请返回空对象
  //   let mess =
  //   `
  // 时间一（1）: 天河-9#,10#,12#,图书馆,加工车间,公路楼,汽车实训楼
  // 时间一（1）: 花都-1#,图书馆
  // 时间二（2）: 天河-2#,运动场
  // 时间二（2）: 花都-10#,15#,16#,运动场
  // 时间三（3）: 清远-立业16#,求是18#,笃实19#,运动场
  // 时间四（4）: 清远-融创13#,创新17#
  
   // `
  //  let tag =  await AISchedulePrompt({titleText:"请选择时间",tipText:mess,defaultText:"1",validator:value=>{if(value ==1||value ==2||value ==3||value ==4) return false;else return "请输入1,2,3,4"}})
  //  let times; 
  //  console.log
  //  switch(Number(tag)){
  //    case 1:times = getTimes(time1);break;
  //    case 2:times = getTimes(time2);break;
  //    case 3:times = getTimes(time3);break;
  //    case 4:times = getTimes(time4);break;
  //    default: console.error(tag);
  //  }
    return {
      totalWeek: 20, // 总周数：[1, 30]之间的整数
      startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
      startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
      showWeekend: false, // 是否显示周末
      forenoon: 4, // 上午课程节数：[1, 10]之间的整数
      afternoon: 4, // 下午课程节数：[0, 10]之间的整数
      night: 4, // 晚间课程节数：[0, 10]之间的整数
      sections: getTimes({
        courseSum: 12,
        startTime: '800',
        oneCourseTime: 45,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2],
        lunchTime: {begin: 4, time: 2 * 60 - 10},
        dinnerTime: {begin: 8, time: 60},
    }), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
    }
    // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
  }
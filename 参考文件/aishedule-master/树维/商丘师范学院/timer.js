function getTimes(){

    let xJTimes = [
        {
            "section": 1,
            "startTime": "08:00",
            "endTime": "08:50"
        },
        {
            "section": 2,
            "startTime": "09:00",
            "endTime": "09:50"
        },
        {
            "section": 3,
            "startTime": "10:10",
            "endTime": "11:00"
        },
        {
            "section": 4,
            "startTime": "11:10",
            "endTime": "12:00"
        },
        {
            "section": 5,
            "startTime": "14:30",
            "endTime": "15:20"
        },
        {
            "section": 6,
            "startTime": "15:30",
            "endTime": "16:20"
        },
        {
            "section": 7,
            "startTime": "16:30",
            "endTime": "17:20"
        },
        {
            "section": 8,
            "startTime": "17:30",
            "endTime": "18:20"
        },
        {
            "section": 9,
            "startTime": "19:00",
            "endTime": "19:30"
        },{
            "section": 10,
            "startTime": "19:30",
            "endTime": "20:00"
        },{
            "section": 11,
            "startTime": "20:00",
            "endTime": "21:30"
        }
    ]
    let dJTimes = [
        {
            "section": 1,
            "startTime": "08:00",
            "endTime": "08:50"
        },
        {
            "section": 2,
            "startTime": "09:00",
            "endTime": "09:50"
        },
        {
            "section": 3,
            "startTime": "10:10",
            "endTime": "11:00"
        },
        {
            "section": 4,
            "startTime": "11:10",
            "endTime": "12:00"
        },
        {
            "section": 5,
            "startTime": "15:00",
            "endTime": "15:50"
        },
        {
            "section": 6,
            "startTime": "16:00",
            "endTime": "16:50"
        },
        {
            "section": 7,
            "startTime": "17:00",
            "endTime": "17:50"
        },
        {
            "section": 8,
            "startTime": "18:00",
            "endTime": "18:50"
        },
        {
            "section": 9,
            "startTime": "19:30",
            "endTime": "20:00"
        },
        {
            "section": 10,
            "startTime": "20:00",
            "endTime": "20:50"
        },
        {
            "section": 11,
            "startTime": "20:50",
            "endTime": "21:50"
        }
    ];

    let nowDate = new Date();
    let year = nowDate.getFullYear();                       //2020
    let wuYi = new Date(year+"/"+'05/01');           //2020/05/01
    let jiuSanLing = new Date(year+"/"+'09/30');     //2020/09/30
    let shiYi = new Date(year+"/"+'10/01');          //2020/10/01
    let nextSiSanLing = new Date((year+1)+"/"+'04/30');    //2021/04/30
    let previousShiYi = new Date((year-1)+"/"+'10/01');     //2019/10/01
    let siSanLing = new Date(year+"/"+'04/30');         //2020/04/30
  
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
    night: 3, // 晚间课程节数：[0, 10]之间的整数
    sections: getTimes(), // 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}
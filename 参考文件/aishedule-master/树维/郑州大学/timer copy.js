/**
 * @Author: xiaoxiao
 * @Date: 2022-03-15 18:40:09
 * @LastEditTime: 2022-03-30 18:55:06
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\树维\郑州大学\timer copy.js
 * @QQ：357914968
 */

let updateText = () =>{
    let addInterval = setInterval(addFun,"100")
    function addFun () {
        let aiDiv = document.getElementsByTagName("ai-schedule-div")
        if(aiDiv.length!=0){
            aiDiv[4].innerText="请选择";
            aiDiv[6].innerText="确定";
            clearInterval(addInterval)
        }
    }
}

/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer() {


  return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: false, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 3, // 晚间课程节数：[0, 10]之间的整数
    sections:  [
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
            "startTime": "14:00",
            "endTime": "14:50"
        },
        {
            "section": 6,
            "startTime": "15:00",
            "endTime": "15:50"
        },
        {
            "section": 7,
            "startTime": "16:00",
            "endTime": "16:50"
        },
        {
            "section": 8,
            "startTime": "17:00",
            "endTime": "17:50"
        },
        {
            "section": 9,
            "startTime": "19:30",
            "endTime": "20:20"
        },
        {
            "section": 10,
            "startTime": "20:30",
            "endTime": "21:20"
        },
        {
            "section": 11,
            "startTime": "21:30",
            "endTime": "22:20"
        }
    ]// 课程时间表，注意：总长度要和上边配置的节数加和对齐
  }
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}


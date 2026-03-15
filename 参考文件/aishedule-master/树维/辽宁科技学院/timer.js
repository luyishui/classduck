/**
 * @Author: xiaoxiao
 * @Date: 2022-06-10 11:58:01
 * @LastEditTime: 2022-08-17 15:54:35
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\树维\辽宁科技学院\timer.js
 * @QQ：357914968
 */
async function scheduleTimer() {
  return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: true, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 2, //
    sections: [
      {
        section: 1,
        startTime: '08:00',
        endTime: '09:15',
      },
      {
        section: 2,
        startTime: '09:20',
        endTime: '10:05',
      },
      {
        section: 3,
        startTime: '10:25',
        endTime: '11:10',
      },
      {
        section: 4,
        startTime: '11:15',
        endTime: '12:00',
      },
      {
        section: 5,
        startTime: '13:20',
        endTime: '14:05',
      },
      {
        section: 6,
        startTime: '14:10',
        endTime: '14:55',
      },
      {
        section: 7,
        startTime: '15:05',
        endTime: '15:55',
      },
      {
        section: 8,
        startTime: '15:55',
        endTime: '16:25',
      },
      {
        section: 9,
        startTime: '17:30',
        endTime: '18:15',
      },
      {
        section: 10,
        startTime: '18:15',
        endTime: '19:00',
      }
      // ,
      // {
      //   section: 11,
      //   startTime: '19:00',
      //   endTime: '19:45',
      // },
      // {
      //   section: 12,
      //   startTime: '19:45',
      //   endTime: '20:30',
      // },
    ],
  }
}

/**
 * @Author: xiaoxiao
 * @Date: 2022-06-10 11:58:01
 * @LastEditTime: 2022-08-17 15:54:35
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\树维\广州工商学院\timer.js
 * @QQ：357914968
 */
async function scheduleTimer() {
  return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: true, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 6, // 下午课程节数：[0, 10]之间的整数
    night: 2, //
    sections: [
      {
        section: 1,
        startTime: '08:20',
        endTime: '09:05',
      },
      {
        section: 2,
        startTime: '09:05',
        endTime: '09:50',
      },
      {
        section: 3,
        startTime: '10:05',
        endTime: '10:50',
      },
      {
        section: 4,
        startTime: '10:50',
        endTime: '11:35',
      },
      {
        section: 5,
        startTime: '12:20',
        endTime: '13:05',
      },
      {
        section: 6,
        startTime: '13:05',
        endTime: '13:50',
      },
      {
        section: 7,
        startTime: '14:00',
        endTime: '14:45',
      },
      {
        section: 8,
        startTime: '14:45',
        endTime: '15:30',
      },
      {
        section: 9,
        startTime: '15:45',
        endTime: '16:30',
      },
      {
        section: 10,
        startTime: '16:30',
        endTime: '17:15',
      },
      {
        section: 11,
        startTime: '19:00',
        endTime: '19:45',
      },
      {
        section: 12,
        startTime: '19:45',
        endTime: '20:30',
      },
    ],
  }
}

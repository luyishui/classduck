/*
 * @Author: xiaoxiao
 * @Date: 2023-02-16 17:08:29
 * @LastEditors: xiaoxiao
 * @LastEditTime: 2023-02-16 17:27:54
 * @Description: 
 */
async function scheduleTimer() {
  return {
    totalWeek: 24, // 总周数：[1, 30]之间的整数
    startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
    startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
    showWeekend: true, // 是否显示周末
    forenoon: 4, // 上午课程节数：[1, 10]之间的整数
    afternoon: 4, // 下午课程节数：[0, 10]之间的整数
    night: 4, //
    sections: [
      {
        section: 1,
        startTime: '08:20',
        endTime: '09:05',
      },
      {
        section: 2,
        startTime: '09:10',
        endTime: '09:55',
      },
      {
        section: 3,
        startTime: '10:10',
        endTime: '10:55',
      },
      {
        section: 4,
        startTime: '11:00',
        endTime: '11:45',
      },
      {
        section: 5,
        startTime: '12:55',
        endTime: '13:45',
      },
      {
        section: 6,
        startTime: '13:55',
        endTime: '14:30',
      },
      {
        section: 7,
        startTime: '14:45',
        endTime: '15:30',
      },
      {
        section: 8,
        startTime: '15:35',
        endTime: '16:20',
      },
      {
        section: 9,
        startTime: '17:00',
        endTime: '17:45',
      },
      {
        section: 10,
        startTime: '17:50',
        endTime: '18:35',
      },
      {
        section: 11,
        startTime: '18:40',
        endTime: '19:25',
      },
      {
        section: 12,
        startTime: '19:30',
        endTime: '20:15',
      },
    ],
  }
}

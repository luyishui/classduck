/**
 * @Author: xiaoxiao
 * @Date: 2022-03-01 19:22:48
 * @LastEditTime: 2022-10-05 14:43:55
 * @LastEditors: xiaoxiao
 * @Description:
 * @FilePath: \AISchedule\小爱测试\parser.js
 * @QQ: 357914968
 */
function scheduleHtmlParser(html) {
  var jsonArray = []

  var $ = cheerio.load(html, {
    decodeEntities: false,
  })

  var names, day, teacher, position, sections

  //分化去逐个输入
  $('#simple-table > tbody > tr > td').each(function () {
    //name

    names = $(this).html().split(':')[7]
    //teacher

    teacher = $(this).html().split(':')[5].split('???') //这里就不能再加一个裁切了

    // position
    position = $(this).html().split('<br>')[0].split(':')[2]
    //weeks//:selected
    // for (let index = 0; index < $("#ddl_周数 option").length; index++) {
    //     week[index] = $("#ddl_周数").children[index].text();

    // }
    weeks = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17] //$("#ddl_周数 option:selected").text();
    //day
    day = $(this).index()

    //sectionsr

    sections = $(this).html().split('<br>')[1]

    // if ($("#simple-table tbody").find("tr:nth-child(1) td:nth-child(1)").text() == "上午") {
    //     if ($("#simple-table tbody").find("tr:nth-child(2) td:nth-child(1)").text() == "上午") {
    //         sections = [1, 2]
    //     } else { sections = [1, 2, 3, 4] }

    // } else {
    //     if ($("#simple-table tbody").find("tr:nth-child(2) td:nth-child(1)").text() == "下午") {
    //         sections = [5, 6]
    //     }else{
    //         sections = [5, 6,7,8]
    //     }
    // }

    var obj = {
      name: names,
      position: position,
      teacher: teacher,
      weeks: weeks,
      day: day,
      sections: sections,
      // token: token
    }
    // $(this)!=$(this).find("td:nth-child(1)")

    if (day != 0 && $(this).text() != '') {
      jsonArray.push(obj)
    }
  })

  return jsonArray
}

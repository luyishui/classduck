/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
 async function scheduleTimer() {

  let providerJSON = JSON.parse(providerRes)
 // alert(providerJSON.tag)
 // let providerJSON = JSON.parse(localStorage.getItem("JSON"))
  let doms;
   // let sections = []
    let timeJson = {
      totalWeek: 30, // 总周数：[1, 30]之间的整数
      startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
      startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
      showWeekend: true, // 是否显示周末
      forenoon: 4, // 上午课程节数：[1, 10]之间的整数
      afternoon: 6, // 下午课程节数：[0, 10]之间的整数
      night: 0, // 晚间课程节数：[0, 10]之间的整数
      sections: []
  }
  let readAsText = (blob, encoding) => {
    return new Promise((resolve, reject) => {
        const fr = new FileReader();
        fr.onload = event => {
            resolve(fr.result);
        };

        fr.onerror = err => {
            reject(err);
        };

        fr.readAsText(blob, encoding);
    });
};
  let arr = ['','1','2','3','4','午间1','午间2','5','6','7','8','9','10','11']
  if(providerJSON.tag == "LIST"){   
    let url = window.frames[0].frames['mainFrame'].document.getElementsByClassName("button")[0].getAttribute("onclick").match(/'.*?'/)[0].replace(/'/g,"").replace("../../","")
     doms = await (new DOMParser().parseFromString(await fetch(url).then(re=>re.blob().then(v=>readAsText(v,'gbk'))).then(v=>v),"text/html"))
  }
  else if(providerJSON.tag == "BASE"){
     doms = new DOMParser().parseFromString(providerJSON.course,"text/html")
   }
    let trs = doms.getElementsByClassName("infolist_hr")[0].getElementsByClassName("infolist_hr_common")
    console.log(trs.length)
    for(let i=0;i<trs.length;i++){
      let th = trs[i].getElementsByTagName("th")[0]
      let timearr = th.innerHTML.replace(/[第节]/g,"").split("<br>")
      console.log(timearr)
     let sec = arr.indexOf(timearr[0])
      if(sec!=-1){
        timeJson.sections.push({
          "section": sec,
          "startTime": timearr[1],
          "endTime":timearr[3]
        })
      }
      timeJson.night=timeJson.sections.length-10
  }
 if(timeJson.sections.length==0) timeJson = {}
  return timeJson
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}
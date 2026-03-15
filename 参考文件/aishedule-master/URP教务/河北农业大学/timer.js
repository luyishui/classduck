/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
 async function scheduleTimer() {
      let timeJson = {
        totalWeek: 24, // 总周数：[1, 30]之间的整数
        startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
        startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
        showWeekend: true, // 是否显示周末
        forenoon: 4, // 上午课程节数：[1, 10]之间的整数
        afternoon: 4, // 下午课程节数：[0, 10]之间的整数
        night: 0, // 晚间课程节数：[0, 10]之间的整数
        sections: []
    }
    //let providerJSON = JSON.parse(providerRes)
   // alert(providerJSON.tag)
   try{
    let providerRes = localStorage.getItem("RE")
   let doms = new DOMParser().parseFromString(providerRes,"text/html") 
   let tds = doms.querySelectorAll("td[width='11%']")
     // let sections = []

    let arr = ['','一','二','三','四','五','六','七','八','九','十','十一','十二','十三','十四']
      for(let i=0;i<tds.length;i++){
        let timearr = tds[i].innerHTML.split(/[()]/)
        
        let sec = arr.indexOf(timearr[0].replace(/[第节]/g,""))
        console.log(sec,timearr)
        //let sec = Number(timearr[0])
            if(sec!=-1){
            timeJson.sections.push({
                "section": sec,
                "startTime": timearr[1].split('-')[0],
                "endTime":timearr[1].split('-')[1]
            })
            }
            timeJson.night=timeJson.sections.length-8
    }
   }catch(e){
       console.error(e)
        return {}
   }

   if(timeJson.sections.length==0) timeJson = {}
    return timeJson
    // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
  }
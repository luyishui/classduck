/**
 * @Author: xiaoxiao
 * @Date: 2022-03-15 18:40:09
 * @LastEditTime: 2022-03-28 18:15:52
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\超星\timer.js
 * @QQ：357914968
 */


function requests(tag,url,data)
{
   let pre = window.location.protocol+"//"+window.location.host+"/"
    let ss = "";
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        console.log(xhr.readyState+" "+xhr.status)
            if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {  
                ss = xhr.responseText
            }
            
        };
    xhr.open(tag, pre+url,false);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    xhr.send(data)
    return ss;
 }

/**
 * 时间配置函数，此为入口函数，不要改动函数名
 */
async function scheduleTimer({
    providerRes,

  } = {}) {
    try{
        let res ={
            totalWeek: 24, // 总周数：[1, 30]之间的整数
            startSemester: '', // 开学时间：时间戳，13位长度字符串，推荐用代码生成
            startWithSunday: false, // 是否是周日为起始日，该选项为true时，会开启显示周末选项
            showWeekend: false, // 是否显示周末
            forenoon: 0, // 上午课程节数：[1, 10]之间的整数
            afternoon: 0, // 下午课程节数：[0, 10]之间的整数
            night: 0, // 晚间课程节数：[0, 10]之间的整数
            sections:  []// 课程时间表，注意：总长度要和上边配置的节数加和对齐
        }

        let tag = JSON.parse(providerRes).tag
        console.log(tag)
        if(tag==='jw'){
            let time = requests("get","admin/system/zy/xlgl/selectJxzxsj/"+JSON.parse(providerRes).xnxq)
            let times = JSON.parse(time)
            times.forEach(t=>{
                res.sections.push({
                    section:t.jc,
                    startTime:t.kssj,
                    endTime:t.jssj
                })
                if(t.sjd==='sw'){
                    res.forenoon++
                }
                if(t.sjd==='xw'){
                    res.afternoon++
                }
                if(t.sjd==='bw' || t.sjd==='ws'){
                    res.night++
                }
            })
        }else if(tag === 'cx'){
            let  resJson = await fetch("/pc/curriculum/getMyLessons?curTime="+new Date().getTime()).then(v=>v.json()).then(v=>v);
            let timeArr = resJson.data.curriculum.lessonTimeConfigArray
            console.log(timeArr)
            res.forenoon = 4
            res.afternoon = 4
            res.night = timeArr.length-8;
            timeArr.forEach((t,index)=>{
                let ab = t.split("-");
                res.sections.push({
                    section:index+1,
                    startTime:ab[0].length === 4 ? '0' + ab[0]:ab[0],
                    endTime:ab[1].length === 4 ? '0' + ab[1]:ab[1]
                })
            })
        }

  return res.sections.length===0?{}:res 
}catch(e){
    return {}
}
  // PS: 夏令时什么的还是让用户在夏令时的时候重新导入一遍吧，在这个函数里边适配吧！奥里给！————不愿意透露姓名的嘤某人
}


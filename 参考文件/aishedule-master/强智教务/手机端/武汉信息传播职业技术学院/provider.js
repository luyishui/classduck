/**
 * @Author: xiaoxiao
 * @Date: 2022-03-02 20:21:32
 * @LastEditTime: 2022-03-02 21:15:21
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\强智教务\手机端\武汉信息传播职业技术学院\provider.js
 * @QQ：357914968
 */
async function request(tag, data, url,token) {
    console.log("fetching.......")
    let rep = await fetch(url,{method:tag,body:data,headers:{
        "token": token
    }}).then(re=>re.json()).then(v=>v).catch(err=>{console.error(err)})
    return rep
}

function AIScheduleLoading({
    titleText='加载中',
    contentText = 'loading...',
}={}
){
    console.log("start......")
    AIScheduleComponents.addMeta()
    const title = AIScheduleComponents.createTitle(titleText)
    const content = AIScheduleComponents.createContent(contentText)
    const card = AIScheduleComponents.createCard([title, content])
    const mask = AIScheduleComponents.createMask(card)
    
    // let dyn 
    // let count = 0
    // function dynLoading(){
    //     let t = ['loading','loading.','loading..','loading...']
    //     if(count==4) count=0
    //     content.innerText = t[count++]
    // }

    this.show=()=>{ 
        console.log("show......")
        document.body.appendChild(mask)
     //   dyn = setInterval(dynLoading,1000);
    }
    this.close=()=>{
        document.body.removeChild(mask)
        //clearInterval(dyn)
    }
    this.update=(str)=>{
        content.innerText = str;
    }
    }

async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改

    await loadTool("AIScheduleTools")
    await AIScheduleAlert("即将开始导入，导入时长受网络影响，请等待。。。。")

    let load = new AIScheduleLoading({
        titleText:'加载中',
        contentText : '即将开始导入'
    })
    load.show()
    let baseUrl = "http://219.140.59.210/bzb_njwhd"
    let token = sessionStorage.getItem('Token')

    let kbjcmsid = await request("post", null, baseUrl + "/Get_sjkbms", token)
    kbjcmsid =kbjcmsid.data[0].kbjcmsid
    console.log(kbjcmsid)

    let teachingWeek = await request("post", null, baseUrl + "/teachingWeek", token)
    teachingWeek = teachingWeek.data
    console.log(teachingWeek)

    let courses=new Set()
    
    for(let i=0;i<teachingWeek.length;i++){
          let datas = await request("post", null, baseUrl + "/student/curriculum?week=" + teachingWeek[i].week + "&kbjcmsid=" + kbjcmsid, token)
       
          datas = datas.data[0].item
          datas.forEach(v=>{
              courses.add(JSON.stringify(v))
          })
          load.update(`已获取${i+1}/${teachingWeek.length}节课`)
    }

    return "["+Array.from(courses).toString()+"]"

}
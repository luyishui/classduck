
async function req(method,url,data){
    return await fetch(url,{method:method,headers:{
        "Content-Type":"application/x-www-form-urlencoded"
    },body:data}).then(v=>v.text()).then(v=>v).catch(v=>v)
  }
  async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
       //除函数名外都可编辑
      //以下为示例，您可以完全重写或在此基础上更改
  //alert("请使用【本学期课表】导入")
  //let tag = confirm("选择导入模式，导入失败时请选择另外一种模式\n模式一（推荐）：确定\n模式二：取消")
  await loadTool("AIScheduleTools")
  let tag = (await AIScheduleSelect({
    titleText: '导入模式',
    contentText: '请选择导入模式',
    selectList: ['0:解析接口(准确度高)', '1:解析课表(兼容性高)'],
  })).split(":")[0]
  let html;
  let tag2 = document.getElementById("courseTable")
  if(tag==='0'||(tag2==null&&tag==='1')){
    let pc =  dom.getElementById("planCode")
    let method = "get"
    let data = null
    if(!!pc) {
        data = "&planCode="+pc.value;
        method = "post"
    }
    console.log(data)
      html = await req(method,"/student/courseSelect/thisSemesterCurriculum/ajaxStudentSchedule/callback",data)  
  }
  else {   html = document.getElementById("courseTable").outerHTML;   }                        
  
  return JSON.stringify({data:html,tag:(tag==='0'||(tag2==null&&tag==='1'))})
  }
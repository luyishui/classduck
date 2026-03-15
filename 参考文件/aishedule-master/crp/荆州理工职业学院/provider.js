
function getJieci(jcStr) {
    let rejc = [];
    let jc = jcStr.split(",")[1].replace(/第|节/g, "").split('-').filter(function (s) { return s && s.trim(); });
    for (let y = Number(jc[0]); y <= jc[jc.length - 1]; y++) {
        rejc.push(y);
    }
    return rejc;
}
async function req(form){
	let forms = new FormData(form)
	forms.set("__EVENTTARGET", "LinkButton_下一周")
     return await fetch('/st/student/st_p.aspx', {
	  method: 'POST',
	  body: forms
	}).then(c=>c.text()).then(v=>v);
}
async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
    console.log("begin")
    //除函数名外都可编辑
    //以下为示例，您可以完全重写或在此基础上更改
    await loadTool('AIScheduleTools')
    const { AIScheduleAlert,AISchedulePrompt } = AIScheduleTools()
    await AIScheduleAlert("即将进行导入...\n请确保当页面为第0周！！\n不是请改正！！\n此过程大概需要30秒\n导入时会出现假死，不要进行任何操作\n请耐心等待，导入完成后将会自动跳转...\n完成后，请去设置调整课表节数和时间\n点击确定开始进行导入")
    let htmstr =await req(dom.getElementById("form1"))
    let result = []
    let yz = {
    	titleText:"学期", 
    	tipText:"请输入本学期有总共有多少周？(默认20)", 
    	defaultText:22, 
    	validator:value=>{
           if (value != null && value != '' && value >= 0 && value <= 30) return false;
           return '输入不在0-30之间'
     }
    }
    let zs = await AISchedulePrompt(yz)
    let tag = confirm("即将进行导入，点击确定开始...")
    if (tag) {
        for (let i = 0; i < zs; i++) {
            AIScheduleAlert("正在获取第" + (i + 1) + "周")
            let formDom = new DOMParser().parseFromString(htmstr, "text/html")

            let trs = formDom.getElementsByTagName("table")[2].getElementsByTagName("tr")
            let form = formDom.getElementById("form1")

            for (j = 1; j <= 5; j++) {
                let tds = trs[j].getElementsByTagName("td")
                for (k = 1; k <= 7; k++) {
                    kcsText = tds[k].getElementsByTagName("span")[0].innerHTML.replace(/\s/g, "").split(/<br><br>/).slice(0, -1)
                    kcsText.forEach(v => {
                        kcarr = v.split("<br>")
                        let re = { weeks: [], sections: [] };
                       
                        kcarr.forEach(con => {
                            let cons = con.split("：") 
                      //      console.log(cons)
                            switch (cons[0]) {
                                case "时间":
                                    if (j != 5) {
                                        re.sections = getJieci(cons[1])
                                    }
                                    else {
                                        re.sections = getJieci(",第1-10节")
                                    }
                                    break;
                                case "课程名称": re.name = cons[1]; break
                                case "任课老师": re.teacher = cons[1].replace(/老师/g, ""); break
                                case "课室": re.position = cons[1].split("(").slice(0,-1).join("("); break
                            }
                        })
                        re.weeks.push(i + 1)
                        re.day = k
                       console.log(re)
                        result.push(re)
                    }
               )

            }
        }
           htmstr = await req(form)
        }
  //      console.log(result)
        return JSON.stringify(result);
    }
else return "do not continue"
}
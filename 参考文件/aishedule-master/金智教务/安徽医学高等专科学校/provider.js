/*
 * @Author: your name
 * @Date: 2022-02-19 22:54:23
 * @LastEditTime: 2023-02-20 09:49:01
 * @LastEditors: xiaoxiao
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: \AISchedule\金智教务\燕山大学\provider.js
 */


    let req = async (method,body,url)=>{
        return await fetch(url,{method:method, body:body,headers:{
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'
        }}).then(re=>re.json()).then(v=>v).catch(err=>console.error(err))
    }
    let getCourse = async (mode)=>{
            let nowXNXQ = "/jwapp/sys/wdkb/modules/jshkcb/dqxnxq.do"
            let course = "/jwapp/sys/wdkb/modules/xskcb/xskcb.do"
            let showApp = "/appShow?appId=4770397878132218" //我的课表appid
            // console.log(await req("get",null,showApp))
            await fetch(showApp,{method:"get"}).then(v=>v).then(v=>v.text())
            let xnxq = !document.getElementById('dqxnxq2')?(await req("post",null,nowXNXQ)).datas.dqxnxq.rows[0].DM:document.getElementById('dqxnxq2').getAttribute('value')
            console.log(xnxq)
            let courseText = (await req("post","XNXQDM="+xnxq,course)).datas.xskcb.rows
            console.log(courseText)
           return JSON.stringify({'courseJson':courseText,'mode':mode})
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
        
        let dyn 
        let count = 0
        function dynLoading(){
            let t = ['loading','loading.','loading..','loading...']
            if(count==4) count=0
            content.innerText = t[count++]
        }

        this.show=()=>{ 
            console.log("show......")
            document.body.appendChild(mask)
            dyn = setInterval(dynLoading,1000);
        }
        this.close=()=>{
            document.body.removeChild(mask)
            clearInterval(dyn)
        }
        }
    async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
        //除函数名外都可编辑
        //以下为示例，您可以完全重写或在此基础上更改
        await loadTool('AIScheduleTools')
      
        try{
             let mode = (await AIScheduleSelect({
                titleText:"导入模式选择",
                contentText:"请选择导入模式",
                selectList:[
                    "模式一:解析当前页面（速度快）",
                    "模式二:请求接口（速度慢）"
                ]
            })).split(':')[0]

            if(mode=='模式一'){
                return JSON.stringify({'html':dom.getElementById("kcb_container").outerHTML,'mode':mode})
            }
            else if(mode=='模式二'){
                let loading = new AIScheduleLoading()
                loading.show()
                let res = await getCourse(mode)
                loading.close()
            return res
            }
        }catch(e){
            console.error(e)
            try{
                let loading = new AIScheduleLoading()
                loading.show()
                let res = await getCourse("模式二")
               loading.close()
                return res
            }catch(e){
                await AIScheduleAlert({
                    contentText: e,
                    titleText: '错误',
                    confirmText: '导入失败',
                  })
                return "do not continue"
            }
            
        }
       
             
    }




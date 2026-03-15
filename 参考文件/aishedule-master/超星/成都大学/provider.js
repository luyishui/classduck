/**
 * @Author: xiaoxiao
 * @Date: 2022-03-28 17:46:09
 * @LastEditTime: 2022-03-28 18:04:13
 * @LastEditors: xiaoxiao
 * @Description: 
 * @FilePath: \AISchedule\超星\provider.js
 * @QQ：357914968
 */

function AIScheduleLoading({
    titleText = '加载中',
    contentText = 'loading...',
  } = {}) {
    console.log('start......')
    AIScheduleComponents.addMeta()
    const title = AIScheduleComponents.createTitle(titleText)
    const content = AIScheduleComponents.createContent(contentText)
    const card = AIScheduleComponents.createCard([title, content])
    const mask = AIScheduleComponents.createMask(card)
  
    let dyn
    let count = 0
    function dynLoading() {
      if (count == 4) count = 0
      content.innerText = contentText + '.'.repeat(count++)
      // console.log(contentText + '.'.repeat(count))
    }
  
    this.show = () => {
      console.log('show......')
      document.body.appendChild(mask)
      dyn = setInterval(dynLoading, 1000)
    }
    this.close = () => {
      document.body.removeChild(mask)
      clearInterval(dyn)
    }
  }

 function request(tag,url,data)
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
 
 async function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
     //除函数名外都可编辑
     //以下为示例，您可以完全重写或在此基础上更改

    await loadTool('AIScheduleTools')
    let loading = new AIScheduleLoading({contentText:"课表加载中"});
    try {
       let json = ''
       let fram ;
       let a_s = dom.querySelectorAll('.J_menuTab','a') 
       let xnxq='';
       let tag = '';
       let  iframes = document.getElementsByTagName('iframe');

        let currentUrl = window.location.href;
        if(currentUrl.search("jw")!==-1){
            tag = "jw";
        }else if(currentUrl.search(/i.chaoxing.com|kb.chaoxing.com/)!==-1){
            tag = 'cx'
        }else {
            await AIScheduleAlert(`
            您可能不在课表页，请到达课表页；
            若已在课表页请加群:628325112,找开发者进行反馈
        `)
        }
       
        loading.show()

        if (tag === 'jw'){
            for (let index = 0; index < a_s.length; index++) {
                const element = a_s[index];
                if(element.innerText.trim()=='我的课表'){
                    fram = dom.getElementsByTagName('iframe')[index];
                    break;
                }
            }
            if(fram){
                let dom1 = fram.contentDocument
                xnxq = dom1.getElementById('xnxq').value
                let xhid = dom1.getElementById('xhid').value
                let xqdm = dom1.getElementById('xqdm').value
                let url = 'admin/pkgl/xskb/sdpkkbList?xnxq='+xnxq+'&xhid='+xhid+'&xqdm='+xqdm
                json = request('get',url,null)
            }
            else{
                let html = request('get','/admin/pkgl/xskb/queryKbForXsd',null)
                let dom1 = new DOMParser().parseFromString(html, 'text/html')
                xnxq = dom1.getElementById('xnxq').value
                let xhid = dom1.getElementById('xhid').value
                let xqdm = dom1.getElementById('xqdm').value
                let url = 'admin/pkgl/xskb/sdpkkbList?xnxq='+xnxq+'&xhid='+xhid+'&xqdm='+xqdm
                json = request('get',url,null)
            }
        }else if (tag==='cx'){
            if(window.location.href.search("/curriculum/schedule.html")===-1){
                let iframs = document.getElementsByTagName('iframe');
                let src = ''
                for (let index = 0; index < iframs.length; index++) {
                    if(iframes[index].src.search("/curriculum/schedule.html")!==-1){
                        src = iframs[index].src
                    }
                }
                if(src.length === 0){
                    window.location.href = "https://kb.chaoxing.com/res/pc/curriculum/schedule.html";
                }else {
                    window.location.href = src;
                }
                return 'do not continue'
            }

            let  res = request("get","/pc/curriculum/getMyLessons?curTime="+new Date().getTime());
            let resJson = JSON.parse(res);
            let  maxWeek = resJson.data.curriculum.maxWeek

            let allResultPromise = []
            for(let week = 1;week<=Number(maxWeek?maxWeek:25);week++){
                allResultPromise.push(
                    fetch("/pc/curriculum/getMyLessons?curTime="+new Date().getTime()+"&week="+week, {
                        "method": "GET",
                    }).then(v=>v.json()).then(v=>v).catch(e=>console.error(e))
                )
            }
            let allResultJson = await Promise.all(allResultPromise)
            let allResult = []
            allResultJson.forEach(result=>allResult.push(...result.data.lessonArray))
            console.log(allResultJson)
            let arr = []
            allResult = allResult.filter(res => {
                let key = `${res.beginNumber}+${res.length}+${res.dayOfWeek}+${res.name}+${res.teacherNo}+${res.location}+${res.weeks}`
                let isNew = arr.indexOf(key) === -1
                arr.push(key)
                return isNew;
            });
            json = JSON.stringify(allResult)
        }

       return JSON.stringify({"data":JSON.parse(json),"xnxq":xnxq,"tag":tag})
    } catch (error) {
            console.log(error)
        let errText = `
        遇到错误，请凭此页面截图，加群:628325112,找开发者进行反馈
        错误：${ error.message.slice(0, 50)}
        `
      AIScheduleAlert({
        contentText: errText,
        titleText: '错误',
        confirmText: '我已知晓',
      })
      return "do not continue"
    } finally{
        loading.close()
    }
 }
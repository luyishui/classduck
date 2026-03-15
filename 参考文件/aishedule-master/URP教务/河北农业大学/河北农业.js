   function getWeeks(Str) {
    function range(con, tag) {
        if(con.length==1) return [];
        let retWeek=[]
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag === 1 || tag === 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag===0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 !== 0    }))
        })
        return retWeek
    }

    Str = Str.replace(/[(){}|第\[\]上课]/g, "").replace(/到/g, "-")
    if(Str=="全周"){
        Str = "1-24周"
    }
    else if(Str=="单周"){
        Str = "1-24单周"
    }
    else if(Str=="双周"){
        Str = "1-24双周"
    }
    let reWeek = [];
    let week1 = []
    while (Str.search(/周|\s/) !== -1) {
        let index = Str.search(/周|\s/)
        if (Str[index + 1] === '单' || Str[index + 1] === '双') {
            week1.push(Str.slice(0, index + 2).replace(/周|\s/g, ""));
            index += 2
        } else {
            week1.push(Str.slice(0, index + 1).replace(/周|\s/g, ""));
            index += 1
        }

        Str = Str.slice(index)
        index = Str.search(/\d/)
        if (index !== -1) Str = Str.slice(index)
        else Str = ""

    }
    if (Str.length !== 0) week1.push(Str)
    console.log(week1)
    week1.forEach(v => {
        console.log(v)
        if (v.slice(-1) === "双") reWeek.push(...range(v, 2))
        else if (v.slice(-1) === "单") reWeek.push(...range(v, 3))
        else reWeek.push(...range(v+"全", 1))
    });
    return reWeek;
}

   function cton(str){
       return ['','一','二','三','四','五','六','七','八','九','十','十一','十二','十三','十四'].indexOf(str)
   }
   function scheduleHtmlParser(html) {
       //除函数名外都可编辑
       //传入的参数为上一步函数获取到的html
       //可使用正则匹配
       //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
       //以下为示例，您可以完全重写或在此基础上更改
     //  html = JSON.parse(html)
     //  if (html.we.length ==0) html.we = 16
    //   console.log(html.htm)
        let $ = cheerio.load(html,{decodeEntities: false})
         let lb = $('#user').eq(1)
         let trs = $('tr','tbody',lb)
         let result = []
          trs.each(function(index,em){
              let re = {sections:[],weeks:[]}
              let tda = $(this).find('td')
              if(tda.length>7){
                  if(tda.eq(11).text().trim().length>0 && tda.eq(16).text().trim() !="虚拟教学楼"){
                       re.name = tda.eq(2).text().trim()
                      re.teacher = tda.eq(7).text().trim().replace(/\d|\*/g,"").replace(/\*/g," ")
                      re.day = tda.eq(12).text().trim()
                      re.position = tda.eq(16).text().trim()+tda.eq(17).text().trim()
                      for(let i = cton(tda.eq(13).text().trim()),j=0;j<tda.eq(14).text().trim();i++,j++){
                          re.sections.push(i)
                      }
                      re.weeks = getWeeks(tda.eq(11).text().trim())
                       result.push(re)
                  }
   
                  
              }
              else{
               if(tda.eq(0).text().trim().length>0 && tda.eq(5).text().trim() !="虚拟教学楼"){
                   re.name = result[result.length-1].name
                   re.teacher = result[result.length-1].teacher
                   re.day = tda.eq(1).text().trim()
                   re.position = tda.eq(5).text().trim()+tda.eq(6).text().trim()
                   re.position = re.position.replace("到个人课表查询71","")
                   for(let i = cton(tda.eq(2).text().trim()),j=0;j<tda.eq(3).text().trim();i++,j++){
                       re.sections.push(i)
                   }
                //   console.log(html.we)
                   re.weeks = getWeeks(tda.eq(0).text().trim())
                   result.push(re)
               }
              }
   
          })
       return result 
    }
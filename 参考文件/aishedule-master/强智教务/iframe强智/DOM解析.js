function getTimes(xJConf, dJConf) {
    //xJConf : 夏季时间配置文件
    //dJConf : 冬季时间配置文件
    //return : Array[{},{}]
    dJConf = dJConf === undefined ? xJConf : dJConf;

    function getTime(conf) {
        let courseSum = conf.courseSum;  //课程节数 : 12
        let startTime = conf.startTime; //上课时间 :800
        let oneCourseTime = conf.oneCourseTime;  //一节课的时间
        let shortRestingTime = conf.shortRestingTime;  //小班空

        let longRestingTimeBegin = conf.longRestingTimeBegin; //大班空开始位置
        let longRestingTime = conf.longRestingTime;   //大班空
        let lunchTime = conf.lunchTime;     //午休时间
        let dinnerTime = conf.dinnerTime;    //下午休息
        let abnormalClassTime = conf.abnormalClassTime;      //其他课程时间长度
        let abnormalRestingTime = conf.abnormalRestingTime;    //其他休息时间

        let result = [];
        let studyOrRestTag = true;
        let timeSum = startTime.slice(-2) * 1 + startTime.slice(0, -2) * 60;

        let classTimeMap = new Map();
        let RestingTimeMap = new Map();
        if (abnormalClassTime !== undefined) abnormalClassTime.forEach(time => {
            classTimeMap.set(time.begin, time.time)
        });
        if (longRestingTimeBegin !== undefined) longRestingTimeBegin.forEach(time => RestingTimeMap.set(time, longRestingTime));
        if (lunchTime !== undefined) RestingTimeMap.set(lunchTime.begin, lunchTime.time);
        if (dinnerTime !== undefined) RestingTimeMap.set(dinnerTime.begin, dinnerTime.time);
        if (abnormalRestingTime !== undefined) abnormalRestingTime.forEach(time => {
            RestingTimeMap.set(time.begin, time.time)
        });

        for (let i = 1, j = 1; i <= courseSum * 2; i++) {
            if (studyOrRestTag) {
                let startTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
                timeSum += classTimeMap.get(j) === undefined ? oneCourseTime : classTimeMap.get(j);
                let endTime = ("0" + Math.floor(timeSum / 60)).slice(-2) + ':' + ('0' + timeSum % 60).slice(-2);
                studyOrRestTag = false;
                result.push({
                    section: j++,
                    startTime: startTime,
                    endTime: endTime
                })
            } else {
                timeSum += RestingTimeMap.get(j - 1) === undefined ? shortRestingTime : RestingTimeMap.get(j - 1);
                studyOrRestTag = true;
            }
        }
        return result;
    }

    let nowDate = new Date();
    let year = nowDate.getFullYear();                       //2020
    let wuYi = new Date(year + "/" + '05/01');           //2020/05/01
    let jiuSanLing = new Date(year + "/" + '09/30');     //2020/09/30
    let shiYi = new Date(year + "/" + '10/01');          //2020/10/01
    let nextSiSanLing = new Date((year + 1) + "/" + '04/30');    //2021/04/30
    let previousShiYi = new Date((year - 1) + "/" + '10/01');     //2019/10/01
    let siSanLing = new Date(year + "/" + '04/30');         //2020/04/30
    let xJTimes = getTime(xJConf);
    let dJTimes = getTime(dJConf);
    console.log("夏季时间:\n", xJTimes)
    console.log("冬季时间:\n", dJTimes)
    if (nowDate >= wuYi && nowDate <= jiuSanLing) {
        return xJTimes;
    } else if (nowDate >= shiYi && nowDate <= nextSiSanLing || nowDate >= previousShiYi && nowDate <= siSanLing) {
        return dJTimes;
    }
}

function getWeeks(Str) {
    function range(con, tag) {
        console.log(con,tag)
        let retWeek=[]
        con.slice(0, -1).split(',').forEach(w => {
            let tt = w.split('-')
            let start = parseInt(tt[0])
            let end = parseInt(tt[tt.length - 1])
            if (tag == 1 || tag == 2)    retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(f=>{return f%tag==0}))
            else retWeek.push(...Array(end + 1 - start).fill(start).map((x, y) => x + y).filter(v => {return v % 2 != 0    }))
        })
        return retWeek
    }
    Str = Str.replace(/\(|\)|\{|\}|\||第/g, "").replace(/到/g, "-")
    let reWeek = [];
    let week1 = []
    while (Str.search(/周/) != -1) {
        let index = Str.search(/周/)
        if (Str[index + 1] == '单' || Str[index + 1] == '双') {
            week1.push(Str.slice(0, index + 2).replace("周", ""));
            index += 2
        } else {
            week1.push(Str.slice(0, index + 1).replace("周", ""));
            index += 1
        }

        Str = Str.slice(index)
        index = Str.search(/\d/)
        if (index != -1) Str = Str.slice(index)
        else Str = ""

    }
    if (Str.length != 0) week1.push(Str)

    week1.forEach(v => {
        console.log(v)
        if (v.slice(-1) == "双") reWeek.push(...range(v, 2))
        else if (v.slice(-1) == "单") reWeek.push(...range(v, 3))
        else reWeek.push(...range(v+"全", 1))
    });
    return reWeek;
}

function getSection(Str) {
    let rejc = [];
    Str = Str.replace("节", "").trim().split("-").forEach(v=>{
        rejc.push({section: Number(v)});
    })
//     for (let i = Number(Str[0]); i <= Number(Str[Str.length - 1]); i++) {
//         rejc.push({section: Number(i)});
//     }

    return rejc;

}

function scheduleHtmlParser(html) {
    //除函数名外都可编辑
    //传入的参数为上一步函数获取到的html
    //可使用正则匹配
    //可使用解析dom匹配，工具内置了$，跟jquery使用方法一样，直接用就可以了，参考：https://juejin.im/post/5ea131f76fb9a03c8122d6b9
    //以下为示例，您可以完全重写或在此基础上更改

    let $ = cheerio.load(html, {decodeEntities: false});
    let tag = false;
    let result = []
    console.log("html")
    let hang = $('tbody tr')
    console.log(hang)
    for (let i = 1; i < hang.length - 1; i++) {
        let lie = $('td', hang.eq(i));
        for (let j = 0; j < lie.length; j++) {
            let kc = lie.eq(j).children('div[class="kbcontent"]');
            if (kc.text().length <= 6) {
                continue;
            }
            let kcco = kc.html().split(/-{3,}/);

            kcco.forEach(con => {
                let re = {weeks: [], sections: []};
                console.log(con)
                $ = cheerio.load(con, {decodeEntities: false})
                console.log($.html())
                re.day = j + 1;
                re.name = $('div').length == 0 ? $('body').html().split(/<br>/).filter(f => {
                    return f.trim()
                })[0] : $('div').eq(0).html().split(/<br>/).filter(f => {
                    return f.trim()
                })[0];
                re.teacher = $('font[title="老师"],[title="教师"]').text().replace(/无职称|（高校）/g, "");
                re.position = $('font[title="教室"]').text()
                if(re.position.search("(白)")!=-1){
                    tag = true;
                    re.position = re.position.replace("(白)", "");
                }
                re.weeks = getWeeks($('font[title="周次(节次)"]').text().split("[")[0]);
                re.sections = getSection($('font[title="周次(节次)"]').text().match(/(?<=\[).*?(?=\])/g)[0])

                console.log(re)
                result.push(re);
            })

        }

    }
    let dj = {
        courseSum: 12,
        startTime: '0800',
        oneCourseTime: 40,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2, 7],
        lunchTime: {begin: 5, time: 2 * 60 + 20},
        dinnerTime: {begin: 9, time: 60 + 40}
    }
    let bxj = {
        courseSum: 12,
        startTime: '840',
        oneCourseTime: 40,
        longRestingTime: 20,
        shortRestingTime: 10,
        longRestingTimeBegin: [2, 6],
        // lunchTime: {begin: 4, time: 1 * 60 + 30},
        dinnerTime: {begin: 9, time: 2 * 60 + 10},
        abnormalClassTime:[{begin:5,time:1 * 60 + 10}]
    }

    return {courseInfos: result, sectionTimes: tag?getTimes(bxj):getTimes(dj)}


}
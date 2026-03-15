/**
 * 形如 1-3单周,4-8周双，10-12周
 * 原理：以周为界限进行分割
 * @param Str
 * @returns {*[]}
 */
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
    Str = Str.replace(/[(){}|第\[\]]/g, "").replace(/到/g, "-")
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

//console.log(getWeeks("1-5,6-10周单,4-8双周,7-9周,10到12周,13-15周,16-20"),)
//let start = 1
//let end =3
console.log(getWeeks("第13-18周|单周"),)
//console.log(getWeeks("1-6,7-13周(单),1-6,7-14周[双周] ,1-6,7-13周{单周},1-6,7-13 单,1-20,1,2,3,4 "))
function cutCourseInfo(result) {
    function cutOutStringByteLength(str, long) {
        let seeString = [];
        let countByteLength = 0;
        for (let i = 0; i < str.length; i++) {
            let charCode = str.charCodeAt(i);
            if (charCode >= 0 && charCode <= 128) {
                countByteLength += 1;
            } else {
                countByteLength += 2;
            }
            if (countByteLength <= long) {
                seeString.push(str[i]);
            } else {
                break;
            }
        }
        return seeString.join("");
    }

    for (const element of result) {
        element.name = cutOutStringByteLength(element.name, 40)
        element.teacher = cutOutStringByteLength(element.teacher, 38)
        element.position = cutOutStringByteLength(element.position, 38)
    }
    return result;
}

let result = [{
    name: "毛泽东思想与中国特色社会主义理论体系概论123",
    teacher: "毛泽东思想与中国特色社会主义理论体系概论aaa",
    position: "毛泽东思想与中国特色社会主义理论体系概论aaa"
}]

console.log(cutCourseInfo(result))

//activity = new TaskActivity(null,null,"1-2","4","国际金融",actTeacherId.join(','),actTeacherName.join(','),"7838(02120780-3.03)","国际金融(02120780-3.03)","77","5-401(多媒体教室)","01111111111111111100000000000000000000000000000000000",null,"",assistantName,"","");
//activity = new TaskActivity(actTeacherId.join(','),actTeacherName.join(','),"3668(08043022.03)","推拿学(08043022.03)","2348","中医学院中医推拿诊断实验室3","00000000001111111000000000000000000000000000000000000",null,null,assistantName,"","3");
//

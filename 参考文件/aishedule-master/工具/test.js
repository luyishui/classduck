//延时函数
function sleep(timeout) {
  for (let t = Date.now(); Date.now() - t <= timeout * 1000; );
}
//
// for(let i = 0;i<10;i++){
//     console.log(i)
//     sleep(3)
// }

//数组删除验证
// let arr = [1,2,3,4,5,6,7]
// arr.splice(1,1)
//
// //console.log(arr.shift())
// console.log(arr[1])

//sections判断函数
function pdSection(or, inn) {
  // console.log(or,inn)
  or.sort(function (a, b) {
    return a.section - b.section
  })
  inn.sort(function (a, b) {
    return a.section - b.section
  })
  if (JSON.stringify(or) === JSON.stringify(inn)) {
    return true
  } else return false
}
//
// let seca = {
//     "sections": [
//         {
//             "section": 7
//         },
//         {
//             "section": 8
//         },
//         {
//             "section": 9
//         },
//         {
//             "section": 10
//         }
//     ]
// }
// let secb = {
//     "sections": [
//         {
//             "section": 8
//         },
//         {
//             "section": 9
//         },
//         {
//             "section": 8
//         },
//         {
//             "section": 10
//         }
//     ]
// }
// console.log(pdSection(seca.sections,secb.sections))
//外网识别
function request(tag, data, url) {
  let ss = ''
  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + ' ' + xhr.status)
    if ((xhr.readyState == 4 && xhr.status == 200) || xhr.status == 304) {
      ss = xhr.responseText
    }
  }
  xhr.open(tag, url, false)
  xhr.setRequestH
  eader('Content-Type', 'application/x-www-form-urlencoded')
  xhr.send(data)
  return ss
}

let Name = 'xiaoxiao'
console.log(Name)

//////////////////////
;[
  {
    name: '可持续发展',
    teacher: '萧萧',
    day: 1,
    position: '123123',
    sections: [10],
    weeks: [1, 5, 3],
  },
]

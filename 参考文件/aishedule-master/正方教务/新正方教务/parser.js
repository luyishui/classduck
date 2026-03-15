function request(tag, data, url) {
  let ss = "";
  var xhr = new XMLHttpRequest();
  xhr.onreadystatechange = function () {
    console.log(xhr.readyState + " " + xhr.status);
    if (xhr.readyState == 4 && xhr.status == 200 || xhr.status == 304) {
      ss = xhr.responseText;
    }

  };
  xhr.open(tag, url, false);
  xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  xhr.send(data);
  return ss;
}

function scheduleHtmlProvider(iframeContent = "", frameContent = "", dom = document) {
  //除函数名外都可编辑
  //以下为示例，您可以完全重写或在此基础上更改
  let ts =
    `
导入失败，请确保当前位于【学生课表查询】页面!
----------------------------------
     >>导入流程<<
  >>点击【信息查询】<<
  >>点击【学生课表查询】<<
   >>点击【一键导入】<<

`

  try {
    htt = dom.getElementById("ylkbTable").outerHTML
  } catch (e) {
    try {
      let id;
      let arr = dom.getElementById("cdNav").outerHTML.match(/(?<=clickMenu\().*?(?=\);)/g)
      arr.every(v => {
        if (v.search("学生课表查询") != -1) {
          id = arr[i].split(",")[0].slice(1, -1)
          console.log(id)
          return true;
        }
      })
      let su = dom.getElementById("sessionUserKey").value
      let html = request("get", null, "/jwglxt/kbcx/xskbcx_cxXskbcxIndex.html?gnmkdm=" + id)
      console.log(su)
      dom = new DOMParser().parseFromString(html, "text/html")
      let form = dom.getElementById("ajaxForm")
      htt = JSON.stringify(JSON.parse(request("post", "xnm=" + form.xnm.value + "&xqm=" + form.xqm.value, "/jwglxt/kbcx/xskbcx_cxXsKb.html")).kbList)
    } catch (e) {
      alert(ts + e)
    }

  }
  return JSON.stringify({ html: htt })

}
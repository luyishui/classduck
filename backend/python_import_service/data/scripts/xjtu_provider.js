(async function() {
  try {
    const year = "{{YEAR}}";
    const term = "{{TERM}}";
    const res = await fetch(
      "https://ehall.xjtu.edu.cn/jwapp/sys/wdkb/modules/xskcb/cxxszhxqkb.do",
      {
        credentials: "include",
        headers: {
          "Accept": "application/json, text/javascript, */*; q=0.01",
          "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: "XNXQDM=" + term + "&XNM=" + year,
        method: "POST"
      }
    );

    if (!res.ok) {
      window.flutter_inappwebview.callHandler(
        "onImportResult",
        JSON.stringify({ success: false, error: "HTTP " + res.status })
      );
      return;
    }

    const data = await res.json();
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: true, data: data.kbList || [] })
    );
  } catch (error) {
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: false, error: error.message })
    );
  }
})();
(async function() {
  try {
    const fromWindow = window.__SORA_SCHEDULE__;
    if (fromWindow) {
      window.flutter_inappwebview.callHandler(
        "onImportResult",
        JSON.stringify({ success: true, data: fromWindow })
      );
      return;
    }

    const payloadScript = document.querySelector("script#__SORA_SCHEDULE__");
    if (payloadScript && payloadScript.textContent) {
      const parsed = JSON.parse(payloadScript.textContent);
      const data = parsed && parsed.courses ? parsed.courses : parsed;
      window.flutter_inappwebview.callHandler(
        "onImportResult",
        JSON.stringify({ success: true, data: data || [] })
      );
      return;
    }

    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: false, error: "SORA页面未发现可提取课表数据" })
    );
  } catch (error) {
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify({ success: false, error: error.message })
    );
  }
})();

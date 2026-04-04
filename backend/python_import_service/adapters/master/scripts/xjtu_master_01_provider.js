(async function () {
  function emit(payload) {
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify(payload)
    );
  }

  function normalizeText(value) {
    return String(value || "")
      .replace(/\u00a0/g, " ")
      .replace(/&nbsp;/gi, " ")
      .replace(/\r/g, "")
      .trim();
  }

  function extractField(blockText, label) {
    var pattern = new RegExp(label + "\\s*[:：]\\s*([^\\n]+)");
    var matched = blockText.match(pattern);
    return normalizeText(matched ? matched[1] : "");
  }

  function normalizeWeeks(raw) {
    var text = normalizeText(raw)
      .replace(/\s+/g, "")
      .replace(/^周次[:：]?/, "")
      .replace(/第/g, "")
      .replace(/[，、；;]/g, ",");
    if (!text) {
      return "1-20周";
    }
    if (!/周$/.test(text)) {
      text += "周";
    }
    return text;
  }

  function normalizeSections(raw, fallbackSection) {
    var text = normalizeText(raw)
      .replace(/节/g, "")
      .replace(/\s+/g, "");
    var matched = text.match(/(\d{1,2})(?:[-~到](\d{1,2}))?/);
    if (!matched) {
      return String(fallbackSection);
    }
    var start = Number(matched[1]);
    var end = Number(matched[2] || matched[1]);
    if (!Number.isFinite(start) || !Number.isFinite(end) || start <= 0 || end <= 0) {
      return String(fallbackSection);
    }
    if (end < start) {
      var temp = start;
      start = end;
      end = temp;
    }
    return start === end ? String(start) : start + "-" + end;
  }

  function parseCellBlock(blockText, day, fallbackSection) {
    var name = extractField(blockText, "课程");
    if (!name) {
      return null;
    }
    return {
      name: name,
      teacher: extractField(blockText, "教师"),
      position: extractField(blockText, "教室") || extractField(blockText, "地点"),
      day: day,
      weeks: normalizeWeeks(extractField(blockText, "周次")),
      sections: normalizeSections(extractField(blockText, "节次"), fallbackSection)
    };
  }

  try {
    var cells = document.querySelectorAll('td[id^="td_"]');
    var parsed = [];

    cells.forEach(function (cell) {
      var idMatch = String(cell.id || "").match(/^td_(\d+)_(\d+)$/);
      if (!idMatch) {
        return;
      }
      var day = Number(idMatch[1]);
      var fallbackSection = Number(idMatch[2]);
      if (day < 1 || day > 7 || fallbackSection < 1) {
        return;
      }

      var html = String(cell.innerHTML || "");
      if (!/课程[:：]/.test(html)) {
        return;
      }

      var blocks = html.split(/<br\s*\/?>(\s*<br\s*\/?>\s*)+/i);
      blocks.forEach(function (blockHtml) {
        var text = String(blockHtml)
          .replace(/<br\s*\/?>/gi, "\n")
          .replace(/<[^>]+>/g, "")
          .replace(/&nbsp;/gi, " ")
          .trim();
        if (!/课程[:：]/.test(text)) {
          return;
        }
        var item = parseCellBlock(text, day, fallbackSection);
        if (item) {
          parsed.push(item);
        }
      });
    });

    var dedup = new Map();
    parsed.forEach(function (item) {
      var key = [
        item.name,
        item.teacher,
        item.position,
        item.day,
        item.weeks,
        item.sections
      ].join("|");
      if (!dedup.has(key)) {
        dedup.set(key, item);
      }
    });

    var courses = Array.from(dedup.values()).sort(function (a, b) {
      var dayDelta = a.day - b.day;
      if (dayDelta !== 0) {
        return dayDelta;
      }
      var sa = Number(String(a.sections).split("-")[0]);
      var sb = Number(String(b.sections).split("-")[0]);
      if (sa !== sb) {
        return sa - sb;
      }
      return String(a.name).localeCompare(String(b.name));
    });

    if (courses.length === 0) {
      emit({
        success: false,
        error: "未在当前页面识别到研究生课表数据，请先打开“课表查询”并选择学期。"
      });
      return;
    }

    emit({ success: true, data: courses });
  } catch (error) {
    emit({
      success: false,
      error: error && error.message ? error.message : String(error)
    });
  }
})();

(async function () {
  function emit(payload) {
    window.flutter_inappwebview.callHandler(
      "onImportResult",
      JSON.stringify(payload)
    );
  }

  var DAY_MAP = {
    一: 1,
    二: 2,
    三: 3,
    四: 4,
    五: 5,
    六: 6,
    日: 7,
    天: 7
  };

  function normalizeText(value) {
    return String(value || "")
      .replace(/\u00a0/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function normalizeWeekText(value) {
    var text = String(value || "")
      .replace(/\s+/g, "")
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

  function normalizeSections(value) {
    var text = String(value || "")
      .replace(/节/g, "")
      .replace(/\s+/g, "");
    var matched = text.match(/(\d{1,2})(?:[-~到](\d{1,2}))?/);
    if (!matched) {
      return "1";
    }
    var start = Number(matched[1]);
    var end = Number(matched[2] || matched[1]);
    if (!Number.isFinite(start) || !Number.isFinite(end) || start <= 0 || end <= 0) {
      return "1";
    }
    if (end < start) {
      var tmp = start;
      start = end;
      end = tmp;
    }
    return start === end ? String(start) : start + "-" + end;
  }

  function pick(obj, keys) {
    if (!obj || typeof obj !== "object") {
      return "";
    }
    for (var i = 0; i < keys.length; i += 1) {
      var key = keys[i];
      if (obj[key] !== undefined && obj[key] !== null && String(obj[key]).trim() !== "") {
        return String(obj[key]);
      }
    }
    return "";
  }

  function parseDay(value) {
    var text = String(value || "").replace(/\s+/g, "");
    var zh = text.match(/(?:星期|周)?([一二三四五六日天])/);
    if (zh) {
      return DAY_MAP[zh[1]] || 0;
    }
    var num = text.match(/(?:星期|周)?([1-7])(?!\d)/);
    return num ? Number(num[1]) : 0;
  }

  function extractRows(payload) {
    if (Array.isArray(payload)) {
      return payload;
    }
    if (!payload || typeof payload !== "object") {
      return [];
    }
    if (Array.isArray(payload.rwList)) {
      return payload.rwList;
    }
    if (payload.datas && typeof payload.datas === "object") {
      var dataKeys = Object.keys(payload.datas);
      for (var i = 0; i < dataKeys.length; i += 1) {
        var block = payload.datas[dataKeys[i]];
        if (block && Array.isArray(block.rows)) {
          return block.rows;
        }
      }
    }
    if (payload.data && Array.isArray(payload.data.rows)) {
      return payload.data.rows;
    }
    if (payload.rows && Array.isArray(payload.rows)) {
      return payload.rows;
    }
    return [];
  }

  function getTermCode(row) {
    return normalizeText(
      pick(row, ["XNXQDM", "XNXQ", "TERM", "DM", "VALUE", "XQDM"]) 
    );
  }

  function isCurrentTerm(row) {
    var flag = normalizeText(
      pick(row, ["DQBZ", "DQM", "IS_CURRENT", "SFDQ", "CURRENT"]) 
    );
    return /^(1|Y|YES|TRUE|是)$/i.test(flag);
  }

  function pickCurrentTermCode(rows) {
    if (!rows || rows.length === 0) {
      return "";
    }

    for (var i = 0; i < rows.length; i += 1) {
      if (isCurrentTerm(rows[i])) {
        var currentCode = getTermCode(rows[i]);
        if (currentCode) {
          return currentCode;
        }
      }
    }

    var sorted = rows
      .slice()
      .sort(function (a, b) {
        var pa = Number(pick(a, ["PX", "ORDER_NUM", "XNXQDM"]) || 0);
        var pb = Number(pick(b, ["PX", "ORDER_NUM", "XNXQDM"]) || 0);
        return pb - pa;
      });

    return getTermCode(sorted[0]);
  }

  function parseScheduleSegments(pkText, fallback) {
    var text = String(pkText || "").trim();
    if (!text) {
      return [];
    }

    var parts = text.split(/[;；]/).map(function (part) {
      return normalizeText(part);
    }).filter(Boolean);

    var out = [];

    parts.forEach(function (part) {
      var matched = part.match(
        /(.+?周)\s*星期([一二三四五六日天])\[(\d{1,2})(?:\s*[-~到]\s*(\d{1,2}))?节\](.*)/
      );
      if (!matched) {
        matched = part.match(
          /(.+?周)\s*星期([一二三四五六日天])\s*(\d{1,2})(?:\s*[-~到]\s*(\d{1,2}))?节\s*(.*)/
        );
      }
      if (!matched) {
        return;
      }

      var weeks = normalizeWeekText(matched[1]);
      var day = DAY_MAP[matched[2]] || fallback.day || 0;
      var start = Number(matched[3]);
      var end = Number(matched[4] || matched[3]);
      if (end < start) {
        var tmp = start;
        start = end;
        end = tmp;
      }
      var sections = start === end ? String(start) : start + "-" + end;
      var position = normalizeText(matched[5]) || fallback.position;

      out.push({
        name: fallback.name,
        teacher: fallback.teacher,
        position: position,
        day: day,
        weeks: weeks,
        sections: sections
      });
    });

    return out;
  }

  function parseCourseRows(rows) {
    var courses = [];

    rows.forEach(function (row) {
      var name = normalizeText(
        pick(row, ["KCMC", "COURSE_NAME", "课程名称", "KCMC_DISPLAY"]) 
      );
      if (!name) {
        return;
      }

      var teacher = normalizeText(
        pick(row, ["RKJS", "SKJS", "JSXM", "JSMC", "TEACHER"]) 
      );
      var position = normalizeText(
        pick(row, ["JASMC", "CDMC", "JXDD", "CLASSROOM", "SKDD"]) 
      );
      var day = parseDay(pick(row, ["XQJ", "SKXQ", "WEEKDAY", "XQ"])) || 1;
      var fallback = {
        name: name,
        teacher: teacher,
        position: position,
        day: day
      };

      var pkText = pick(row, ["PKSJDD", "SJDD", "SCHEDULE", "KCSJ", "SKSJ"]);
      if (pkText) {
        var segments = parseScheduleSegments(pkText, fallback);
        if (segments.length > 0) {
          courses.push.apply(courses, segments);
          return;
        }
      }

      var sections = normalizeSections(pick(row, ["JCS", "JC", "SECTIONS", "SKJC"]));
      var weeks = normalizeWeekText(pick(row, ["ZCD", "WEEKS", "JXZ", "SKZC"]));
      courses.push({
        name: name,
        teacher: teacher,
        position: position,
        day: day,
        weeks: weeks,
        sections: sections
      });
    });

    return courses;
  }

  function parseDomTable(doc) {
    var rows = Array.from(doc.querySelectorAll("tr"));
    if (rows.length < 2) {
      return [];
    }

    var headerIndex = -1;
    var headerCells = [];

    for (var i = 0; i < rows.length; i += 1) {
      var cells = Array.from(rows[i].querySelectorAll("th,td"));
      var texts = cells.map(function (cell) {
        return normalizeText(cell.textContent);
      });
      var joined = texts.join("|");
      if (/课程/.test(joined) && (/星期|周几|上课日/.test(joined)) && (/节次|节/.test(joined))) {
        headerIndex = i;
        headerCells = texts;
        break;
      }
    }

    if (headerIndex < 0) {
      return [];
    }

    function findIndex(pattern) {
      for (var col = 0; col < headerCells.length; col += 1) {
        if (pattern.test(headerCells[col])) {
          return col;
        }
      }
      return -1;
    }

    var idxName = findIndex(/课程|名称/);
    var idxDay = findIndex(/星期|周几|上课日/);
    var idxSection = findIndex(/节次|节/);
    var idxWeek = findIndex(/周次|教学周/);
    var idxTeacher = findIndex(/教师|老师/);
    var idxLocation = findIndex(/教室|地点|上课地点/);

    if (idxName < 0 || idxDay < 0 || idxSection < 0) {
      return [];
    }

    var result = [];
    for (var rowIndex = headerIndex + 1; rowIndex < rows.length; rowIndex += 1) {
      var rowCells = Array.from(rows[rowIndex].querySelectorAll("td"));
      if (rowCells.length <= Math.max(idxName, idxDay, idxSection)) {
        continue;
      }

      var name = normalizeText(rowCells[idxName] ? rowCells[idxName].textContent : "");
      if (!name || /^\d+$/.test(name)) {
        continue;
      }

      var day = parseDay(rowCells[idxDay] ? rowCells[idxDay].textContent : "");
      if (day < 1 || day > 7) {
        continue;
      }

      var sections = normalizeSections(rowCells[idxSection] ? rowCells[idxSection].textContent : "");
      var weeks = normalizeWeekText(idxWeek >= 0 && rowCells[idxWeek] ? rowCells[idxWeek].textContent : "1-20周");
      var teacher = idxTeacher >= 0 && rowCells[idxTeacher] ? normalizeText(rowCells[idxTeacher].textContent) : "";
      var position = idxLocation >= 0 && rowCells[idxLocation] ? normalizeText(rowCells[idxLocation].textContent) : "";

      result.push({
        name: name,
        teacher: teacher,
        position: position,
        day: day,
        weeks: weeks,
        sections: sections
      });
    }

    return result;
  }

  function collectFrameDocuments() {
    var docs = [];
    for (var i = 0; i < window.frames.length; i += 1) {
      try {
        var frameDoc = window.frames[i].document;
        if (frameDoc && frameDoc.body) {
          docs.push(frameDoc);
        }
      } catch (_) {
        // cross-origin frame ignored
      }
    }
    return docs;
  }

  function dedupe(courses) {
    var map = new Map();
    (courses || []).forEach(function (item) {
      var key = [
        item.name,
        item.teacher,
        item.position,
        item.day,
        item.weeks,
        item.sections
      ].join("|");
      if (!map.has(key)) {
        map.set(key, item);
      }
    });
    return Array.from(map.values()).sort(function (a, b) {
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
  }

  async function requestJson(url, body) {
    var response = await fetch(url, {
      method: "POST",
      credentials: "include",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
        "X-Requested-With": "XMLHttpRequest"
      },
      body: body || ""
    });
    if (!response.ok) {
      throw new Error("HTTP " + response.status + " @ " + url);
    }
    var text = await response.text();
    return JSON.parse(text);
  }

  async function fetchByApi(origin) {
    var termCode = "";
    try {
      var termPayload = await requestJson(
        origin + "/gsapp/sys/wdkbapp/modules/xskcb/kfdxnxqcx.do",
        ""
      );
      var termRows = extractRows(termPayload);
      termCode = pickCurrentTermCode(termRows);
    } catch (_) {
      termCode = "";
    }

    var endpointList = [
      origin + "/gsapp/sys/wdkbapp/bykb/loadXskbData.do",
      origin + "/gsapp/sys/wdkbapp/modules/xskcb/xsjxrwcx.do",
      origin + "/gsapp/sys/wdkbapp/modules/xskcb/cxxszhxqkb.do"
    ];

    var bodies = [];
    if (termCode) {
      bodies.push("XNXQDM=" + encodeURIComponent(termCode));
    }
    bodies.push("");

    for (var i = 0; i < endpointList.length; i += 1) {
      for (var j = 0; j < bodies.length; j += 1) {
        try {
          var payload = await requestJson(endpointList[i], bodies[j]);
          var rows = extractRows(payload);
          if (!rows || rows.length === 0) {
            continue;
          }
          var courses = parseCourseRows(rows);
          if (courses.length > 0) {
            return courses;
          }
        } catch (_) {
          // next endpoint fallback
        }
      }
    }

    return [];
  }

  try {
    var origin = window.location && window.location.origin
      ? window.location.origin
      : "https://yjs.jlu.edu.cn";

    var courses = await fetchByApi(origin);

    if (courses.length === 0) {
      var docs = [document].concat(collectFrameDocuments());
      for (var i = 0; i < docs.length; i += 1) {
        var parsed = parseDomTable(docs[i]);
        if (parsed.length > 0) {
          courses = parsed;
          break;
        }
      }
    }

    courses = dedupe(courses);

    if (courses.length === 0) {
      var pageText = normalizeText(
        (document && document.title ? document.title : "") + " " +
        (document && document.body ? document.body.innerText.slice(0, 200) : "")
      );
      var errorMessage = /我的成绩|成绩查询/.test(pageText)
        ? "当前位于成绩页面，请先进入“我的课程表”后再执行导入。"
        : "未识别到课表数据，请先进入研究生课表页面并确保已完成登录。";
      emit({ success: false, error: errorMessage });
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

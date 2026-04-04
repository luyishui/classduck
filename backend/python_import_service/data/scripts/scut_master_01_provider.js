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

  var SECTION_SLOTS = [
    { section: 1, start: "08:00", end: "08:45" },
    { section: 2, start: "08:50", end: "09:35" },
    { section: 3, start: "09:50", end: "10:35" },
    { section: 4, start: "10:40", end: "11:25" },
    { section: 5, start: "11:30", end: "12:15" },
    { section: 6, start: "14:00", end: "14:45" },
    { section: 7, start: "14:50", end: "15:35" },
    { section: 8, start: "15:50", end: "16:35" },
    { section: 9, start: "16:40", end: "17:25" },
    { section: 10, start: "19:00", end: "19:45" },
    { section: 11, start: "19:50", end: "20:35" },
    { section: 12, start: "20:40", end: "21:25" },
    { section: 13, start: "21:30", end: "22:15" }
  ];

  function normalizeText(value) {
    return String(value || "")
      .replace(/\u00a0/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function toMinutes(value) {
    var matched = String(value || "").match(/(\d{1,2}):(\d{2})/);
    if (!matched) {
      return NaN;
    }
    return Number(matched[1]) * 60 + Number(matched[2]);
  }

  SECTION_SLOTS = SECTION_SLOTS.map(function (slot) {
    return {
      section: slot.section,
      startMin: toMinutes(slot.start),
      endMin: toMinutes(slot.end)
    };
  });

  function parseScheduleText(scheduleText) {
    var matched = String(scheduleText || "").match(
      /星期([一二三四五六日天])\s*(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})/
    );
    if (!matched) {
      return null;
    }
    var day = DAY_MAP[matched[1]] || 0;
    var startMin = toMinutes(matched[2]);
    var endMin = toMinutes(matched[3]);
    if (day < 1 || day > 7 || !Number.isFinite(startMin) || !Number.isFinite(endMin)) {
      return null;
    }
    return { day: day, startMin: startMin, endMin: endMin };
  }

  function parseDateRange(dateText) {
    var matched = String(dateText || "").match(
      /(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})\s*-\s*(\d{4})[\/-](\d{1,2})[\/-](\d{1,2})/
    );
    if (!matched) {
      return null;
    }

    var start = new Date(
      Number(matched[1]),
      Number(matched[2]) - 1,
      Number(matched[3])
    );
    var end = new Date(
      Number(matched[4]),
      Number(matched[5]) - 1,
      Number(matched[6])
    );

    start.setHours(0, 0, 0, 0);
    end.setHours(0, 0, 0, 0);

    if (!Number.isFinite(start.getTime()) || !Number.isFinite(end.getTime())) {
      return null;
    }

    return { start: start, end: end };
  }

  function sectionsFromMinutes(startMin, endMin) {
    var overlaps = SECTION_SLOTS.filter(function (slot) {
      return slot.startMin < endMin && slot.endMin > startMin;
    }).map(function (slot) {
      return slot.section;
    });

    if (overlaps.length > 0) {
      return overlaps;
    }

    var nearest = 1;
    var minDiff = Number.MAX_SAFE_INTEGER;
    SECTION_SLOTS.forEach(function (slot) {
      var diff = Math.abs(slot.startMin - startMin);
      if (diff < minDiff) {
        minDiff = diff;
        nearest = slot.section;
      }
    });

    var roughCount = Math.max(1, Math.round((endMin - startMin) / 45));
    var fallback = [];
    for (var i = 0; i < roughCount; i += 1) {
      var section = nearest + i;
      if (section >= 1 && section <= 15) {
        fallback.push(section);
      }
    }
    if (fallback.length === 0) {
      fallback.push(nearest);
    }
    return fallback;
  }

  function buildWeeks(dateRange, baseStartDate) {
    if (!dateRange || !baseStartDate) {
      return [];
    }
    var oneDay = 24 * 60 * 60 * 1000;
    var startWeek = Math.floor((dateRange.start.getTime() - baseStartDate.getTime()) / oneDay / 7) + 1;
    var endWeek = Math.floor((dateRange.end.getTime() - baseStartDate.getTime()) / oneDay / 7) + 1;

    if (!Number.isFinite(startWeek) || !Number.isFinite(endWeek)) {
      return [];
    }

    if (endWeek < startWeek) {
      var temp = startWeek;
      startWeek = endWeek;
      endWeek = temp;
    }

    startWeek = Math.max(1, startWeek);
    endWeek = Math.min(30, endWeek);

    var result = [];
    for (var week = startWeek; week <= endWeek; week += 1) {
      result.push(week);
    }
    return result;
  }

  function weeksToText(weeks) {
    var unique = Array.from(new Set(weeks || []))
      .filter(function (week) {
        return week >= 1 && week <= 30;
      })
      .sort(function (a, b) {
        return a - b;
      });

    if (unique.length === 0) {
      return "1-20周";
    }

    var parts = [];
    var start = unique[0];
    var prev = unique[0];

    for (var i = 1; i <= unique.length; i += 1) {
      var current = unique[i];
      if (current === prev + 1) {
        prev = current;
        continue;
      }
      parts.push(start === prev ? String(start) : start + "-" + prev);
      start = current;
      prev = current;
    }

    return parts.join(",") + "周";
  }

  function sectionsToText(sections) {
    var unique = Array.from(new Set(sections || []))
      .filter(function (section) {
        return section >= 1 && section <= 15;
      })
      .sort(function (a, b) {
        return a - b;
      });

    if (unique.length === 0) {
      return "1";
    }

    var start = unique[0];
    var end = unique[unique.length - 1];
    return start === end ? String(start) : start + "-" + end;
  }

  function extractCourseName(groupNode) {
    var titleNode = groupNode.querySelector(".PAGROUPDIVIDER");
    var title = normalizeText(titleNode ? titleNode.textContent : "");
    if (!title) {
      return "";
    }
    var splitByDash = title.split(/\s+-\s+/);
    if (splitByDash.length >= 2) {
      return normalizeText(splitByDash.slice(1).join("-"));
    }
    return normalizeText(title.replace(/^[A-Za-z0-9_-]+\s*-\s*/, ""));
  }

  function collectRawRows(root) {
    var items = [];
    var groups = root.querySelectorAll('div[id^="win4divDERIVED_REGFRM1_DESCR20$"]');

    groups.forEach(function (group) {
      var courseName = extractCourseName(group);
      if (!courseName) {
        return;
      }

      var rows = group.querySelectorAll('tr[id^="trCLASS_MTG_VW$"]');
      rows.forEach(function (row) {
        var scheduleText = normalizeText(
          row.querySelector('[id^="MTG_SCHED$"]')
            ? row.querySelector('[id^="MTG_SCHED$"]').textContent
            : ""
        );
        var schedule = parseScheduleText(scheduleText);
        if (!schedule) {
          return;
        }

        var sections = sectionsFromMinutes(schedule.startMin, schedule.endMin);
        var location = normalizeText(
          row.querySelector('[id^="MTG_LOC$"]')
            ? row.querySelector('[id^="MTG_LOC$"]').textContent
            : ""
        );
        var teacher = normalizeText(
          row.querySelector('[id^="DERIVED_CLS_DTL_SSR_INSTR_LONG$"]')
            ? row.querySelector('[id^="DERIVED_CLS_DTL_SSR_INSTR_LONG$"]').textContent
            : ""
        );
        var dateText = normalizeText(
          row.querySelector('[id^="MTG_DATES$"]')
            ? row.querySelector('[id^="MTG_DATES$"]').textContent
            : ""
        );

        items.push({
          name: courseName,
          teacher: teacher,
          position: location,
          day: schedule.day,
          sections: sections,
          dateRange: parseDateRange(dateText)
        });
      });
    });

    return items;
  }

  try {
    var rawItems = collectRawRows(document);

    if (rawItems.length === 0) {
      emit({
        success: false,
        error: "未识别到课程行，请先打开“我的课程表”页面并切换到周历列表后重试。"
      });
      return;
    }

    var datedItems = rawItems.filter(function (item) {
      return item.dateRange && item.dateRange.start;
    });

    var baseStartDate = null;
    if (datedItems.length > 0) {
      baseStartDate = datedItems
        .map(function (item) {
          return item.dateRange.start;
        })
        .sort(function (a, b) {
          return a.getTime() - b.getTime();
        })[0];
    }

    var grouped = new Map();

    rawItems.forEach(function (item) {
      var key = [
        item.name,
        item.teacher,
        item.position,
        item.day,
        sectionsToText(item.sections)
      ].join("|");

      var weeks = buildWeeks(item.dateRange, baseStartDate);
      if (weeks.length === 0) {
        weeks = [];
        for (var i = 1; i <= 20; i += 1) {
          weeks.push(i);
        }
      }

      if (!grouped.has(key)) {
        grouped.set(key, {
          name: item.name,
          teacher: item.teacher,
          position: item.position,
          day: item.day,
          sections: sectionsToText(item.sections),
          weekSet: new Set()
        });
      }

      var target = grouped.get(key);
      weeks.forEach(function (week) {
        target.weekSet.add(week);
      });
    });

    var courses = Array.from(grouped.values())
      .map(function (item) {
        return {
          name: item.name,
          teacher: item.teacher,
          position: item.position,
          day: item.day,
          sections: item.sections,
          weeks: weeksToText(Array.from(item.weekSet))
        };
      })
      .sort(function (a, b) {
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

    emit({ success: true, data: courses });
  } catch (error) {
    emit({
      success: false,
      error: error && error.message ? error.message : String(error)
    });
  }
})();

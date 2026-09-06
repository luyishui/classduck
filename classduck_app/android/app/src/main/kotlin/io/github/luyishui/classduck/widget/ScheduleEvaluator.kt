package io.github.luyishui.classduck.widget

import java.time.Duration
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime
import java.time.temporal.ChronoUnit

/**
 * 实时判定引擎：纯函数、纯本地算术推导，不依赖后台常驻或网络。
 *
 * 小组件每次渲染（添加、系统周期刷新、数据下发广播）时都会调用 [evaluate]，
 * 以当前系统时间推算教学周次、今日课程与当前/下一节课状态。
 */

/** 课表整体状态。 */
enum class WidgetScheduleStatus {
    /** 未下发数据或数据不可用。 */
    NO_DATA,

    /** 未设置开学日期，无法推算周次（按全部课程展示兜底）。 */
    NO_SEMESTER_DATE,

    /** 尚未开学。 */
    NOT_STARTED,

    /** 学期已结束（假期）。 */
    SEMESTER_ENDED,

    /** 今日无课。 */
    NO_CLASS_TODAY,

    /** 正在上课。 */
    ONGOING,

    /** 今日还有未开始的课。 */
    NEXT_UP,

    /** 今日课程全部结束。 */
    ALL_DONE,
}

/** 一门课程的起止时刻（由节次时间表换算）。 */
data class CourseTimeRange(
    val start: LocalTime,
    val end: LocalTime,
)

/** 引擎输出：UI 层据此渲染三种规格的小组件。 */
data class WidgetEvaluation(
    val status: WidgetScheduleStatus,
    val today: LocalDate,

    /** ISO 星期序号：1=周一 ... 7=周日，与课程 weekTime 语义一致。 */
    val weekdayIso: Int,

    /**
     * 当前教学周：null=未设置开学日期；0=未开学；-1=学期已结束；否则为 1..termWeeks。
     */
    val currentWeek: Int?,

    /** 今日课程（按开始节次升序），未开学/已结束/无课时为空。 */
    val todayCourses: List<WidgetCourse>,

    /** 正在进行的课程（多门重叠时取开始最早的一门）。 */
    val ongoing: WidgetCourse?,

    /** 下一节课（今天尚未开始的第一门）。 */
    val next: WidgetCourse?,

    /** 距下一节课开始的分钟数。 */
    val minutesUntilNext: Int?,
) {

    /** 从“正在进行/下一节”开始的今日剩余课程流，供 4x2 日程流使用。 */
    val upcomingCourses: List<WidgetCourse>
        get() {
            val anchorCourse = ongoing ?: next ?: return emptyList()
            val anchorIndex = todayCourses.indexOfFirst { it === anchorCourse || it == anchorCourse }
            if (anchorIndex < 0) {
                return listOf(anchorCourse)
            }
            return todayCourses.drop(anchorIndex)
        }
}

object ScheduleEvaluator {

    /** 学期结束标记（与未开学 0、正常周 1..n 区分）。 */
    private const val WEEK_SEMESTER_ENDED = -1
    private const val WEEK_NOT_STARTED = 0

    /** 解析 "HH:mm" / "H:mm" / "HH:mm:ss" 形式的节次时间。 */
    fun parseTime(raw: String): LocalTime? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) {
            return null
        }
        return try {
            val parts = trimmed.split(":")
            val hour = parts[0].trim().toInt()
            val minute = if (parts.size > 1) parts[1].trim().toInt() else 0
            val second = if (parts.size > 2) parts[2].trim().toInt() else 0
            if (hour in 0..23 && minute in 0..59 && second in 0..59) {
                LocalTime.of(hour, minute, second)
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    /** 解析 "yyyy-MM-dd" 形式的开学日期。 */
    fun parseDate(raw: String?): LocalDate? {
        if (raw.isNullOrBlank()) {
            return null
        }
        return try {
            val parts = raw.trim().split("-")
            if (parts.size != 3) {
                return null
            }
            LocalDate.of(
                parts[0].trim().toInt(),
                parts[1].trim().toInt(),
                parts[2].trim().toInt(),
            )
        } catch (_: Exception) {
            null
        }
    }

    /**
     * 计算当前教学周：
     * 教学周以周一为统一周期锚点。将开学日期归一化对齐到其所在周的周一，
     * 消除开学日非周一导致的首周课程清空与全学期周次偏移问题。
     * Δdays < 0 → 未开学(0)；周次 > termWeeks → 已结束(-1)；否则 Δdays/7 + 1。
     * 未配置开学日期时返回 null。
     */
    fun computeCurrentWeek(data: WidgetScheduleData, today: LocalDate): Int? {
        val rawStartDate = parseDate(data.semesterStartMonday) ?: return null
        // 归一化对齐到所在周的周一（1=周一 ... 7=周日）
        val anchorMonday = rawStartDate.minusDays((rawStartDate.dayOfWeek.value - 1).toLong())
        val deltaDays = ChronoUnit.DAYS.between(anchorMonday, today)
        if (deltaDays < 0) {
            return WEEK_NOT_STARTED
        }
        val week = (deltaDays / 7 + 1).toInt()
        if (week > data.termWeeks) {
            return WEEK_SEMESTER_ENDED
        }
        return week
    }

    /**
     * 由节次时间表换算课程起止时刻。
     *
     * 节次越界（如晚上加课超出作息表）时不静默丢弃课程：
     * 1. 起始时刻：若 firstSection 存在，严格以其真实 start 为准；不存在时才从末节链式外推；
     * 2. 结束时刻：若 lastSection 存在，以其真实 end 为准；不存在时按时长向后累加；
     * 3. 跨越午夜（24:00 回绕）时，兜底截断至 23:59:59，杜绝课程静默丢弃。
     */
    fun courseTimeRange(
        data: WidgetScheduleData,
        course: WidgetCourse,
    ): CourseTimeRange? {
        if (course.startTime <= 0 || course.timeCount <= 0) {
            return null
        }
        val firstSection = data.sectionAt(course.startTime)
        val lastSection =
            data.sectionAt(course.startTime + course.timeCount - 1)
        if (firstSection != null && lastSection != null) {
            val start = parseTime(firstSection.start) ?: return null
            val end = parseTime(lastSection.end) ?: return null
            if (end.isAfter(start)) {
                return CourseTimeRange(start = start, end = end)
            }
            return CourseTimeRange(start = start, end = LocalTime.of(23, 59))
        }

        val stepMinutes = (data.classDuration + data.breakDuration).coerceAtLeast(5)
        val start: LocalTime = if (firstSection != null) {
            parseTime(firstSection.start) ?: return null
        } else {
            val anchor = data.sections.lastOrNull() ?: return null
            val anchorStart = parseTime(anchor.start) ?: return null
            val offsetSections = (course.startTime - anchor.index).coerceAtLeast(0)
            anchorStart.plusMinutes(offsetSections * stepMinutes.toLong())
        }

        val end: LocalTime = if (lastSection != null) {
            parseTime(lastSection.end) ?: return null
        } else {
            val durationMinutes = ((course.timeCount - 1) * stepMinutes + data.classDuration).toLong()
            start.plusMinutes(durationMinutes)
        }

        if (end.isAfter(start)) {
            return CourseTimeRange(start = start, end = end)
        }
        return CourseTimeRange(start = start, end = LocalTime.of(23, 59))
    }

    /** 周次匹配：空周列表视为全周有效（与 App 端 _isCourseInWeek 一致）。 */
    private fun isCourseInWeek(course: WidgetCourse, currentWeek: Int?): Boolean {
        return currentWeek == null ||
            course.weeks.isEmpty() ||
            currentWeek in course.weeks
    }

    /**
     * 取某一天（ISO 星期序号）在当前教学周的课程，按开始节次升序。
     * 未开学/已结束（currentWeek <= 0）时无课；未设置开学日期时
     * 忽略周次约束仅按星期匹配。
     */
    fun coursesForDay(
        data: WidgetScheduleData,
        currentWeek: Int?,
        weekdayIso: Int,
    ): List<WidgetCourse> {
        if (currentWeek != null && currentWeek <= 0) {
            return emptyList()
        }
        return data.courses
            .filter { it.weekTime == weekdayIso }
            .filter { isCourseInWeek(it, currentWeek) }
            .sortedBy { it.startTime }
    }

    /** 主入口：以 [now] 为基准做全量实时推导。 */
    fun evaluate(
        data: WidgetScheduleData?,
        now: LocalDateTime = LocalDateTime.now(),
    ): WidgetEvaluation? {
        if (data == null || !data.hasValidSections) {
            return data?.let {
                WidgetEvaluation(
                    status = WidgetScheduleStatus.NO_DATA,
                    today = now.toLocalDate(),
                    weekdayIso = now.dayOfWeek.value,
                    currentWeek = computeCurrentWeek(it, now.toLocalDate()),
                    todayCourses = emptyList(),
                    ongoing = null,
                    next = null,
                    minutesUntilNext = null,
                )
            }
        }

        val today = now.toLocalDate()
        val weekdayIso = today.dayOfWeek.value
        val currentWeek = computeCurrentWeek(data, today)

        val todayCourses = coursesForDay(data, currentWeek, weekdayIso)

        val nowTime = now.toLocalTime()
        var ongoing: WidgetCourse? = null
        var next: WidgetCourse? = null
        var minutesUntilNext: Int? = null
        for (course in todayCourses) {
            val range = courseTimeRange(data, course) ?: continue
            when {
                // 正在上课：开始时刻 <= 当前 < 结束时刻。
                !nowTime.isBefore(range.start) && nowTime.isBefore(range.end) -> {
                    if (ongoing == null) {
                        ongoing = course
                    }
                }
                // 尚未开始的最早一门课即“下一节”。
                nowTime.isBefore(range.start) && next == null -> {
                    next = course
                    minutesUntilNext =
                        Duration.between(nowTime, range.start).toMinutes().toInt()
                }
                else -> Unit
            }
        }

        val resolvedStatus = when {
            ongoing != null -> WidgetScheduleStatus.ONGOING
            next != null -> WidgetScheduleStatus.NEXT_UP
            todayCourses.isNotEmpty() -> WidgetScheduleStatus.ALL_DONE
            currentWeek == WEEK_NOT_STARTED -> WidgetScheduleStatus.NOT_STARTED
            currentWeek == WEEK_SEMESTER_ENDED -> WidgetScheduleStatus.SEMESTER_ENDED
            currentWeek == null -> WidgetScheduleStatus.NO_SEMESTER_DATE
            else -> WidgetScheduleStatus.NO_CLASS_TODAY
        }

        return WidgetEvaluation(
            status = resolvedStatus,
            today = today,
            weekdayIso = weekdayIso,
            currentWeek = currentWeek,
            todayCourses = todayCourses,
            ongoing = ongoing,
            next = next,
            minutesUntilNext = minutesUntilNext,
        )
    }

    /** 周次文案（与 App 内“第 N 周 / 未开学 / 已结束”保持一致）。 */
    fun weekLabel(currentWeek: Int?): String {
        return when (currentWeek) {
            null -> ""
            WEEK_NOT_STARTED -> "未开学"
            WEEK_SEMESTER_ENDED -> "已结束"
            else -> "第 $currentWeek 周"
        }
    }

    /** 星期短文案：周一...周日。 */
    fun weekdayLabel(weekdayIso: Int): String {
        return when (weekdayIso) {
            1 -> "周一"
            2 -> "周二"
            3 -> "周三"
            4 -> "周四"
            5 -> "周五"
            6 -> "周六"
            7 -> "周日"
            else -> ""
        }
    }

    /**
     * 计算下一次需要重绘小组件的时刻（供节点闹钟调度使用）。
     *
     * 取今日剩余课程流（正在进行/下一节起）中最早的「开始时刻或结束时刻」，
     * 保证上下课切换在节点即时刷新；若无后续节点则取明日零点，
     * 作为跨天重绘的第二重保险（第一重是系统 DATE_CHANGED 广播）。
     */
    fun nextRefreshTime(
        data: WidgetScheduleData,
        evaluation: WidgetEvaluation,
        now: LocalDateTime,
    ): LocalDateTime? {
        val today = now.toLocalDate()
        val candidates = mutableListOf<LocalDateTime>()
        for (course in evaluation.upcomingCourses) {
            val range = courseTimeRange(data, course) ?: continue
            candidates += today.atTime(range.start)
            candidates += today.atTime(range.end)
        }
        candidates += today.plusDays(1).atStartOfDay()
        return candidates.filter { it.isAfter(now) }.minOrNull()
    }
}

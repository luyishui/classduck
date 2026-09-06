package io.github.luyishui.classduck.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.LocalTime

/**
 * 实时判定引擎的纯函数单测：
 * 覆盖周一锚定周次推导、开学日非周一归一化、节次越界外推、
 * 跨午夜截断、周次过滤与上下课状态流转。
 */
class ScheduleEvaluatorTest {

    private companion object {
        /** 与 App 端默认作息同源：上午 4 节 + 下午 4 节 + 晚上 2 节（45+10 链式）。 */
        val DEFAULT_SECTIONS: List<WidgetSection> = buildSections(
            anchors = listOf("08:00" to 4, "14:00" to 4, "19:00" to 2),
        )

        private fun buildSections(
            anchors: List<Pair<String, Int>>,
            classMinutes: Int = 45,
            breakMinutes: Int = 10,
        ): List<WidgetSection> {
            val sections = mutableListOf<WidgetSection>()
            var index = 1
            for ((anchor, count) in anchors) {
                val parts = anchor.split(":")
                var cursor = parts[0].toInt() * 60 + parts[1].toInt()
                repeat(count) {
                    val end = cursor + classMinutes
                    sections += WidgetSection(
                        index = index++,
                        start = "%02d:%02d".format(cursor / 60, cursor % 60),
                        end = "%02d:%02d".format(end / 60, end % 60),
                    )
                    cursor = end + breakMinutes
                }
            }
            return sections
        }
    }

    private fun data(
        semesterStartMonday: String? = "2026-09-07",
        termWeeks: Int = 4,
        sections: List<WidgetSection> = DEFAULT_SECTIONS,
        courses: List<WidgetCourse> = emptyList(),
    ): WidgetScheduleData = WidgetScheduleData(
        tableName = "测试课表",
        semesterStartMonday = semesterStartMonday,
        termWeeks = termWeeks,
        classDuration = 45,
        breakDuration = 10,
        sections = sections,
        courses = courses,
    )

    private fun course(
        name: String = "高等数学",
        weekTime: Int = 1,
        startTime: Int = 1,
        timeCount: Int = 2,
        weeks: Set<Int> = emptySet(),
        classroom: String? = "外语楼-201",
    ): WidgetCourse = WidgetCourse(
        name = name,
        classroom = classroom,
        teacher = null,
        weekTime = weekTime,
        startTime = startTime,
        timeCount = timeCount,
        colorHex = "#D45E6A",
        weeks = weeks,
    )

    // ---------- 周次推导 ----------

    @Test
    fun `周一开学按自然周翻转`() {
        val d = data(semesterStartMonday = "2026-09-07", termWeeks = 4)
        assertEquals(1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 7)))
        assertEquals(1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 13)))
        assertEquals(2, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 14)))
        assertEquals(4, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 10, 4)))
    }

    @Test
    fun `开学日非周一归一化到所在周的周一`() {
        // 2026-09-02 是周三 → 锚点周一为 2026-08-31。
        val d = data(semesterStartMonday = "2026-09-02", termWeeks = 4)
        assertEquals(1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 8, 31)))
        assertEquals(1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 2)))
        assertEquals(1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 6)))
        // 周一 0 点翻转为第二周，而非周三。
        assertEquals(2, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 7)))
    }

    @Test
    fun `开学前与学期结束后`() {
        val d = data(semesterStartMonday = "2026-09-07", termWeeks = 4)
        assertEquals(0, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 9, 6)))
        // 第 4 周周日 +1 天 → 5 周 > 4 周 → 已结束。
        assertEquals(-1, ScheduleEvaluator.computeCurrentWeek(d, LocalDate.of(2026, 10, 5)))
        assertNull(ScheduleEvaluator.computeCurrentWeek(data(semesterStartMonday = null), LocalDate.of(2026, 9, 7)))
    }

    // ---------- 课程起止时刻 ----------

    @Test
    fun `正常节次换算`() {
        val range = ScheduleEvaluator.courseTimeRange(
            data(),
            course(startTime = 1, timeCount = 2),
        )!!
        assertEquals(LocalTime.of(8, 0), range.start)
        assertEquals(LocalTime.of(9, 40), range.end)
    }

    @Test
    fun `结束节越界时起始时刻不被后移`() {
        // 10 节作息表，第 9 节连上 3 节（9、10、11）：起始必须仍是 19:00，
        // 结束按时长外推 19:00 + 2×55 + 45 = 21:35。
        val range = ScheduleEvaluator.courseTimeRange(
            data(),
            course(startTime = 9, timeCount = 3),
        )!!
        assertEquals(LocalTime.of(19, 0), range.start)
        assertEquals(LocalTime.of(21, 35), range.end)
    }

    @Test
    fun `起始节越界时链式外推`() {
        // 第 12 节越界：以最后一节（第 10 节 19:55）为锚点外推 2 节。
        val range = ScheduleEvaluator.courseTimeRange(
            data(),
            course(startTime = 12, timeCount = 1),
        )!!
        assertEquals(LocalTime.of(21, 45), range.start)
        assertEquals(LocalTime.of(22, 30), range.end)
    }

    @Test
    fun `跨午夜结束时刻截断到 23 点 59`() {
        val sections = listOf(WidgetSection(1, "23:30", "00:15"))
        val range = ScheduleEvaluator.courseTimeRange(
            data(sections = sections),
            course(startTime = 1, timeCount = 1),
        )!!
        assertEquals(LocalTime.of(23, 30), range.start)
        assertEquals(LocalTime.of(23, 59), range.end)
    }

    @Test
    fun `非法节次返回空`() {
        assertNull(ScheduleEvaluator.courseTimeRange(data(), course(startTime = 0)))
        assertNull(ScheduleEvaluator.courseTimeRange(data(), course(timeCount = 0)))
    }

    // ---------- 周次过滤 ----------

    @Test
    fun `周次过滤与空周列表全周有效`() {
        val d = data(
            courses = listOf(
                course(name = "单周课", weekTime = 1, weeks = setOf(1)),
                course(name = "全周课", weekTime = 1, weeks = emptySet()),
            ),
        )
        // 第 1 周：两门都在。
        assertEquals(
            setOf("单周课", "全周课"),
            ScheduleEvaluator.coursesForDay(d, 1, 1).map { it.name }.toSet(),
        )
        // 第 2 周：只剩全周课。
        assertEquals(
            setOf("全周课"),
            ScheduleEvaluator.coursesForDay(d, 2, 1).map { it.name }.toSet(),
        )
        // 未开学无课；未设置开学日期时只按星期匹配。
        assertEquals(0, ScheduleEvaluator.coursesForDay(d, 0, 1).size)
        assertEquals(
            setOf("单周课", "全周课"),
            ScheduleEvaluator.coursesForDay(d, null, 1).map { it.name }.toSet(),
        )
    }

    // ---------- 状态流转 ----------

    @Test
    fun `正在上课`() {
        val monday = LocalDateTime.of(2026, 9, 7, 10, 0)
        val e = ScheduleEvaluator.evaluate(
            data(courses = listOf(course(startTime = 3, timeCount = 2))),
            monday,
        )!!
        assertEquals(WidgetScheduleStatus.ONGOING, e.status)
        assertEquals("高等数学", e.ongoing?.name)
    }

    @Test
    fun `下一节课与分钟数`() {
        val mondayMorning = LocalDateTime.of(2026, 9, 7, 8, 0)
        val e = ScheduleEvaluator.evaluate(
            data(courses = listOf(course(startTime = 3, timeCount = 2))),
            mondayMorning,
        )!!
        assertEquals(WidgetScheduleStatus.NEXT_UP, e.status)
        assertEquals("高等数学", e.next?.name)
        assertEquals(110, e.minutesUntilNext)
    }

    @Test
    fun `今日课程已结束与今日无课`() {
        val mondayNight = LocalDateTime.of(2026, 9, 7, 21, 0)
        val done = ScheduleEvaluator.evaluate(
            data(courses = listOf(course(startTime = 3, timeCount = 2))),
            mondayNight,
        )!!
        assertEquals(WidgetScheduleStatus.ALL_DONE, done.status)

        val noClass = ScheduleEvaluator.evaluate(
            data(courses = listOf(course(weekTime = 2))),
            LocalDateTime.of(2026, 9, 7, 10, 0),
        )!!
        assertEquals(WidgetScheduleStatus.NO_CLASS_TODAY, noClass.status)
    }

    @Test
    fun `假期状态清空课程`() {
        // 开学 30 天前、学期仅 1 周 → 已结束。
        val e = ScheduleEvaluator.evaluate(
            data(
                semesterStartMonday = "2026-07-06",
                termWeeks = 1,
                courses = listOf(course(weekTime = 1)),
            ),
            LocalDateTime.of(2026, 9, 7, 10, 0),
        )!!
        assertEquals(WidgetScheduleStatus.SEMESTER_ENDED, e.status)
        assertEquals(0, e.todayCourses.size)
    }

    // ---------- 节点刷新时点 ----------

    @Test
    fun `下一刷新时刻取最近的课程节点`() {
        val d = data(
            courses = listOf(
                course(name = "A", startTime = 3, timeCount = 2), // 09:50-11:30
                course(name = "B", startTime = 4, timeCount = 1), // 10:45-11:30
            ),
        )
        val now = LocalDateTime.of(2026, 9, 7, 10, 0)
        // 10:00 时：A 进行中（结束 11:30），B 下一节（开始 10:45）→ 最近节点 10:45。
        val evaluation = ScheduleEvaluator.evaluate(d, now)!!
        assertEquals(
            LocalDateTime.of(2026, 9, 7, 10, 45),
            ScheduleEvaluator.nextRefreshTime(d, evaluation, now),
        )

        // 全部结束后：下一个节点是明日零点。
        val night = LocalDateTime.of(2026, 9, 7, 21, 0)
        val nightEvaluation = ScheduleEvaluator.evaluate(d, night)!!
        assertEquals(
            LocalDateTime.of(2026, 9, 8, 0, 0),
            ScheduleEvaluator.nextRefreshTime(d, nightEvaluation, night),
        )
    }
}

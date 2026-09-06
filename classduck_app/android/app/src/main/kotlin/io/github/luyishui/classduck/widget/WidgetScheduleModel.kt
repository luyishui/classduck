package io.github.luyishui.classduck.widget

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * 桌面小组件的数据实体与安全反序列化。
 *
 * 数据由 Flutter 端在课表增删改、切换课表、App 切后台时经 home_widget
 * 写入 SharedPreferences（文件名固定为 home_widget 插件约定的
 * "HomeWidgetPreferences"，key 为 widget_schedule_data）。
 * 原生端只读取，不写回。
 */

/** 节次时间，[index] 从 1 开始与 App 内节次序号一致。 */
data class WidgetSection(
    val index: Int,
    val start: String,
    val end: String,
)

/** 下发到小组件的单门课程。 */
data class WidgetCourse(
    val name: String,
    val classroom: String?,
    val teacher: String?,
    val weekTime: Int,
    val startTime: Int,
    val timeCount: Int,
    val colorHex: String?,
    val weeks: Set<Int>,
)

/** 全量课表结构。 */
data class WidgetScheduleData(
    val tableName: String,
    val semesterStartMonday: String?,
    val termWeeks: Int,
    val classDuration: Int,
    val breakDuration: Int,
    val sections: List<WidgetSection>,
    val courses: List<WidgetCourse>,
) {

    /** 无节次时间表时无法推导课程起止时刻，视为不可用数据。 */
    val hasValidSections: Boolean
        get() = sections.isNotEmpty()

    /** 按节次序号取节次。 */
    fun sectionAt(index: Int): WidgetSection? =
        sections.firstOrNull { it.index == index }

    companion object {
        /** home_widget 插件保存数据使用的 SharedPreferences 文件名。 */
        private const val PREFS_NAME = "HomeWidgetPreferences"

        /** Flutter 端 ScheduleWidgetService 下发数据的 key。 */
        private const val DATA_KEY = "widget_schedule_data"

        /** 从 SharedPreferences 读取并解析；任何异常都降级为 null（空状态）。 */
        fun fromSharedPreferences(context: Context): WidgetScheduleData? {
            return try {
                val prefs =
                    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val raw = prefs.getString(DATA_KEY, null) ?: return null
                parse(raw)
            } catch (_: Exception) {
                null
            }
        }

        /** 宽松解析：字段缺失或类型异常时逐项兜底，整体失败返回 null。 */
        fun parse(raw: String): WidgetScheduleData? {
            return try {
                val root = JSONObject(raw)

                val sections = mutableListOf<WidgetSection>()
                val sectionsArray = root.optJSONArray("sections") ?: JSONArray()
                for (i in 0 until sectionsArray.length()) {
                    val item = sectionsArray.optJSONObject(i) ?: continue
                    val index = item.optInt("index", i + 1)
                    val start = item.optString("start").trim()
                    val end = item.optString("end").trim()
                    if (start.isEmpty() || end.isEmpty()) {
                        continue
                    }
                    sections.add(WidgetSection(index = index, start = start, end = end))
                }
                sections.sortBy { it.index }

                val courses = mutableListOf<WidgetCourse>()
                val coursesArray = root.optJSONArray("courses") ?: JSONArray()
                for (i in 0 until coursesArray.length()) {
                    val item = coursesArray.optJSONObject(i) ?: continue
                    val name = item.optNullableString("name")
                    if (name.isNullOrEmpty()) {
                        continue
                    }
                    val weeks = mutableSetOf<Int>()
                    val weeksArray = item.optJSONArray("weeks")
                    if (weeksArray != null) {
                        for (j in 0 until weeksArray.length()) {
                            val week = weeksArray.optInt(j, -1)
                            if (week > 0) {
                                weeks.add(week)
                            }
                        }
                    }
                    courses.add(
                        WidgetCourse(
                            name = name,
                            classroom = item.optNullableString("classroom"),
                            teacher = item.optNullableString("teacher"),
                            weekTime = item.optInt("weekTime", 0),
                            startTime = item.optInt("startTime", 0),
                            timeCount = item.optInt("timeCount", 1),
                            colorHex = item.optNullableString("colorHex"),
                            weeks = weeks,
                        ),
                    )
                }

                WidgetScheduleData(
                    tableName = root.optNullableString("tableName") ?: "我的课表",
                    semesterStartMonday = root.optNullableString("semesterStartMonday"),
                    termWeeks = root.optInt("termWeeks", 20).coerceAtLeast(1),
                    classDuration = root.optInt("classDuration", 45).coerceAtLeast(1),
                    breakDuration = root.optInt("breakDuration", 10).coerceAtLeast(0),
                    sections = sections,
                    courses = courses,
                )
            } catch (_: Exception) {
                null
            }
        }

        /**
         * 读取可空字符串字段。
         *
         * org.json 的 optString 对「键存在但值为 JSON null」会返回字面量
         * 字符串 "null"（JSONObject.NULL.toString()），这里统一归一为 null，
         * 避免把 "null" 当成教室名/颜色值渲染出来。
         */
        private fun JSONObject.optNullableString(key: String): String? {
            if (isNull(key)) {
                return null
            }
            val value = optString(key).trim()
            if (value.isEmpty() || value.equals("null", ignoreCase = true)) {
                return null
            }
            return value
        }
    }
}

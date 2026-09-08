package io.github.luyishui.classduck.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.time.LocalDate

/**
 * 4x4 多日日程网格小组件。
 *
 * 1. 智能滑动 5 天视窗：以“今天”为首列（第 1 个位置），顺延展示未来 5 天；
 * 2. 纯净无界设计：移除顶部 Header 与鸭鸭 Logo，空间 100% 留给课表网格；
 * 3. 严格等宽网格：表头与主体严格 5 等分（5 * defaultWeight + 4 * 1dp 细分割线）；
 * 4. 独立日期气泡：星期在上方，下方为 28x28 独立日期气泡（今日鸭鸭金高亮，非今日透明）；
 * 5. 微卡片防挤压：紧凑内边距，彩点锁定首行文字左上角，长课名最多 2 行，空课日通透留白。
 */
class ClassDuckLargeWidget : GlanceAppWidget() {

    private companion object {
        const val MAX_COURSES_PER_DAY = 4
        /** 视窗固定展示 5 天（今天为第 1 天）。 */
        const val WINDOW_DAYS = 5
    }

    // Exact 模式下支持 Launcher 缩放微调自适应拉伸。
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = WidgetScheduleData.fromSharedPreferences(context)
        val evaluation = ScheduleEvaluator.evaluate(data)
        // 预排下一次节点刷新（下一节课开始/正在上课结束/明日零点，取最早）。
        if (data != null && evaluation != null) {
            WidgetRefreshScheduler.scheduleNext(context, data, evaluation)
        }

        provideContent {
            val today = evaluation?.today ?: LocalDate.now()
            WidgetRootCard(context) {
                Column(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .padding(horizontal = 12.dp, vertical = 14.dp),
                ) {
                    DayHeaderRow(today = today)
                    Spacer(modifier = GlanceModifier.height(10.dp))
                    WeekGrid(
                        data = data,
                        evaluation = evaluation,
                        today = today,
                        modifier = GlanceModifier.defaultWeight(),
                    )
                }
            }
        }
    }

    @Composable
    private fun DayHeaderRow(today: LocalDate) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(WINDOW_DAYS) { offset ->
                if (offset > 0) {
                    Spacer(modifier = GlanceModifier.width(1.dp))
                }
                val date = today.plusDays(offset.toLong())
                val isToday = offset == 0
                DayHeaderItem(
                    date = date,
                    isToday = isToday,
                    weekdayText = ScheduleEvaluator.weekdayLabel(date.dayOfWeek.value),
                    modifier = GlanceModifier.defaultWeight(),
                )
            }
        }
    }

    @Composable
    private fun DayHeaderItem(
        date: LocalDate,
        isToday: Boolean,
        weekdayText: String,
        modifier: GlanceModifier = GlanceModifier,
    ) {
        Column(
            modifier = modifier,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(
                text = weekdayText,
                style = TextStyle(
                    color = ColorProvider(if (isToday) WidgetTheme.textDark else WidgetTheme.textSubtle),
                    fontSize = 11.sp,
                    fontWeight = if (isToday) FontWeight.Bold else FontWeight.Medium,
                ),
                maxLines = 1,
            )
            Spacer(modifier = GlanceModifier.height(2.dp))
            val bubbleModifier = if (isToday) {
                GlanceModifier
                    .size(28.dp)
                    .background(WidgetTheme.duckYellow)
                    .cornerRadius(9.dp)
            } else {
                GlanceModifier.size(28.dp)
            }
            Box(
                modifier = bubbleModifier,
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = date.dayOfMonth.toString(),
                    style = TextStyle(
                        color = ColorProvider(WidgetTheme.textDark),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    maxLines = 1,
                )
            }
        }
    }

    @Composable
    private fun WeekGrid(
        data: WidgetScheduleData?,
        evaluation: WidgetEvaluation?,
        today: LocalDate,
        modifier: GlanceModifier = GlanceModifier,
    ) {
        if (data == null || evaluation == null || evaluation.status == WidgetScheduleStatus.NO_DATA) {
            Box(modifier = modifier.fillMaxWidth()) {
                EmptyStateContent(message = "暂无课表数据", hint = "打开上课鸭同步")
            }
            return
        }

        Row(
            modifier = modifier.fillMaxWidth(),
        ) {
            repeat(WINDOW_DAYS) { offset ->
                if (offset > 0) {
                    Box(
                        modifier = GlanceModifier
                            .width(1.dp)
                            .fillMaxHeight()
                            .background(WidgetTheme.columnDivider),
                    ) {}
                }
                val targetDate = today.plusDays(offset.toLong())
                val targetWeek = ScheduleEvaluator.computeCurrentWeek(data, targetDate)
                DayColumn(
                    data = data,
                    evaluation = evaluation,
                    date = targetDate,
                    week = targetWeek,
                    isToday = offset == 0,
                    modifier = GlanceModifier.defaultWeight(),
                )
            }
        }
    }

    @Composable
    private fun DayColumn(
        data: WidgetScheduleData,
        evaluation: WidgetEvaluation,
        date: LocalDate,
        week: Int?,
        isToday: Boolean,
        modifier: GlanceModifier = GlanceModifier,
    ) {
        val dayCourses = ScheduleEvaluator
            .coursesForDay(data, week, date.dayOfWeek.value)
        val courses = dayCourses.take(MAX_COURSES_PER_DAY)
        val total = dayCourses.size

        Column(
            modifier = modifier.fillMaxHeight().padding(horizontal = 2.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            if (courses.isEmpty()) {
                Spacer(modifier = GlanceModifier.defaultWeight())
            } else {
                courses.forEachIndexed { index, course ->
                    if (index > 0) {
                        Spacer(modifier = GlanceModifier.height(4.dp))
                    }
                    val isOngoing = isToday && course == evaluation.ongoing
                    MiniCard(
                        data = data,
                        course = course,
                        isOngoing = isOngoing,
                    )
                }
                if (total > courses.size) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    CaptionText(
                        text = "+${total - courses.size}",
                        fontSize = 8.sp,
                        color = WidgetTheme.textSubtle,
                    )
                }
                Spacer(modifier = GlanceModifier.defaultWeight())
            }
        }
    }

    @Composable
    private fun MiniCard(
        data: WidgetScheduleData,
        course: WidgetCourse,
        isOngoing: Boolean,
    ) {
        val range = ScheduleEvaluator.courseTimeRange(data, course)
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(if (isOngoing) WidgetTheme.cardBgHighlight else WidgetTheme.cardBgSubtle)
                .cornerRadius(8.dp),
        ) {
            Column(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp, vertical = 4.dp),
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.Top,
                ) {
                    Box(modifier = GlanceModifier.padding(vertical = 3.dp)) {
                        CourseColorDot(hex = course.colorHex, size = 4.dp)
                    }
                    Spacer(modifier = GlanceModifier.width(3.dp))
                    Text(
                        text = course.name,
                        modifier = GlanceModifier.defaultWeight(),
                        style = TextStyle(
                            color = ColorProvider(WidgetTheme.textDark),
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 2,
                    )
                }
                if (range != null) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    Row(modifier = GlanceModifier.fillMaxWidth()) {
                        Spacer(modifier = GlanceModifier.width(7.dp))
                        Text(
                            text = range.start.toString(),
                            style = TextStyle(
                                color = ColorProvider(WidgetTheme.textSubtle),
                                fontSize = 8.sp,
                                fontWeight = FontWeight.Medium,
                            ),
                            maxLines = 1,
                        )
                    }
                }
            }
        }
    }
}

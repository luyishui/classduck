package io.github.luyishui.classduck.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.text.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
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
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import io.github.luyishui.classduck.R
import java.time.LocalDate

/**
 * 4x4 多日迷你日程网格。
 *
 * 顶部：当前教学周总览 + 上课鸭徽标；
 * 日期列头：周一至周日等分排布（星期 + 日期号，今日鸭鸭黄圆角气泡高亮）；
 * 网格主体：各列纵向排布当天课程微卡片（彩点 + 课名 + 开始时间），
 * 空课列保留清爽浅色底，一览全周课程。
 */
class ClassDuckLargeWidget : GlanceAppWidget() {

    private companion object {
        const val MAX_COURSES_PER_DAY = 4

        /** 常规宽度下的完整周列数。 */
        const val FULL_WEEK_DAYS = 7

        /** 窄宽度下的列数：只保留周一至周五，避免单列被极限压缩。 */
        const val COMPACT_WEEK_DAYS = 5

        /** 宽度达到该阈值（dp）时展示 7 天，否则自适应收窄为 5 天。 */
        const val FULL_WEEK_MIN_WIDTH_DP = 290
    }

    // Exact 模式下 LocalSize 才是 Launcher 分配的真实拉伸宽度；
    // Single 模式恒等于 XML minWidth（250dp），自适应列数会沦为死代码。
    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = WidgetScheduleData.fromSharedPreferences(context)
        val evaluation = ScheduleEvaluator.evaluate(data)
        // 预排下一次节点刷新（下一节课开始/正在上课结束/明日零点，取最早）。
        if (data != null && evaluation != null) {
            WidgetRefreshScheduler.scheduleNext(context, data, evaluation)
        }

        provideContent {
            // 4x4 在不同 Launcher/缩放下实际宽度差异较大：宽度充裕时展示
            // 周一至周日 7 列，否则收窄为周一至周五 5 列，保证单列文字可读。
            val dayCount = if (LocalSize.current.width >= FULL_WEEK_MIN_WIDTH_DP.dp) {
                FULL_WEEK_DAYS
            } else {
                COMPACT_WEEK_DAYS
            }
            WidgetRootCard(context) {
                Column(
                    modifier = GlanceModifier.fillMaxSize().padding(10.dp),
                ) {
                    HeaderSection(data, evaluation)
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    DayHeaderRow(evaluation, dayCount)
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    WeekGrid(data, evaluation, dayCount)
                }
            }
        }
    }

    @Composable
    private fun HeaderSection(data: WidgetScheduleData?, evaluation: WidgetEvaluation?) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            val weekLabel = evaluation?.let { ScheduleEvaluator.weekLabel(it.currentWeek) }
            if (weekLabel.isNullOrEmpty()) {
                MainText(text = data?.tableName ?: "上课鸭课表", fontSize = 14.sp)
            } else {
                MainText(text = weekLabel, fontSize = 14.sp)
                Spacer(modifier = GlanceModifier.width(6.dp))
                CaptionText(text = data?.tableName ?: "", fontSize = 10.sp)
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
            Image(
                provider = ImageProvider(R.drawable.widget_duck_logo),
                contentDescription = null,
                modifier = GlanceModifier.size(20.dp).cornerRadius(8.dp),
            )
        }
    }

    @Composable
    private fun DayHeaderRow(evaluation: WidgetEvaluation?, dayCount: Int) {
        val today = evaluation?.today ?: LocalDate.now()
        val monday = today.minusDays((today.dayOfWeek.value - 1).toLong())
        Row(verticalAlignment = Alignment.CenterVertically) {
            repeat(dayCount) { offset ->
                Box(modifier = GlanceModifier.defaultWeight()) {
                    val date = monday.plusDays(offset.toLong())
                    val isToday = evaluation != null && date == today
                    if (isToday) {
                        Column(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .background(WidgetTheme.duckYellow)
                                .cornerRadius(8.dp)
                                .padding(vertical = 3.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            CaptionText(
                                text = ScheduleEvaluator.weekdayLabel(offset + 1),
                                color = WidgetTheme.textMain,
                                fontSize = 9.sp,
                            )
                            Text(
                                text = date.dayOfMonth.toString(),
                                style = TextStyle(
                                    color = ColorProvider(WidgetTheme.textMain),
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                ),
                                maxLines = 1,
                            )
                        }
                    } else {
                        Column(
                            modifier = GlanceModifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            CaptionText(
                                text = ScheduleEvaluator.weekdayLabel(offset + 1),
                                fontSize = 9.sp,
                            )
                            Text(
                                text = date.dayOfMonth.toString(),
                                style = TextStyle(
                                    color = ColorProvider(WidgetTheme.textMain),
                                    fontSize = 12.sp,
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

    @Composable
    private fun WeekGrid(
        data: WidgetScheduleData?,
        evaluation: WidgetEvaluation?,
        dayCount: Int,
    ) {
        if (data == null || evaluation == null) {
            Box(modifier = GlanceModifier.fillMaxSize()) {
                EmptyStateContent(message = "暂无课表数据", hint = "打开上课鸭同步")
            }
            return
        }

        Row(modifier = GlanceModifier.fillMaxSize()) {
            repeat(dayCount) { offset ->
                if (offset > 0) {
                    Spacer(modifier = GlanceModifier.width(3.dp))
                }
                DayColumn(data, evaluation, offset, modifier = GlanceModifier.defaultWeight())
            }
        }
    }

    @Composable
    private fun DayColumn(
        data: WidgetScheduleData,
        evaluation: WidgetEvaluation,
        dayOffset: Int,
        modifier: GlanceModifier = GlanceModifier,
    ) {
        val dayCourses = ScheduleEvaluator
            .coursesForDay(data, evaluation.currentWeek, dayOffset + 1)
        val courses = dayCourses.take(MAX_COURSES_PER_DAY)
        val total = dayCourses.size

        Column(modifier = modifier) {
            if (courses.isEmpty()) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .defaultWeight()
                        .background(WidgetTheme.gridEmptyBackground)
                        .cornerRadius(8.dp),
                ) {}
            } else {
                courses.forEachIndexed { index, course ->
                    if (index > 0) {
                        Spacer(modifier = GlanceModifier.height(3.dp))
                    }
                    val range = ScheduleEvaluator.courseTimeRange(data, course)
                    val isOngoing = course == evaluation.ongoing
                    Box(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .background(if (isOngoing) WidgetTheme.duckYellowSoft else WidgetTheme.surface)
                            .cornerRadius(8.dp),
                    ) {
                        Row(
                            modifier = GlanceModifier.fillMaxWidth().padding(4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            CourseColorDot(hex = course.colorHex, size = 5.dp)
                            Spacer(modifier = GlanceModifier.width(3.dp))
                            Column(modifier = GlanceModifier.defaultWeight()) {
                                Text(
                                    text = course.name,
                                    style = TextStyle(
                                        color = ColorProvider(WidgetTheme.textMain),
                                        fontSize = 9.sp,
                                        fontWeight = FontWeight.Medium,
                                    ),
                                    maxLines = 2,
                                )
                                if (range != null) {
                                    CaptionText(
                                        text = range.start.toString(),
                                        fontSize = 8.sp,
                                    )
                                }
                            }
                        }
                    }
                }
                if (total > courses.size) {
                    Spacer(modifier = GlanceModifier.height(2.dp))
                    CaptionText(text = "+${total - courses.size}", fontSize = 8.sp)
                }
            }
        }
    }
}

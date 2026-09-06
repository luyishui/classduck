package io.github.luyishui.classduck.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.text.FontWeight
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
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.time.LocalDate

/**
 * 4x2 双栏日程流卡片。
 *
 * 左栏（约 1/3）：大字日期看板（日期 + 星期 + 学期周次 + 今日节数）；
 * 右栏（约 2/3）：今日课程流，从“正在进行/下一节”开始列出至多 3 节，
 * 正在上课的条目以柔黄高亮展示。
 */
class ClassDuckMediumWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Single

    private companion object {
        const val MAX_VISIBLE_COURSES = 3
    }

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = WidgetScheduleData.fromSharedPreferences(context)
        val evaluation = ScheduleEvaluator.evaluate(data)
        // 预排下一次节点刷新（下一节课开始/正在上课结束/明日零点，取最早）。
        if (data != null && evaluation != null) {
            WidgetRefreshScheduler.scheduleNext(context, data, evaluation)
        }

        provideContent {
            WidgetRootCard(context) {
                Row(
                    modifier = GlanceModifier.fillMaxSize().padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    DashboardPanel(evaluation)
                    Spacer(modifier = GlanceModifier.width(10.dp))
                    CourseFlowPanel(
                        data,
                        evaluation,
                        modifier = GlanceModifier.defaultWeight(),
                    )
                }
            }
        }
    }

    @Composable
    private fun DashboardPanel(evaluation: WidgetEvaluation?) {
        // 无课表数据时也展示当前系统日期，保持日期看板始终可读。
        val today = evaluation?.today ?: LocalDate.now()
        Column(horizontalAlignment = Alignment.Start) {
            Row(verticalAlignment = Alignment.Bottom) {
                    Text(
                        text = today.monthValue.toString(),
                        style = TextStyle(
                            color = ColorProvider(WidgetTheme.textMain),
                            fontSize = WidgetTheme.dateFontSize,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Text(
                        text = "/",
                        style = TextStyle(
                            color = ColorProvider(WidgetTheme.duckYellow),
                            fontSize = WidgetTheme.dateFontSize,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                    Text(
                        text = today.dayOfMonth.toString(),
                        style = TextStyle(
                            color = ColorProvider(WidgetTheme.textMain),
                            fontSize = WidgetTheme.dateFontSize,
                            fontWeight = FontWeight.Bold,
                        ),
                        maxLines = 1,
                    )
                }
            Spacer(modifier = GlanceModifier.height(3.dp))
            CaptionText(
                text = evaluation?.let { ScheduleEvaluator.weekdayLabel(it.weekdayIso) } ?: "",
                color = WidgetTheme.textMain,
            )
            if (evaluation != null) {
                val weekLabel = ScheduleEvaluator.weekLabel(evaluation.currentWeek)
                if (weekLabel.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(1.dp))
                    CaptionText(text = weekLabel)
                }
                if (evaluation.todayCourses.isNotEmpty()) {
                    Spacer(modifier = GlanceModifier.height(1.dp))
                    CaptionText(text = "今日 ${evaluation.todayCourses.size} 节课")
                }
            }
        }
    }

    @Composable
    private fun CourseFlowPanel(
        data: WidgetScheduleData?,
        evaluation: WidgetEvaluation?,
        modifier: GlanceModifier = GlanceModifier,
    ) {
        val current = evaluation
        if (data == null || current == null) {
            Box(modifier = modifier) {
                EmptyStateContent(message = "暂无课表数据", hint = "打开上课鸭同步")
            }
            return
        }

        val courses = current.upcomingCourses.take(MAX_VISIBLE_COURSES)
        if (courses.isEmpty()) {
            Box(modifier = modifier) {
                when (current.status) {
                    WidgetScheduleStatus.NOT_STARTED ->
                        EmptyStateContent(message = "还未开学", hint = "假期愉快～")
                    WidgetScheduleStatus.SEMESTER_ENDED ->
                        EmptyStateContent(message = "学期已结束", hint = "期待下学期见")
                    WidgetScheduleStatus.ALL_DONE ->
                        EmptyStateContent(message = "今日课程已结束", hint = "好好休息～")
                    WidgetScheduleStatus.NO_DATA ->
                        EmptyStateContent(message = "暂无课表数据", hint = "打开上课鸭同步")
                    else -> EmptyStateContent(message = "今日无课", hint = "好好休息～")
                }
            }
            return
        }

        Column(modifier = modifier) {
            courses.forEachIndexed { index, course ->
                if (index > 0) {
                    Spacer(modifier = GlanceModifier.height(4.dp))
                }
                val isOngoing = course == current.ongoing
                Box(
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .background(if (isOngoing) WidgetTheme.duckYellowSoft else WidgetTheme.surface)
                        .cornerRadius(8.dp),
                ) {
                    Column(modifier = GlanceModifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 5.dp)) {
                        CourseRow(
                            course = course,
                            subtitle = courseSubtitle(course, data),
                            highlight = isOngoing,
                        )
                    }
                }
            }
            val remaining = current.upcomingCourses.size - courses.size
            if (remaining > 0) {
                Spacer(modifier = GlanceModifier.height(3.dp))
                CaptionText(text = "还有 $remaining 节课程")
            }
        }
    }
}

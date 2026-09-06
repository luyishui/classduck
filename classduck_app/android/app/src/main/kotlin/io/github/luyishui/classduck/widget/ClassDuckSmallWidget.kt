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
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.time.LocalDate

/**
 * 2x2 单日聚焦卡片。
 *
 * 顶部：左侧大字日期（斜杠用鸭鸭黄点缀），右侧星期与当日节数；
 * 主体：聚焦“正在上课 / 下一节课”，空态展示鸭鸭徽标与温馨文案。
 */
class ClassDuckSmallWidget : GlanceAppWidget() {

    override val sizeMode: SizeMode = SizeMode.Single

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val data = WidgetScheduleData.fromSharedPreferences(context)
        val evaluation = ScheduleEvaluator.evaluate(data)
        // 预排下一次节点刷新（下一节课开始/正在上课结束/明日零点，取最早）。
        if (data != null && evaluation != null) {
            WidgetRefreshScheduler.scheduleNext(context, data, evaluation)
        }

        provideContent {
            WidgetRootCard(context) {
                Column(
                    modifier = GlanceModifier.fillMaxSize().padding(12.dp),
                ) {
                    HeaderSection(evaluation)
                    Spacer(modifier = GlanceModifier.height(8.dp))
                    FocusSection(data, evaluation)
                }
            }
        }
    }

    @Composable
    private fun HeaderSection(evaluation: WidgetEvaluation?) {
        // 无课表数据时也展示当前系统日期，保持日期看板始终可读。
        val today = evaluation?.today ?: LocalDate.now()
        Row(verticalAlignment = Alignment.CenterVertically) {
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
            Spacer(modifier = GlanceModifier.defaultWeight())
            Column(horizontalAlignment = Alignment.End) {
                CaptionText(
                    text = evaluation?.let { ScheduleEvaluator.weekdayLabel(it.weekdayIso) }
                        ?: "",
                    color = WidgetTheme.textMain,
                )
                CaptionText(text = countText(evaluation))
            }
        }
    }

    private fun countText(evaluation: WidgetEvaluation?): String {
        if (evaluation == null) {
            return "暂无数据"
        }
        return when (evaluation.status) {
            WidgetScheduleStatus.ONGOING,
            WidgetScheduleStatus.NEXT_UP,
            WidgetScheduleStatus.ALL_DONE,
            -> "${evaluation.todayCourses.size}节课"
            WidgetScheduleStatus.NOT_STARTED -> "未开学"
            WidgetScheduleStatus.SEMESTER_ENDED -> "假期中"
            WidgetScheduleStatus.NO_DATA -> "暂无数据"
            else -> "今日无课"
        }
    }

    @Composable
    private fun FocusSection(data: WidgetScheduleData?, evaluation: WidgetEvaluation?) {
        val current = evaluation
        if (data == null || current == null) {
            EmptyStateContent(message = "暂无课表数据", hint = "打开上课鸭同步")
            return
        }

        val focused = current.ongoing ?: current.next
        if (focused != null) {
            val isOngoing = current.ongoing != null
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(if (isOngoing) WidgetTheme.duckYellowSoft else WidgetTheme.surface)
                    .cornerRadius(WidgetTheme.cardRadius),
                contentAlignment = Alignment.CenterStart,
            ) {
                Column(modifier = GlanceModifier.fillMaxSize().padding(10.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CaptionText(
                            text = if (isOngoing) "正在上课" else "下一节课",
                            color = WidgetTheme.textMuted,
                        )
                    }
                    Spacer(modifier = GlanceModifier.height(4.dp))
                    CourseRow(
                        course = focused,
                        subtitle = courseSubtitle(focused, data),
                        highlight = isOngoing,
                    )
                }
            }
            return
        }

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

}

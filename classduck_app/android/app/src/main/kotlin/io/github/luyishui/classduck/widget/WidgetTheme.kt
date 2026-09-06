package io.github.luyishui.classduck.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.glance.text.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.github.luyishui.classduck.MainActivity
import io.github.luyishui.classduck.R

/**
 * 与 Flutter 端 AppTokens 保持 1:1 契约的视觉常量（色板来源
 * lib/shared/theme/app_tokens.dart），以及三种规格小组件共享的组件。
 */
object WidgetTheme {
    /** 奶油米白底色（pageBackground）。 */
    val pageBackground: Color = Color(0xFFFFFDF8)

    /** 纯白卡片容器（surface）。 */
    val surface: Color = Color(0xFFFFFFFF)

    /** 鸭鸭金黄（duckYellow）：日期斜杠点缀、今日列头高亮。 */
    val duckYellow: Color = Color(0xFFFFC93C)

    /** 柔黄背景（duckYellowSoft）：正在上课高亮底色。 */
    val duckYellowSoft: Color = Color(0xFFFFF4CC)

    /** 主要文字（textMain）：温润深灰棕。 */
    val textMain: Color = Color(0xFF40352A)

    /** 次级文字（textMuted）：灰棕说明色。 */
    val textMuted: Color = Color(0xFFA3978A)

    /** 浅色网格线（borderLight）。 */
    val borderLight: Color = Color(0xFFE8DFD2)

    /** 多日网格空白列的轻底色。 */
    val gridEmptyBackground: Color = Color(0xFFFBF7EF)

    /** 外部容器大圆角：贴合现代 Launcher 小组件外框。 */
    val outerRadius: Dp = 24.dp

    /** 内部小卡片圆角。 */
    val cardRadius: Dp = 12.dp

    /** 大号看板日期字号。 */
    val dateFontSize: TextUnit = 26.sp

    /** 课程标题字号。 */
    val courseTitleFontSize: TextUnit = 13.sp

    /** 时间与地点标签字号。 */
    val captionFontSize: TextUnit = 11.sp

    /** 小组件点击拉起 App 的深链（AppShell 监听该 scheme 并按 tab 参数直达课表）。 */
    val launchUri: Uri = Uri.parse("classduck://schedule?tab=1")

    /** 解析 "#RRGGBB" 课程色；非法时回退品牌金。 */
    fun parseCourseColor(hex: String?): Color {
        if (hex.isNullOrBlank()) {
            return duckYellow
        }
        val normalized = hex.removePrefix("#").uppercase()
        if (normalized.length != 6) {
            return duckYellow
        }
        return try {
            Color(android.graphics.Color.parseColor("#$normalized"))
        } catch (_: IllegalArgumentException) {
            duckYellow
        }
    }
}

/**
 * 点击小组件任意区域 → 拉起 MainActivity 直达课表。
 *
 * Intent 采用计划第 6 节的约定：携带 home_widget 插件约定的拉起 action
 * （App 端据此识别"由小组件拉起"）、语义化深链 data Uri，并显式赋予
 * NEW_TASK | CLEAR_TOP 标志，规避部分定制系统（MIUI/ColorOS）从
 * 广播/桌面环境拉起 Activity 的兼容问题。
 */
fun openAppAction(context: Context): Action {
    val intent = Intent(context, MainActivity::class.java).apply {
        action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        data = WidgetTheme.launchUri
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    }
    return actionStartActivity(intent)
}

/** 统一的外层卡片：奶油米白底、24dp 大圆角、整体可点击打开 App。 */
@Composable
fun WidgetRootCard(
    context: Context,
    content: @Composable () -> Unit,
) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetTheme.pageBackground)
            .cornerRadius(WidgetTheme.outerRadius)
            .clickable(openAppAction(context)),
        contentAlignment = Alignment.CenterStart,
    ) {
        content()
    }
}

/** 课程左侧彩色圆点标志。 */
@Composable
fun CourseColorDot(hex: String?, size: Dp = 8.dp) {
    Box(
        modifier = GlanceModifier
            .size(size)
            .cornerRadius(size / 2)
            .background(WidgetTheme.parseCourseColor(hex)),
    ) {}
}

/** 主标题文字（课程名等）。 */
@Composable
fun MainText(
    text: String,
    fontSize: TextUnit = WidgetTheme.courseTitleFontSize,
    maxLines: Int = 1,
) {
    Text(
        text = text,
        modifier = GlanceModifier,
        style = TextStyle(
            color = ColorProvider(WidgetTheme.textMain),
            fontSize = fontSize,
            fontWeight = FontWeight.Bold,
        ),
        maxLines = maxLines,
    )
}

/** 次级说明文字（时间/地点/统计等）。 */
@Composable
fun CaptionText(
    text: String,
    fontSize: TextUnit = WidgetTheme.captionFontSize,
    color: Color = WidgetTheme.textMuted,
    maxLines: Int = 1,
) {
    Text(
        text = text,
        modifier = GlanceModifier,
        style = TextStyle(
            color = ColorProvider(color),
            fontSize = fontSize,
        ),
        maxLines = maxLines,
    )
}

/**
 * 课程条目：彩点 + 课程名 +（可选）两行说明。
 * 供 2x2 聚焦卡片与 4x2 日程流复用。
 */
@Composable
fun CourseRow(
    course: WidgetCourse,
    subtitle: String?,
    highlight: Boolean,
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        CourseColorDot(course.colorHex)
        Spacer(modifier = GlanceModifier.width(8.dp))
        Column {
            MainText(text = course.name)
            if (!subtitle.isNullOrBlank()) {
                Spacer(modifier = GlanceModifier.height(1.dp))
                CaptionText(text = subtitle)
            }
        }
    }
}

/**
 * 空状态：鸭鸭徽标 + 温馨文案。
 * 覆盖今日无课、假期、未开学、暂无数据等场景。
 */
@Composable
fun EmptyStateContent(message: String, hint: String?) {
    Column(
        modifier = GlanceModifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        androidx.glance.Image(
            provider = androidx.glance.ImageProvider(R.drawable.widget_duck_logo),
            contentDescription = null,
            modifier = GlanceModifier.size(34.dp).cornerRadius(10.dp),
        )
        Spacer(modifier = GlanceModifier.height(8.dp))
        Text(
            text = message,
            style = TextStyle(
                color = ColorProvider(WidgetTheme.textMain),
                fontSize = WidgetTheme.courseTitleFontSize,
                fontWeight = FontWeight.Medium,
            ),
            maxLines = 1,
        )
        if (!hint.isNullOrBlank()) {
            Spacer(modifier = GlanceModifier.height(2.dp))
            CaptionText(text = hint)
        }
    }
}

/** 课程的时间副标题：起止时刻 + 教室。 */
fun courseSubtitle(course: WidgetCourse, data: WidgetScheduleData): String? {
    val range = ScheduleEvaluator.courseTimeRange(data, course) ?: return null
    val room = course.classroom
    val timeText = "${range.start} - ${range.end}"
    return if (room.isNullOrBlank()) timeText else "$timeText  $room"
}

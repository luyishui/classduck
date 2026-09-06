package io.github.luyishui.classduck.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.updateAll
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.ZoneId

/**
 * 小组件的轻量主动刷新机制（零常驻后台）：
 *
 * 1. [WidgetTimeChangeReceiver]：监听系统 DATE_CHANGED / TIME_SET /
 *    TIMEZONE_CHANGED 广播，覆盖跨天、校时、时区切换三类场景；
 * 2. [WidgetRefreshScheduler]：在每次渲染时预排一个「下一节课节点」的
 *    一次性闹钟（下一节开始 / 正在上课结束 / 明日零点，取最早者），
 *    驱动上下课状态即时切换。闹钟使用 RTC（非唤醒型）：亮屏使用时准时
 *    触发，息屏期间顺延到下次亮屏，不唤醒设备、不额外耗电；
 *    且每次渲染都会重排，闹钟丢失具备自愈能力（30 分钟周期刷新兜底）。
 */
object WidgetRefreshScheduler {
    private const val REQUEST_CODE = 0x4455

    /** 预排下一次刷新闹钟；重复调用会替换上一次的排期（全局仅一个在途闹钟）。 */
    fun scheduleNext(
        context: Context,
        data: WidgetScheduleData,
        evaluation: WidgetEvaluation,
    ) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                ?: return
        val next = ScheduleEvaluator.nextRefreshTime(
            data,
            evaluation,
            LocalDateTime.now(),
        ) ?: return
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, WidgetRefreshAlarmReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pendingIntent)
        alarmManager.set(
            AlarmManager.RTC,
            next.atZone(ZoneId.systemDefault()).toInstant().toEpochMilli(),
            pendingIntent,
        )
    }

    /** 三个规格的小组件一并重绘。 */
    suspend fun updateAllWidgets(context: Context) {
        ClassDuckSmallWidget().updateAll(context)
        ClassDuckMediumWidget().updateAll(context)
        ClassDuckLargeWidget().updateAll(context)
    }
}

/** 系统跨天/校时/时区广播 → 重绘全部小组件（渲染时读取本地时钟，天然准确）。 */
class WidgetTimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            -> dispatchUpdate(context.applicationContext, goAsync())
        }
    }
}

/** 节点闹钟触发 → 重绘全部小组件。 */
class WidgetRefreshAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        dispatchUpdate(context.applicationContext, goAsync())
    }
}

private fun dispatchUpdate(context: Context, pendingResult: BroadcastReceiver.PendingResult) {
    CoroutineScope(Dispatchers.Default).launch {
        try {
            WidgetRefreshScheduler.updateAllWidgets(context)
        } finally {
            pendingResult.finish()
        }
    }
}

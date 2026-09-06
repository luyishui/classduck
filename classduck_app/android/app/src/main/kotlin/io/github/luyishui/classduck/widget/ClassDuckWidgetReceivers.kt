package io.github.luyishui.classduck.widget

import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver

/**
 * 三种规格的小组件接收器。
 *
 * AndroidManifest.xml 中各自注册了对应的 appwidget-provider 元数据；
 * Flutter 端通过 home_widget 的 updateWidget 发送 APPWIDGET_UPDATE
 * 广播触发 onUpdate → Glance 重新执行 provideGlance 完成刷新。
 */
class ClassDuckSmallWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassDuckSmallWidget()
}

class ClassDuckMediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassDuckMediumWidget()
}

class ClassDuckLargeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ClassDuckLargeWidget()
}

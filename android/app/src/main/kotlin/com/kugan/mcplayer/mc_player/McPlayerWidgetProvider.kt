package com.kugan.mcplayer.mc_player

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.KeyEvent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Compact 4x1 home-screen control bar. Track info is pushed here from Dart via
 * the home_widget plugin's SharedPreferences bridge; button taps are sent as
 * standard Android media-button broadcasts straight to audio_service's own
 * MediaButtonReceiver — the same path headset buttons use — so no custom
 * background-isolate plumbing is needed to actually control playback.
 */
class McPlayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.mc_player_widget)

            val title = widgetData.getString("title", null) ?: "MC Player"
            val artist = widgetData.getString("artist", null) ?: "Tap Play All in the app to start"
            val isPlaying = widgetData.getBoolean("isPlaying", false)

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_artist, artist)
            views.setImageViewResource(
                R.id.widget_btn_play_pause,
                if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
            )

            views.setOnClickPendingIntent(
                R.id.widget_btn_previous,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PREVIOUS, appWidgetId * 10 + 1)
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_play_pause,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, appWidgetId * 10 + 2)
            )
            views.setOnClickPendingIntent(
                R.id.widget_btn_next,
                mediaButtonPendingIntent(context, KeyEvent.KEYCODE_MEDIA_NEXT, appWidgetId * 10 + 3)
            )

            // Tapping the track info opens the app to Now Playing.
            val openAppIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_track_info, openAppIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun mediaButtonPendingIntent(context: Context, keyCode: Int, requestCode: Int): PendingIntent {
        val downIntent = Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            component = ComponentName(context, "com.ryanheise.audioservice.MediaButtonReceiver")
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            downIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}

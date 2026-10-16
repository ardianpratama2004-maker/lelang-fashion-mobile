package com.example.pelelangan_produk_fashion

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver as AndroidBroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import java.util.Calendar
import java.util.TimeZone

internal object DailyReminderScheduler {
    private const val PREFERENCES_NAME = "lelang_daily_reminder"
    private const val ENABLED_KEY = "enabled"
    private const val CHANNEL_ID = "daily_auction_reminder"
    private const val NOTIFICATION_ID = 19001
    private const val REQUEST_CODE = 19001
    private const val ACTION_REMINDER = "com.example.pelelangan_produk_fashion.DAILY_REMINDER"

    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .getBoolean(ENABLED_KEY, false)

    fun hasNotificationPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (!manager.areNotificationsEnabled()) return false
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                manager.getNotificationChannel(CHANNEL_ID)?.importance == NotificationManager.IMPORTANCE_NONE
            ) {
                return false
            }
        }
        return true
    }

    fun enable(context: Context) {
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(ENABLED_KEY, true)
            .apply()
        scheduleNext(context)
    }

    fun disable(context: Context) {
        context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(ENABLED_KEY, false)
            .apply()
        alarmManager(context)?.cancel(reminderPendingIntent(context))
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    fun rescheduleIfEnabled(context: Context) {
        if (!isEnabled(context)) return
        if (hasNotificationPermission(context)) {
            scheduleNext(context)
        } else {
            disable(context)
        }
    }

    fun scheduleNext(context: Context) {
        if (!isEnabled(context)) return
        if (!hasNotificationPermission(context)) {
            disable(context)
            return
        }

        val jakarta = TimeZone.getTimeZone("Asia/Jakarta")
        val next = Calendar.getInstance(jakarta).apply {
            set(Calendar.HOUR_OF_DAY, 19)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        val manager = alarmManager(context) ?: return
        val pendingIntent = reminderPendingIntent(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            manager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                next.timeInMillis,
                pendingIntent,
            )
        } else {
            manager.set(AlarmManager.RTC_WAKEUP, next.timeInMillis, pendingIntent)
        }
    }

    fun showReminder(context: Context) {
        if (!isEnabled(context)) return
        if (!hasNotificationPermission(context)) {
            disable(context)
            return
        }
        postNotification(context)
        scheduleNext(context)
    }

    private fun postNotification(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Pengingat lelang",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ).apply {
                    description = "Pengingat harian untuk membuka lelang di Lelang Fashion."
                },
            )
        }

        val openApp = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(MainActivity.EXTRA_REMINDER_TAP, true)
        }
        val activityFlags = PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        val contentIntent = PendingIntent.getActivity(
            context,
            REQUEST_CODE,
            openApp,
            activityFlags,
        )

        val notificationBuilder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
        val notification = notificationBuilder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Lelang Fashion")
            .setContentText("Ada lelang menarik. Buka aplikasi dan temukan barang favoritmu.")
            .setColor(Color.rgb(23, 58, 43))
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun alarmManager(context: Context): AlarmManager? =
        context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager

    private fun reminderPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, DailyReminderReceiver::class.java).setAction(ACTION_REMINDER)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
    }

    private fun immutableFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
}

class DailyReminderReceiver : AndroidBroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        DailyReminderScheduler.showReminder(context)
    }
}

class ReminderRescheduleReceiver : AndroidBroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        DailyReminderScheduler.rescheduleIfEnabled(context)
    }
}

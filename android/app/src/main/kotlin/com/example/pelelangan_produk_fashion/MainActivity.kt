package com.example.pelelangan_produk_fashion

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var reminderChannel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        reminderChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeInitialReminderTap" -> result.success(consumeReminderTap(intent))
                    "getReminderStatus" -> {
                        val permissionGranted =
                            DailyReminderScheduler.hasNotificationPermission(this)
                        if (!permissionGranted && DailyReminderScheduler.isEnabled(this)) {
                            DailyReminderScheduler.disable(this)
                        }
                        result.success(
                            mapOf(
                                "enabled" to DailyReminderScheduler.isEnabled(this),
                                "permissionGranted" to permissionGranted,
                            ),
                        )
                    }
                    "enableDailyReminder" -> enableReminder(result)
                    "disableDailyReminder" -> {
                        DailyReminderScheduler.disable(this)
                        result.success(null)
                    }
                    "openNotificationSettings" -> {
                        openNotificationSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        DailyReminderScheduler.rescheduleIfEnabled(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (consumeReminderTap(intent)) {
            reminderChannel?.invokeMethod("openAuctionsFromReminder", null)
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_POST_NOTIFICATIONS) return

        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            DailyReminderScheduler.hasNotificationPermission(this)
        if (granted) DailyReminderScheduler.enable(this)
        result.success(granted)
    }

    private fun enableReminder(result: MethodChannel.Result) {
        if (DailyReminderScheduler.hasNotificationPermission(this)) {
            DailyReminderScheduler.enable(this)
            result.success(true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingPermissionResult != null) {
                result.error("permission_request_in_progress", "Notification permission request is already open.", null)
                return
            }
            pendingPermissionResult = result
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_POST_NOTIFICATIONS,
            )
            return
        }

        result.success(false)
    }

    private fun openNotificationSettings() {
        val settingsIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        }
        startActivity(settingsIntent)
    }

    private fun consumeReminderTap(sourceIntent: Intent?): Boolean {
        if (sourceIntent?.getBooleanExtra(EXTRA_REMINDER_TAP, false) != true) return false
        sourceIntent.removeExtra(EXTRA_REMINDER_TAP)
        return true
    }

    companion object {
        private const val CHANNEL_NAME = "com.example.pelelangan_produk_fashion/daily_reminder"
        private const val REQUEST_POST_NOTIFICATIONS = 4719
        const val EXTRA_REMINDER_TAP = "daily_reminder_tap"
    }
}

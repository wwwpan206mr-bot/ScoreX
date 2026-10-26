package com.scorex.app.scorex

import android.app.Activity
import android.os.Build
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Play distribution has no APK downloader, FileProvider or install permission. */
class UpdateBridge(private val activity: Activity) {
    private val manager = AppUpdateManagerFactory.create(activity)
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "platform" -> result.success(mapOf("distribution" to "play", "abis" to Build.SUPPORTED_ABIS.toList()))
            "checkPlay" -> manager.appUpdateInfo.addOnSuccessListener { info ->
                result.success(mapOf("available" to (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                    info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)), "versionCode" to info.availableVersionCode()))
            }.addOnFailureListener { result.error("PLAY_UNAVAILABLE", "Play updates are unavailable for this installation.", null) }
            "startPlay" -> manager.appUpdateInfo.addOnSuccessListener { info ->
                try { result.success(manager.startUpdateFlowForResult(info, activity,
                    AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(), 4102)) }
                catch (e: Exception) { result.error("PLAY_UPDATE_FAILED", e.message, null) }
            }.addOnFailureListener { result.error("PLAY_UPDATE_FAILED", it.message, null) }
            else -> result.notImplemented()
        }
    }
    fun onResume() {
        manager.appUpdateInfo.addOnSuccessListener { info ->
            if (info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS)
                runCatching { manager.startUpdateFlowForResult(info, activity,
                    AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(), 4102) }
        }
    }
    fun close() {}
}

package com.scorex.app.scorex

import android.app.Activity
import android.app.DownloadManager
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class UpdateBridge(private val activity: Activity) {
    private val downloads = activity.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private val prefs = activity.getSharedPreferences("scorex_updates", Context.MODE_PRIVATE)
    private val executor = Executors.newSingleThreadExecutor()
    private var closed = false
    @Suppress("DEPRECATION")
    private fun code(info: PackageInfo) = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    @Suppress("DEPRECATION")
    private fun packageInfo(path: String? = null): PackageInfo {
        val flags = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        return (if (path == null) activity.packageManager.getPackageInfo(activity.packageName, flags)
                else activity.packageManager.getPackageArchiveInfo(path, flags)) ?: error("APK is invalid")
    }
    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): Set<String> {
        val list = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        return list?.map { signature -> signature.toCharsString() }?.toSet() ?: emptySet()
    }
    private fun canInstall() = Build.VERSION.SDK_INT < 26 || activity.packageManager.canRequestPackageInstalls()
    private fun apkFile(): File {
        val root = File(activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: error("Storage unavailable"), "updates")
        val name = prefs.getString("file", "") ?: ""
        require(Regex("^scorex-[0-9]+-[a-f0-9]{12}\\.apk$").matches(name)) { "No downloaded update" }
        return File(root, name).canonicalFile.also { require(it.parentFile == root.canonicalFile) }
    }
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "platform" -> result.success(mapOf("distribution" to "github", "abis" to Build.SUPPORTED_ABIS.toList(),
                    "versionCode" to code(packageInfo()), "versionName" to packageInfo().versionName))
                "download" -> {
                    val url = call.argument<String>("url") ?: ""
                    val sha = call.argument<String>("sha256") ?: ""
                    val size = call.argument<Number>("size")?.toLong() ?: 0
                    val target = call.argument<Number>("versionCode")?.toLong() ?: 0
                    require(UpdatePolicy.trustedUrl(url) && Regex("^[a-f0-9]{64}$").matches(sha)) { "Untrusted update" }
                    require(size in 1..UpdatePolicy.MAX_BYTES && target > code(packageInfo())) { "Invalid update version or size" }
                    if (prefs.getString("url", null) == url && prefs.getString("sha", null) == sha &&
                        progress()["state"] in listOf("downloading", "paused", "ready")) {
                        result.success(progress()); return
                    }
                    cancel()
                    val root = File(activity.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: error("Storage unavailable"), "updates")
                    root.mkdirs()
                    // Only updater-owned files in a restricted private directory are cleaned.
                    root.listFiles()?.filter { it.name.startsWith("scorex-") && it.extension == "apk" }?.forEach { it.delete() }
                    val name = "scorex-$target-${sha.take(12)}.apk"
                    val request = DownloadManager.Request(Uri.parse(url))
                        .setTitle("ScoreX update").setDescription("Downloading the new ScoreX APK")
                        .setMimeType("application/vnd.android.package-archive")
                        .setAllowedOverMetered(true).setAllowedOverRoaming(false)
                        .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                        .setDestinationInExternalFilesDir(activity, Environment.DIRECTORY_DOWNLOADS, "updates/$name")
                    val id = downloads.enqueue(request)
                    prefs.edit().putLong("id", id).putString("url", url).putString("sha", sha)
                        .putLong("size", size).putLong("version", target).putString("file", name).apply()
                    result.success(progress())
                }
                "progress" -> result.success(progress())
                "cancel" -> { cancel(); result.success(null) }
                "allowInstalls" -> {
                    if (Build.VERSION.SDK_INT >= 26 && !canInstall()) activity.startActivity(
                        Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "install" -> {
                    if (!canInstall()) { result.success(mapOf("state" to "permission")); return }
                    require(progress()["state"] == "ready") { "Download is not complete" }
                    executor.execute {
                        try {
                            val file = apkFile()
                            require(file.length() == prefs.getLong("size", 0)) { "Downloaded APK size does not match" }
                            require(UpdatePolicy.sha256(file) == prefs.getString("sha", null)) { "Downloaded APK checksum does not match" }
                            val incoming = packageInfo(file.path)
                            val installed = packageInfo()
                            require(code(incoming) == prefs.getLong("version", 0) &&
                                UpdatePolicy.compatible(incoming.packageName, activity.packageName, code(incoming),
                                    code(installed), signers(incoming), signers(installed))) {
                                "This APK cannot update the installed app. The package, version or signing key differs."
                            }
                            activity.runOnUiThread {
                                if (closed) return@runOnUiThread
                                try {
                                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
                                    activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                                        setDataAndType(uri, "application/vnd.android.package-archive")
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                        clipData = ClipData.newRawUri("ScoreX APK update", uri)
                                    })
                                    result.success(mapOf("state" to "installer"))
                                } catch (e: Exception) { result.error("INSTALL_FAILED", e.message, null) }
                            }
                        } catch (e: Exception) {
                            activity.runOnUiThread { if (!closed) result.error("INVALID_APK", e.message, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) { result.error("UPDATE_FAILED", e.message, null) }
    }
    private fun progress(): Map<String, Any> {
        val id = prefs.getLong("id", -1)
        if (id < 0) return mapOf("state" to "idle")
        downloads.query(DownloadManager.Query().setFilterById(id))?.use { cursor ->
            if (!cursor.moveToFirst()) return mapOf("state" to "idle")
            fun number(column: String) = cursor.getLong(cursor.getColumnIndexOrThrow(column))
            val state = when (number(DownloadManager.COLUMN_STATUS).toInt()) {
                DownloadManager.STATUS_SUCCESSFUL -> "ready"
                DownloadManager.STATUS_FAILED -> "failed"
                DownloadManager.STATUS_PAUSED -> "paused"
                else -> "downloading"
            }
            return mapOf("state" to state, "received" to number(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR),
                "total" to number(DownloadManager.COLUMN_TOTAL_SIZE_BYTES), "url" to (prefs.getString("url", "") ?: ""))
        }
        return mapOf("state" to "idle")
    }
    private fun cancel() {
        val id = prefs.getLong("id", -1)
        if (id >= 0) downloads.remove(id)
        prefs.edit().clear().apply()
    }
    fun onResume() {} // Flutter polls the persisted DownloadManager job when visible.
    fun close() { closed = true; executor.shutdown() } // The OS download continues independently.
}

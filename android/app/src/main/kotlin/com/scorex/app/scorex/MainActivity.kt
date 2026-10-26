package com.scorex.app.scorex

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var updater: UpdateBridge? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        updater = UpdateBridge(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "scorex/updates")
            .setMethodCallHandler { call, result -> updater!!.handle(call, result) }
    }
    override fun onResume() {
        super.onResume()
        updater?.onResume()
    }
    override fun onDestroy() {
        updater?.close()
        super.onDestroy()
    }
}

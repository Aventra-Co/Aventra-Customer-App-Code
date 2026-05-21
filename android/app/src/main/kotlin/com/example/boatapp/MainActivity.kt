package com.app.boatappcustomer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val badgeChannelName = "com.aventra.app/badge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, badgeChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setBadge" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}

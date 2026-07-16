package com.nodly.nodly

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.nodly.nodly/quick_add"
    private var methodChannel: MethodChannel? = null
    private var pendingQuickAdd = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (intent?.action == "com.nodly.nodly.QUICK_ADD") {
            pendingQuickAdd = true
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "checkQuickAdd") {
                val shouldAdd = pendingQuickAdd || (intent?.action == "com.nodly.nodly.QUICK_ADD")
                if (shouldAdd) {
                    pendingQuickAdd = false
                    intent?.action = null
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == "com.nodly.nodly.QUICK_ADD") {
            pendingQuickAdd = true
            methodChannel?.invokeMethod("triggerQuickAdd", null)
            intent.action = null
        }
    }
}

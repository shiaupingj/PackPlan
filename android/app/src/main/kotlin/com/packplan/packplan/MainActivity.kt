package com.packplan.packplan

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val shareChannel = "com.packplan.packplan/system_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            shareChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "shareText") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val text = call.argument<String>("text")
            val subject = call.argument<String>("subject")
            if (text.isNullOrBlank()) {
                result.error("invalid_arguments", "Share text cannot be empty.", null)
                return@setMethodCallHandler
            }

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"
                putExtra(Intent.EXTRA_TEXT, text)
                if (!subject.isNullOrBlank()) {
                    putExtra(Intent.EXTRA_SUBJECT, subject)
                }
            }
            startActivity(Intent.createChooser(intent, subject ?: "分享 PackPlan 清單"))
            result.success(null)
        }
    }
}

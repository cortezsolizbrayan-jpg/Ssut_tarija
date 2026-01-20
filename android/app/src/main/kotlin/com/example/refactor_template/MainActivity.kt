package com.example.refactor_template

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private lateinit var paddleOcr: PaddleOcrEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        paddleOcr = PaddleOcrEngine(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "paddle_ocr")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "runOcr" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("bad_args", "Missing image path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val response = paddleOcr.runOcr(path)
                            result.success(response)
                        } catch (e: Exception) {
                            result.error("ocr_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

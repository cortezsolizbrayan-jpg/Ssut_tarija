package com.example.refactor_template

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ExifInterface
import com.baidu.paddle.lite.demo.ocr.Predictor
import com.baidu.paddle.lite.demo.ocr.Utils

class PaddleOcrEngine(private val context: Context) {
    private val predictor = Predictor()
    private var initialized = false

    private fun ensureInitialized(): Boolean {
        if (initialized) return true
        val ok = predictor.init(
            context,
            "models/ch_PP-OCRv2",
            "labels/ppocr_keys_v1.txt",
            0,
            2,
            "LITE_POWER_HIGH",
            960,
            0.1f,
        )
        initialized = ok
        return ok
    }

    fun runOcr(imagePath: String): Map<String, Any> {
        if (!ensureInitialized()) {
            return mapOf("ok" to false, "error" to "PaddleOCR init failed")
        }
        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: return mapOf("ok" to false, "error" to "Image decode failed")

        val input = rotateIfNeeded(bitmap, imagePath)
        predictor.setInputImage(input)
        val results = predictor.runModelAndGetResults(1, 1, 1)

        val items = ArrayList<Map<String, Any>>()
        val lines = ArrayList<String>()
        for (res in results) {
            val text = res.label ?: ""
            if (text.isNotBlank()) lines.add(text.trim())
            val points = res.points.map { mapOf("x" to it.x, "y" to it.y) }
            items.add(
                mapOf(
                    "text" to text,
                    "confidence" to res.confidence.toDouble(),
                    "points" to points,
                    "clsLabel" to res.clsLabel,
                    "clsConfidence" to res.clsConfidence.toDouble(),
                ),
            )
        }

        return mapOf(
            "ok" to true,
            "text" to lines.joinToString("\n"),
            "items" to items,
            "inferenceMs" to predictor.inferenceTime().toDouble(),
            "postprocessMs" to predictor.postprocessTime().toDouble(),
        )
    }

    private fun rotateIfNeeded(bitmap: Bitmap, path: String): Bitmap {
        return try {
            val exif = ExifInterface(path)
            val orientation = exif.getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
            Utils.rotateBitmap(bitmap, orientation) ?: bitmap
        } catch (e: Exception) {
            bitmap
        }
    }
}

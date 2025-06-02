package com.example.qrush

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.qrush/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "addImageToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        addImageToGallery(filePath, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "File path was null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun addImageToGallery(filePath: String, result: MethodChannel.Result) {
        try {
            val file = File(filePath)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File doesn't exist: $filePath", null)
                return
            }

            // Use MediaScannerConnection to add the file to the gallery
            MediaScannerConnection.scanFile(
                context,
                arrayOf(filePath),
                arrayOf("image/png"),
                { path, uri ->
                    result.success("Image added to gallery: $uri")
                }
            )
        } catch (e: Exception) {
            result.error("GALLERY_ERROR", "Error adding image to gallery: ${e.message}", null)
        }
    }
}

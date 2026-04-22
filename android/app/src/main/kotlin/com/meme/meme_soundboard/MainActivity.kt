package com.meme.meme_soundboard

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    private val importChannelName = "com.meme.meme_soundboard/import"
    private val importPushChannelName = "com.meme.meme_soundboard/import_push"

    private var pendingUri: Uri? = null
    private var importPushChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        captureIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureIntent(intent)
        materializeAndPushToFlutter()
    }

    private fun captureIntent(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_VIEW -> {
                pendingUri = intent.data
            }
            Intent.ACTION_SEND -> {
                pendingUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        importPushChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            importPushChannelName,
        )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, importChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumePendingImport" -> {
                        result.success(materializePendingUri())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun queryDisplayName(uri: Uri): String? {
        val cursor = contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )
        cursor?.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) return it.getString(idx)
            }
        }
        return null
    }

    private fun materializePendingUri(): String? {
        val uri = pendingUri ?: return null
        pendingUri = null
        return try {
            val input = contentResolver.openInputStream(uri) ?: return null
            val display = queryDisplayName(uri)
            val baseName = display?.trim()?.takeIf { it.isNotEmpty() }
                ?: "import_${System.currentTimeMillis()}.msb"
            val safeName = if (baseName.lowercase().endsWith(".msb")) {
                baseName.replace(Regex("""[<>:"/\\|?*]"""), "_")
            } else {
                "${baseName.replace(Regex("""[<>:"/\\|?*]"""), "_")}.msb"
            }
            val out = File(
                cacheDir,
                "intent_import_${System.currentTimeMillis()}_$safeName",
            )
            FileOutputStream(out).use { fos -> input.use { src -> src.copyTo(fos) } }
            out.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun materializeAndPushToFlutter() {
        val path = materializePendingUri() ?: return
        importPushChannel?.invokeMethod(
            "pendingImport",
            path,
            object : MethodChannel.Result {
                override fun success(result: Any?) {}
                override fun error(
                    errorCode: String,
                    errorMessage: String?,
                    errorDetails: Any?,
                ) {
                }

                override fun notImplemented() {}
            },
        )
    }
}

package com.kugan.mcplayer.mc_player

import android.app.RecoverableSecurityException
import android.content.IntentSender
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Deletes media files through MediaStore's delete-request flow instead of raw
 * file I/O. Scoped storage (Android 10+) blocks direct File delete/rename on
 * files this app doesn't own, even with READ_MEDIA_AUDIO granted — the only
 * sanctioned way to remove a user's media file is to ask MediaStore to do it,
 * which shows the user a one-time system confirmation dialog.
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "com.kugan.mcplayer.mc_player/media_store"
    private val deleteRequestCode = 9001
    private var pendingDeleteResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteMediaItems" -> {
                    @Suppress("UNCHECKED_CAST")
                    val uris = (call.arguments as List<String>).map { Uri.parse(it) }
                    deleteMediaItems(uris, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun deleteMediaItems(uris: List<Uri>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                pendingDeleteResult = result
                startIntentSenderForResult(pendingIntent.intentSender, deleteRequestCode, null, 0, 0, 0)
            } catch (e: Exception) {
                result.error("DELETE_FAILED", e.message, null)
            }
            return
        }

        // Pre-R: attempt direct delete; on API 29 a RecoverableSecurityException
        // carries the same kind of user-consent IntentSender.
        try {
            var allDeleted = true
            for (uri in uris) {
                val rows = contentResolver.delete(uri, null, null)
                if (rows <= 0) allDeleted = false
            }
            result.success(allDeleted)
        } catch (e: RecoverableSecurityException) {
            pendingDeleteResult = result
            val intentSender: IntentSender = e.userAction.actionIntent.intentSender
            startIntentSenderForResult(intentSender, deleteRequestCode, null, 0, 0, 0)
        } catch (e: Exception) {
            result.error("DELETE_FAILED", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        if (requestCode == deleteRequestCode) {
            pendingDeleteResult?.success(resultCode == RESULT_OK)
            pendingDeleteResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}

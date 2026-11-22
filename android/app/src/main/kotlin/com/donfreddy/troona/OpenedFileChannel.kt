package com.donfreddy.troona

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Hands Dart the audio file the app was opened with ("Open with").
 *
 * The request is kept until Dart takes it: on a cold start the intent
 * arrives long before the app can play. It is kept for the process, like
 * the engine (audio_service keeps one), so an activity recreated before
 * Dart took it loses nothing. Dart is told when a new one comes
 * ("offered"), then takes it; the last one offered wins.
 *
 * Only the address is kept on the main thread; its provider is asked for
 * the name and size when Dart takes it, off the main thread: a provider
 * may be slow to answer (a cloud one, one whose process must start).
 */
class OpenedFileChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> {
                    val uri = pending
                    pending = null
                    if (uri == null) {
                        result.success(null)
                    } else {
                        val app = context.applicationContext
                        worker.execute {
                            val described = describe(app, uri)
                            main.post { result.success(described) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Keeps [intent]'s file when it is one this app opens. */
    fun offer(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        // Reopened from the recent apps, the launch intent comes again: the
        // file was already played.
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) return
        val uri = intent.data ?: return
        if (uri.scheme != ContentResolver.SCHEME_CONTENT &&
            uri.scheme != ContentResolver.SCHEME_FILE
        ) {
            return
        }
        pending = uri
        channel.invokeMethod("offered", null)
    }

    fun dispose() = channel.setMethodCallHandler(null)

    companion object {
        const val NAME = "troona/opened_file"
        private const val TAG = "OpenedFile"

        /** The address waiting for Dart, for the process. */
        @Volatile
        private var pending: Uri? = null

        private val worker = Executors.newSingleThreadExecutor()
        private val main = Handler(Looper.getMainLooper())

        /**
         * The address, and the name and size its provider gives. Dart finds
         * the MediaStore id in the address itself.
         */
        private fun describe(context: Context, uri: Uri): Map<String, Any?> {
            var name: String? = null
            var size: Long? = null
            try {
                if (uri.scheme == ContentResolver.SCHEME_FILE) {
                    val file = File(uri.path ?: "")
                    name = file.name
                    size = file.length().takeIf { file.exists() }
                } else {
                    context.contentResolver.query(
                        uri,
                        arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                        null,
                        null,
                        null,
                    )?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val nameAt = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            val sizeAt = cursor.getColumnIndex(OpenableColumns.SIZE)
                            if (nameAt >= 0 && !cursor.isNull(nameAt)) name = cursor.getString(nameAt)
                            if (sizeAt >= 0 && !cursor.isNull(sizeAt)) size = cursor.getLong(sizeAt)
                        }
                    }
                }
            } catch (e: Exception) {
                // A provider that refuses the query still gives the address.
                // The class only: a message may hold the file's name.
                Log.w(TAG, "Opened file not described: ${e.javaClass.simpleName}")
            }
            val described = mapOf("uri" to uri.toString(), "name" to name, "size" to size)
            // What each file manager sends is still to be seen on devices; file
            // names stay out of a release build's log.
            if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                Log.i(TAG, "Opened: $described")
            }
            return described
        }
    }
}

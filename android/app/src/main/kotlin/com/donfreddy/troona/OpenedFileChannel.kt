package com.donfreddy.troona

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hands Dart the audio file the app was opened with ("Open with").
 *
 * The request is kept until Dart takes it: on a cold start the intent
 * arrives long before the app can play. Dart is told when a new one
 * comes ("offered"), then takes it; the last one offered wins.
 */
class OpenedFileChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, NAME)
    private var pending: Map<String, Any?>? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> {
                    result.success(pending)
                    pending = null
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
        pending = describe(uri, intent.type)
        channel.invokeMethod("offered", null)
    }

    fun dispose() = channel.setMethodCallHandler(null)

    /** What Dart needs to find the song in the library. */
    private fun describe(uri: Uri, type: String?): Map<String, Any?> {
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
            Log.w(TAG, "Opened file not described: $e")
        }
        val described = mapOf(
            "uri" to uri.toString(),
            "mediaStoreId" to mediaStoreIdOf(uri),
            "name" to name,
            "size" to size,
            "type" to type,
        )
        // What each file manager sends is still to be seen on devices; file
        // names stay out of a release build's log.
        if ((context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            Log.i(TAG, "Opened: $described")
        }
        return described
    }

    /**
     * The MediaStore id an address carries, the same as the library's: a
     * MediaStore address (.../audio/media/<id>), or a document of the media
     * ("audio:<id>") or downloads ("msf:<id>") providers. Null otherwise.
     */
    private fun mediaStoreIdOf(uri: Uri): String? {
        if (uri.authority == MediaStore.AUTHORITY) {
            val segments = uri.pathSegments
            val at = segments.indexOf("audio")
            if (at >= 0 && segments.getOrNull(at + 1) == "media") {
                return segments.getOrNull(at + 2)?.takeIf { it.all(Char::isDigit) }
            }
            return null
        }
        if (!DocumentsContract.isDocumentUri(context, uri)) return null
        val id = try {
            DocumentsContract.getDocumentId(uri)
        } catch (e: IllegalArgumentException) {
            return null
        }
        val prefix = when (uri.authority) {
            MEDIA_DOCUMENTS -> "audio:"
            DOWNLOADS_DOCUMENTS -> "msf:"
            else -> return null
        }
        if (!id.startsWith(prefix)) return null
        return id.removePrefix(prefix).takeIf { it.isNotEmpty() && it.all(Char::isDigit) }
    }

    companion object {
        const val NAME = "troona/opened_file"
        private const val TAG = "OpenedFile"
        private const val MEDIA_DOCUMENTS = "com.android.providers.media.documents"
        private const val DOWNLOADS_DOCUMENTS = "com.android.providers.downloads.documents"
    }
}

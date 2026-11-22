package com.donfreddy.troona

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * The folder backups are written to, chosen once by the user through the
 * system's folder picker (the Storage Access Framework).
 *
 * It needs no storage permission on any Android version, and what it
 * writes stays when the app is uninstalled. The access is kept across
 * restarts (a persisted permission) until the user picks another folder,
 * or the folder is removed.
 *
 * Files cross the channel as local paths, not bytes: a backup can weigh
 * 20 MB. Every call but "pick" runs off the main thread, since a provider
 * may be slow to answer.
 */
class BackupFolderChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, NAME)

    /** The answer awaited from the folder picker. */
    private var picking: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pick" -> pick(result)
                "status" -> io(result) { status(call.uri()) }
                "release" -> io(result) { release(call.uri()) }
                "list" -> io(result) { list(call.uri()) }
                "write" -> io(result) {
                    write(call.uri(), call.argument<String>("name")!!, call.argument<String>("path")!!)
                }
                "read" -> io(result) { read(call.uri(), call.argument<String>("path")!!) }
                "delete" -> io(result) { delete(call.uri()) }
                else -> result.notImplemented()
            }
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (picking != null) {
            result.error("busy", "A folder is already being picked", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        try {
            activity.startActivityForResult(intent, REQUEST_PICK)
            picking = result
        } catch (e: Exception) {
            // No app answers the intent (some stripped-down phones).
            result.error("unavailable", e.javaClass.simpleName, null)
        }
    }

    /** Forwarded by the activity; true when the answer was this channel's. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = picking ?: return true
        picking = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
            return true
        }
        io(result) {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            resolver().takePersistableUriPermission(tree, flags)
            mapOf("uri" to tree.toString(), "name" to nameOf(tree))
        }
        return true
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        // The activity goes while the picker is open: Dart stops waiting.
        picking?.success(null)
        picking = null
    }

    /** The folder's name while this app may still write to it; else null. */
    private fun status(tree: Uri): Map<String, Any?>? {
        val granted = resolver().persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!granted) return null
        // Granted, but the folder may have been deleted since.
        val name: String? = try {
            nameOf(tree)
        } catch (e: Exception) {
            null
        }
        if (name == null) return null
        return mapOf("uri" to tree.toString(), "name" to name)
    }

    private fun release(tree: Uri): Boolean {
        val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        return try {
            resolver().releasePersistableUriPermission(tree, flags)
            true
        } catch (e: SecurityException) {
            false
        }
    }

    private fun list(tree: Uri): List<Map<String, Any?>> {
        val parent = DocumentsContract.getTreeDocumentId(tree)
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parent)
        val found = mutableListOf<Map<String, Any?>>()
        resolver().query(children, COLUMNS, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(3) == DocumentsContract.Document.MIME_TYPE_DIR) continue
                found += mapOf(
                    "id" to DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))
                        .toString(),
                    "name" to cursor.getString(1),
                    "size" to if (cursor.isNull(2)) null else cursor.getLong(2),
                    "modified" to if (cursor.isNull(4)) null else cursor.getLong(4),
                )
            }
        }
        return found
    }

    /**
     * A new document named [name] in the folder, holding the file at [path].
     * Half-written, it is deleted: a backup that cannot be read is worse
     * than none.
     */
    private fun write(tree: Uri, name: String, path: String): Map<String, Any?> {
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val document = DocumentsContract.createDocument(resolver(), parent, MIME, name)
            ?: throw IllegalStateException("Document not created")
        try {
            resolver().openOutputStream(document, "w")!!.use { out ->
                File(path).inputStream().use { it.copyTo(out) }
            }
        } catch (e: Exception) {
            try {
                DocumentsContract.deleteDocument(resolver(), document)
            } catch (_: Exception) {
            }
            throw e
        }
        var stored: Map<String, Any?> = mapOf("id" to document.toString(), "name" to name)
        resolver().query(document, COLUMNS, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                stored = mapOf(
                    "id" to document.toString(),
                    // The provider may have renamed it ("name (1).json").
                    "name" to cursor.getString(1),
                    "size" to if (cursor.isNull(2)) null else cursor.getLong(2),
                    "modified" to if (cursor.isNull(4)) null else cursor.getLong(4),
                )
            }
        }
        return stored
    }

    private fun read(document: Uri, path: String): Boolean {
        resolver().openInputStream(document)!!.use { input ->
            File(path).outputStream().use { input.copyTo(it) }
        }
        return true
    }

    private fun delete(document: Uri): Boolean =
        DocumentsContract.deleteDocument(resolver(), document)

    private fun nameOf(tree: Uri): String? {
        val document = DocumentsContract.buildDocumentUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        return resolver().query(
            document,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { if (it.moveToFirst()) it.getString(0) else null }
    }

    private fun resolver() = activity.applicationContext.contentResolver

    /** Runs [work] off the main thread and answers [result] on it. */
    private fun io(result: MethodChannel.Result, work: () -> Any?) {
        worker.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: SecurityException) {
                main.post { result.error("lost", e.javaClass.simpleName, null) }
            } catch (e: Exception) {
                // The class only: a message may hold a file's name.
                Log.w(TAG, "Backup folder: ${e.javaClass.simpleName}")
                main.post { result.error("io", e.javaClass.simpleName, null) }
            }
        }
    }

    private fun MethodCall.uri(): Uri = Uri.parse(argument<String>("uri")!!)

    companion object {
        const val NAME = "troona/backup_folder"
        private const val TAG = "BackupFolder"
        private const val REQUEST_PICK = 0x7b0c
        private const val MIME = "application/json"
        private val COLUMNS = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        private val worker = Executors.newSingleThreadExecutor()
        private val main = Handler(Looper.getMainLooper())
    }
}

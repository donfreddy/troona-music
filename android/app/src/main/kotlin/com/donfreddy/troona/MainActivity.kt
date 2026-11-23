package com.donfreddy.troona

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
    private var backupFolder: BackupFolderChannel? = null
    private var opened: OpenedFileChannel? = null

    /** Recreated by the system: its launch intent was already handled. */
    private var restored = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Before super: it configures the engine.
        restored = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        backupFolder?.dispose()
        backupFolder = BackupFolderChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        opened?.dispose()
        opened = OpenedFileChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        // Cold start: the file the app was launched with.
        if (!restored) opened?.offer(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The engine outlives the activity (audio_service keeps it).
        backupFolder?.dispose()
        backupFolder = null
        opened?.dispose()
        opened = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Activity results still arrive here on a FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupFolder?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Already running (singleTask: one activity).
        opened?.offer(intent)
    }
}

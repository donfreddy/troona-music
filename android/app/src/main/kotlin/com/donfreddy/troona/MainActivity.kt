package com.donfreddy.troona

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : AudioServiceActivity() {
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
        opened?.dispose()
        opened = OpenedFileChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        // Cold start: the file the app was launched with.
        if (!restored) opened?.offer(intent)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // The engine outlives the activity (audio_service keeps it).
        opened?.dispose()
        opened = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // Already running (singleTop).
        opened?.offer(intent)
    }
}

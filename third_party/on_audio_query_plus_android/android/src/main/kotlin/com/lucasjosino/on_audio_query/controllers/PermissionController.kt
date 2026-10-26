package com.lucasjosino.on_audio_query.controllers

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.lucasjosino.on_audio_query.PluginProvider
import com.lucasjosino.on_audio_query.interfaces.PermissionManagerInterface
import io.flutter.Log
import io.flutter.plugin.common.PluginRegistry

class PermissionController : PermissionManagerInterface,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val TAG: String = "PermissionController"
        private const val REQUEST_CODE: Int = 88560
    }

    var retryRequest: Boolean = false

    private var permissions: Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Troona patch: audio only. Upstream also required
            // READ_MEDIA_IMAGES, which a music player must not declare
            // (Google Play photo and video permissions policy).
            arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
        } else {
            // Troona patch: reading is enough, the app never writes.
            arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
        }

    override fun permissionStatus(): Boolean = permissions.all {
        val ctx = PluginProvider.tryGetContext()
        if (ctx == null) {
            Log.w(TAG, "Context not available while checking permission status")
            return false
        }

        ContextCompat.checkSelfPermission(
            ctx,
            it
        ) == PackageManager.PERMISSION_GRANTED
    }

    override fun requestPermission() {
        Log.d(TAG, "Requesting permissions.")
        Log.d(TAG, "SDK: ${'$'}{Build.VERSION.SDK_INT}, Should retry request: $retryRequest")

        // If we already have permission, return success immediately to Flutter.
        if (permissionStatus()) {
            Log.d(TAG, "Permissions already granted, returning success to Flutter")
            try {
                val result = PluginProvider.tryGetResult()
                result?.success(true)
            } catch (_: Exception) {
                Log.w(TAG, "Failed to deliver success result")
            }
            return
        }

        val activity = PluginProvider.tryGetActivity()
        if (activity == null) {
            Log.w(TAG, "Activity not available to request permissions")
            // If there's a pending Flutter result, return an error so Dart side knows the request couldn't be started.
            try {
                val result = PluginProvider.tryGetResult()
                result?.error(
                    "NoActivity",
                    "Activity not available to request permissions",
                    null
                )
            } catch (_: Exception) {
                Log.w(TAG, "Failed to deliver error result")
            }
            return
        }

        ActivityCompat.requestPermissions(activity, permissions, REQUEST_CODE)
    }

    override fun retryRequestPermission() {
        val activity = PluginProvider.tryGetActivity()
        if (activity == null) {
            Log.w(TAG, "Activity not available to retry permission request")
            return
        }
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permissions[0])
            || ActivityCompat.shouldShowRequestPermissionRationale(activity, permissions[1])
        ) {
            Log.d(TAG, "Retrying permission request")
            retryRequest = false
            requestPermission()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (REQUEST_CODE != requestCode) return false

        val isPermissionGranted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        Log.d(TAG, "Permission accepted: $isPermissionGranted")

        // Guard PluginProvider calls - plugin may be uninitialized when result arrives.
        try {
            if (!PluginProvider.hasResult()) {
                Log.w(TAG, "No plugin result available to deliver permission result to; ignoring.")
                return false
            }
        } catch (_: PluginProvider.UninitializedPluginProviderException) {
            Log.w(TAG, "PluginProvider not initialized while checking hasResult; ignoring.")
            return false
        } catch (_: Exception) {
            Log.w(TAG, "Unexpected error while checking PluginProvider")
            return false
        }

        val result = try {
            PluginProvider.tryGetResult()
        } catch (_: PluginProvider.UninitializedPluginProviderException) {
            Log.w(TAG, "PluginProvider not initialized while getting result; ignoring.")
            null
        } catch (_: Exception) {
            Log.w(TAG, "Unexpected error while getting plugin result")
            null
        }

        if (result == null) {
            Log.w(TAG, "Plugin result was null despite hasResult() indicating otherwise; ignoring.")
            return false
        }

        when {
            isPermissionGranted -> result.success(true)
            retryRequest -> retryRequestPermission()
            else -> result.success(false)
        }

        return true
    }
}

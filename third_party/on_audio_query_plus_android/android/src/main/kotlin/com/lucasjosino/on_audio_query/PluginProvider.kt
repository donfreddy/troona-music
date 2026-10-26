package com.lucasjosino.on_audio_query

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * A singleton used to define all variables/methods that will be used on all plugin.
 *
 * The singleton will provider the ability to 'request' required variables/methods on any moment.
 *
 * All variables/methods should be defined after plugin initialization (activity/context) and
 * dart request (call/result).
 */
object PluginProvider {
    private const val ERROR_MESSAGE =
        "Tried to get one of the methods but the 'PluginProvider' has not initialized"

    /**
    * Define if 'warn' level will show more detailed logging.
    *
    * Will be used when a query produce some error.
    */
    var showDetailedLog: Boolean = false

    // Keep context/activity as weak refs to avoid leaking the Activity/Context
    private lateinit var contextRef: WeakReference<Context>

    private lateinit var activityRef: WeakReference<Activity>

    // Use strong references for call/result so they are not GC'd while waiting for async callbacks
    private var callRef: MethodCall? = null

    private var resultRef: MethodChannel.Result? = null

    /**
     * Used to define the current [Activity] and [Context].
     *
     * Should be defined once.
     */
    fun set(activity: Activity) {
        this.contextRef = WeakReference(activity.applicationContext)
        this.activityRef = WeakReference(activity)
    }

    /**
     * Used to define the current dart request.
     *
     * Should be defined/redefined on every [MethodChannel.MethodCallHandler.onMethodCall] request.
     */
    fun setCurrentMethod(call: MethodCall, result: MethodChannel.Result) {
        this.callRef = call
        this.resultRef = result
    }

    /**
     * The current plugin 'context'. Defined once.
     *
     * @throws UninitializedPluginProviderException
     * @return [Context]
     */
    fun context(): Context {
        return this.contextRef.get() ?: throw UninitializedPluginProviderException(ERROR_MESSAGE)
    }

    /**
     * The current plugin 'activity'. Defined once.
     *
     * @throws UninitializedPluginProviderException
     * @return [Activity]
     */
    fun activity(): Activity {
        return this.activityRef.get() ?: throw UninitializedPluginProviderException(ERROR_MESSAGE)
    }

    /**
     * The current plugin 'call'. Will be replace with newest dart request.
     *
     * @throws UninitializedPluginProviderException
     * @return [MethodCall]
     */
    fun call(): MethodCall {
        return this.callRef ?: throw UninitializedPluginProviderException(ERROR_MESSAGE)
    }

    /**
     * The current plugin 'result'. Will be replace with newest dart request.
     *
     * @throws UninitializedPluginProviderException
     * @return [MethodChannel.Result]
     */
    fun result(): MethodChannel.Result {
        return this.resultRef ?: throw UninitializedPluginProviderException(ERROR_MESSAGE)
    }

    /**
     * Safe check helpers to avoid accessing lateinit properties when the plugin is not initialized.
     */
    fun hasContext(): Boolean = this::contextRef.isInitialized && this.contextRef.get() != null

    fun hasActivity(): Boolean = this::activityRef.isInitialized && this.activityRef.get() != null

    fun hasCall(): Boolean = this.callRef != null

    fun hasResult(): Boolean = this.resultRef != null

    /**
     * Try getters that return null instead of throwing when the provider wasn't initialized.
     */
    fun tryGetContext(): Context? = if (this::contextRef.isInitialized) this.contextRef.get() else null

    fun tryGetActivity(): Activity? = if (this::activityRef.isInitialized) this.activityRef.get() else null

    fun tryGetCall(): MethodCall? = this.callRef

    fun tryGetResult(): MethodChannel.Result? = this.resultRef

    /**
     * Clear referents inside the WeakReferences. This keeps the variables initialized but
     * avoids holding onto stale Activity/Context/Method references after detach.
     */
    fun clear() {
        if (this::contextRef.isInitialized) this.contextRef.clear()
        if (this::activityRef.isInitialized) this.activityRef.clear()
        this.callRef = null
        this.resultRef = null
    }

    class UninitializedPluginProviderException(msg: String) : Exception(msg)
}
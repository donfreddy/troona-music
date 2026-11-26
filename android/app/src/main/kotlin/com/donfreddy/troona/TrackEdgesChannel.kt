package com.donfreddy.troona

import android.content.Context
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.nio.ByteOrder
import java.util.concurrent.Executors
import java.util.concurrent.TimeoutException
import kotlin.math.log10
import kotlin.math.max

/**
 * The loudness of a song's start and end, for the player to find where
 * its music starts and stops (crossfade transitions).
 *
 * Decodes only the first `headMs` and the last `tailMs` of the file, and
 * returns their level in dBFS per window of `windowMs`. A window holding
 * no sample (past the real end of the audio) reads [NO_DATA]. Deciding
 * what is silence or a fade is left to Dart.
 *
 * One analysis at a time, on a background thread, and never longer than
 * [DEADLINE_MS]: a file that stalls the decoder must not hold up the next.
 * Holds the application context only, so it may outlive the activity, as
 * the engine does while music plays.
 */
class TrackEdgesChannel(
    context: Context,
    messenger: BinaryMessenger,
) {
    private val app = context.applicationContext
    private val channel = MethodChannel(messenger, NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "analyze" -> {
                    val uri = call.argument<String>("uri").orEmpty()
                    val path = call.argument<String>("path").orEmpty()
                    val headMs = call.argument<Int>("headMs") ?: 10000
                    val tailMs = call.argument<Int>("tailMs") ?: 30000
                    val windowMs = (call.argument<Int>("windowMs") ?: 50).coerceAtLeast(10)
                    worker.execute {
                        try {
                            val edges = analyze(uri, path, headMs, tailMs, windowMs)
                            main.post { result.success(edges) }
                        } catch (e: Exception) {
                            val code = if (passing(e)) FAILED else UNREADABLE
                            main.post { result.error(code, e.javaClass.simpleName, null) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    /**
     * Whether [e] may not happen again: the deadline, storage or access
     * that comes back, or a decoder busy with playback. Anything else
     * (no audio track, no length, no decoder, a stream the decoder
     * refuses, an encoding not read) is the file's.
     */
    private fun passing(e: Exception) = when (e) {
        is NoDecoder -> false
        is MediaCodec.CodecException -> e.isTransient || e.isRecoverable
        is TimeoutException, is SecurityException, is IOException,
        is IllegalStateException -> true
        else -> false
    }

    /** No decoder on this phone for the file's format. */
    private class NoDecoder(mime: String) : Exception(mime)

    private fun analyze(
        uri: String,
        path: String,
        headMs: Int,
        tailMs: Int,
        windowMs: Int,
    ): Map<String, Any> {
        val deadline = SystemClock.elapsedRealtime() + DEADLINE_MS
        val extractor = MediaExtractor()
        try {
            if (uri.isNotEmpty()) {
                extractor.setDataSource(app, Uri.parse(uri), null)
            } else {
                extractor.setDataSource(path)
            }
            val track = (0 until extractor.trackCount).first {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)
                    ?.startsWith("audio/") == true
            }
            extractor.selectTrack(track)
            val format = extractor.getTrackFormat(track)
            val durationUs = format.getLong(MediaFormat.KEY_DURATION)
            val windowUs = windowMs * 1000L
            val headEndUs = minOf(headMs * 1000L, durationUs)
            val tailFromUs = max(0L, durationUs - tailMs * 1000L)
            val head = envelope(extractor, format, 0L, headEndUs, windowUs, deadline)
            val tail = envelope(extractor, format, tailFromUs, durationUs, windowUs, deadline)
            return mapOf(
                "durationMs" to durationUs / 1000,
                "windowMs" to windowMs,
                "head" to head,
                "tailFromMs" to tailFromUs / 1000,
                "tail" to tail,
            )
        } finally {
            extractor.release()
        }
    }

    /**
     * Level per window of the audio between [fromUs] and [toUs], from one
     * frame in [STRIDE] (plenty for a level over 50 ms).
     */
    private fun envelope(
        extractor: MediaExtractor,
        format: MediaFormat,
        fromUs: Long,
        toUs: Long,
        windowUs: Long,
        deadline: Long,
    ): DoubleArray {
        val windows = ((toUs - fromUs + windowUs - 1) / windowUs).toInt().coerceAtLeast(1)
        val sumSquares = DoubleArray(windows)
        val counts = LongArray(windows)
        var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT).coerceAtLeast(1)
        var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var isFloat = false
        var shortSamples = ShortArray(0)
        var floatSamples = FloatArray(0)

        extractor.seekTo(fromUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)
        val mime = format.getString(MediaFormat.KEY_MIME)!!
        val codec = try {
            MediaCodec.createDecoderByType(mime)
        } catch (e: IOException) {
            throw NoDecoder(mime)
        }
        try {
            codec.configure(format, null, null, 0)
            codec.start()
            val info = MediaCodec.BufferInfo()
            var inputDone = false
            var outputDone = false
            while (!outputDone) {
                if (SystemClock.elapsedRealtime() > deadline) throw TimeoutException()
                // Fill every input buffer the codec has free before waiting
                // for an output: one frame at a time pays the trip to the
                // codec's process on each frame.
                var fed = false
                while (!inputDone) {
                    val index = codec.dequeueInputBuffer(0)
                    if (index < 0) break
                    val buffer = codec.getInputBuffer(index)!!
                    val size = extractor.readSampleData(buffer, 0)
                    val time = extractor.sampleTime
                    if (size < 0 || time > toUs) {
                        codec.queueInputBuffer(index, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                        inputDone = true
                    } else {
                        codec.queueInputBuffer(index, 0, size, time, 0)
                        extractor.advance()
                    }
                    fed = true
                }
                // Wait only when there was nothing to feed.
                val out = codec.dequeueOutputBuffer(info, if (fed) 0 else TIMEOUT_US)
                if (out == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val f = codec.outputFormat
                    channels = f.getInteger(MediaFormat.KEY_CHANNEL_COUNT).coerceAtLeast(1)
                    sampleRate = f.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                    val encoding = if (f.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                        f.getInteger(MediaFormat.KEY_PCM_ENCODING)
                    } else {
                        AudioFormat.ENCODING_PCM_16BIT
                    }
                    isFloat = when (encoding) {
                        AudioFormat.ENCODING_PCM_16BIT -> false
                        AudioFormat.ENCODING_PCM_FLOAT -> true
                        else -> throw IllegalArgumentException("PCM encoding $encoding")
                    }
                } else if (out >= 0) {
                    if (info.size > 0) {
                        val buffer = codec.getOutputBuffer(out)!!
                        buffer.position(info.offset)
                        buffer.limit(info.offset + info.size)
                        buffer.order(ByteOrder.nativeOrder())
                        val samples = if (isFloat) info.size / 4 else info.size / 2
                        // One bulk copy: a get() per sample is slow.
                        if (isFloat) {
                            if (floatSamples.size < samples) floatSamples = FloatArray(samples)
                            buffer.asFloatBuffer().get(floatSamples, 0, samples)
                        } else {
                            if (shortSamples.size < samples) shortSamples = ShortArray(samples)
                            buffer.asShortBuffer().get(shortSamples, 0, samples)
                        }
                        val frames = samples / channels
                        val frameUs = 1_000_000.0 / sampleRate
                        val bufferUs = info.presentationTimeUs
                        var frame = 0
                        while (frame < frames) {
                            val timeUs = bufferUs + (frame * frameUs).toLong()
                            if (timeUs >= toUs) break
                            if (timeUs >= fromUs) {
                                val window = ((timeUs - fromUs) / windowUs).toInt()
                                val base = frame * channels
                                var sum = 0.0
                                for (c in 0 until channels) {
                                    val v = if (isFloat) {
                                        floatSamples[base + c].toDouble()
                                    } else {
                                        shortSamples[base + c] / 32768.0
                                    }
                                    if (v.isFinite()) sum += v * v
                                }
                                sumSquares[window] += sum
                                counts[window] += channels.toLong()
                            }
                            frame += STRIDE
                        }
                    }
                    codec.releaseOutputBuffer(out, false)
                    if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) outputDone = true
                }
            }
        } finally {
            runCatching { codec.stop() }
            codec.release()
        }
        return DoubleArray(windows) { w ->
            if (counts[w] == 0L) {
                NO_DATA
            } else {
                val meanSquare = sumSquares[w] / counts[w]
                if (meanSquare <= 0.0) FLOOR else max(FLOOR, 10 * log10(meanSquare))
            }
        }
    }

    companion object {
        const val NAME = "troona/track_edges"

        /** The error code of a file that cannot be analysed. */
        const val UNREADABLE = "unreadable"

        /** The error code of an analysis that may work another time. */
        const val FAILED = "failed"

        private const val TIMEOUT_US = 10_000L
        private const val DEADLINE_MS = 30_000L
        private const val STRIDE = 4
        private const val FLOOR = -120.0
        private const val NO_DATA = -200.0

        /** One analysis at a time, out of the playback's way. */
        private val worker = Executors.newSingleThreadExecutor { runnable ->
            Thread({
                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
                runnable.run()
            }, "track-edges")
        }
        private val main = Handler(Looper.getMainLooper())
    }
}

package com.bb.eye.eye_hue

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class NativeView(context: Context) : PlatformView {
    private val containerView: FrameLayout
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    override fun getView(): View {
        return containerView
    }

    override fun dispose() {
        cameraExecutor.shutdown()
    }

    init {
        val inflater = LayoutInflater.from(context)
        containerView = FrameLayout(context)

        // Camera Preview View
        val previewView = PreviewView(context)
        previewView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )

        // AI Overlay View
        val overlayView = OverlayView(context, null)

        containerView.addView(previewView)
        containerView.addView(overlayView) // Overlay on top of the camera preview

        startCamera(context, previewView)
    }

    private fun startCamera(context: Context, previewView: PreviewView) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            val preview = Preview.Builder().build().also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }
            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(context as LifecycleOwner, cameraSelector, preview)
        }, context.mainExecutor)
    }
}

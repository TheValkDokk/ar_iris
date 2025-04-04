package com.bb.eye.eye_hue

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.view.TextureRegistry

class CameraXViewFactory(
    private val messenger: BinaryMessenger,
    private val textureRegistry: TextureRegistry,
    private val lifecycleOwner: androidx.lifecycle.LifecycleOwner
) : PlatformViewFactory() {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return object : PlatformView {
            private val cameraPreview = CameraXPreview(context, textureRegistry, lifecycleOwner)

            init {
                cameraPreview.startCamera()
            }

            override fun getView(): View {
                return cameraPreview
            }

            override fun dispose() {
                cameraPreview.dispose()
            }
        }
    }
}

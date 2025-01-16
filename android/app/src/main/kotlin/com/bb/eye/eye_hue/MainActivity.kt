package com.bb.eye.eye_hue

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.os.PersistableBundle
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.android.Utils
import org.opencv.core.Mat
import org.opencv.core.MatOfRect
import org.opencv.core.Scalar
import org.opencv.imgproc.Imgproc
import org.opencv.objdetect.CascadeClassifier
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "opencv/eye_color"
    private lateinit var cascadeClassifier: CascadeClassifier
    val TAG = "app"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (OpenCVLoader.initLocal()) {
            Log.i(TAG, "OpenCV loaded successfully");
        } else {
            Log.e(TAG, "OpenCV initialization failed!");
            return;
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (OpenCVLoader.initLocal()) {
            Log.i(TAG, "OpenCV loaded successfully");
        } else {
            Log.e(TAG, "OpenCV initialization failed!");
            return;
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "processFrame") {
                val base64Image = call.argument<String>("image")
                val processedImage = processFrame(base64Image!!)
                result.success(processedImage)
            } else {
                result.notImplemented()
            }
        }

        val cascadeFile = File(cacheDir, "haarcascade_eye.xml")
        cascadeFile.outputStream().use {
            resources.openRawResource(R.raw.haarcascade_eye).copyTo(it)
        }
        cascadeClassifier = CascadeClassifier(cascadeFile.absolutePath)
    }

    private fun processFrame(base64Image: String): String {
        val decodedBytes = Base64.decode(base64Image, Base64.DEFAULT)
        val bitmap = BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
        val mat = Mat()
        if (bitmap == null) {
            return ""
        }

        Utils.bitmapToMat(bitmap, mat)

        // Convert to grayscale
        val gray = Mat()
        Imgproc.cvtColor(mat, gray, Imgproc.COLOR_BGR2GRAY)

        // Detect eyes
        val eyes = MatOfRect()
        cascadeClassifier.detectMultiScale(gray, eyes)

//        Log.d("Eyes", eyes.toArray().toString())

        for (rect in eyes.toArray()) {
            Imgproc.rectangle(mat, rect.tl(), rect.br(), Scalar(0.0, 255.0, 0.0), -1)
        }

        // Convert back to Bitmap
        val processedBitmap = Bitmap.createBitmap(mat.cols(), mat.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(mat, processedBitmap)

        // Encode Bitmap to Base64
        val byteArrayOutputStream = ByteArrayOutputStream()
        val compressed = processedBitmap.compress(Bitmap.CompressFormat.PNG, 50, byteArrayOutputStream)

        if (!compressed) {
            Log.e("Error", "Bitmap compression failed.")
            return ""
        }

        val byteArray = byteArrayOutputStream.toByteArray()
        if (byteArray.isEmpty()) {
            Log.e("Error", "Compressed byte array is empty.")
            return ""
        }
        return Base64.encodeToString(byteArray, Base64.DEFAULT)
    }
}

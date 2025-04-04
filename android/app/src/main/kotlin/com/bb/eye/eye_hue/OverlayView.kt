package com.bb.eye.eye_hue

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Region
import android.util.AttributeSet
import android.util.Log
import android.view.View
import androidx.core.content.ContextCompat
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sqrt

class OverlayView(context: Context?, attrs: AttributeSet?) :
    View(context, attrs) {

    private var results: FaceLandmarkerResult? = null
    private var linePaint = Paint()
    private var pointPaint = Paint()

    private var scaleFactor: Float = 1f
    private var imageWidth: Int = 1
    private var imageHeight: Int = 1

    init {
        initPaints()
    }

    fun clear() {
        results = null
        linePaint.reset()
        pointPaint.reset()
        invalidate()
        initPaints()
    }

    private fun initPaints() {
        linePaint.color =
            ContextCompat.getColor(context!!, R.color.mp_color_primary)
        linePaint.strokeWidth = LANDMARK_STROKE_WIDTH
        linePaint.style = Paint.Style.STROKE

        pointPaint.color = Color.YELLOW
        pointPaint.strokeWidth = LANDMARK_STROKE_WIDTH
        pointPaint.style = Paint.Style.FILL
    }

    override fun draw(canvas: Canvas) {
        super.draw(canvas)

        // Clear previous drawings if results exist but have no face landmarks
        if (results?.faceLandmarks().isNullOrEmpty()) {
            clear()
            return
        }

        results?.let { faceLandmarkerResult ->

            // Calculate scaled image dimensions
            val scaledImageWidth = imageWidth * scaleFactor
            val scaledImageHeight = imageHeight * scaleFactor

            // Calculate offsets to center the image on the canvas
            val offsetX = (width - scaledImageWidth) / 2f
            val offsetY = (height - scaledImageHeight) / 2f
            val irisBitmap: Bitmap =
                BitmapFactory.decodeResource(resources, R.drawable.bicolor_iris)
            // Iterate through each detected face
            faceLandmarkerResult.faceLandmarks().forEach { faceLandmarks ->
                // Draw all landmarks for the current face
//                drawFaceLandmarks(canvas, faceLandmarks, offsetX, offsetY)
//
//                // Draw all connectors for the current face
//                drawIrisConnectors(canvas, faceLandmarks, offsetX, offsetY)

                //Draw eye lids

                // Draw the iris overlay on the canvas
                drawIrisOverlay(canvas, faceLandmarks, offsetX, offsetY, irisBitmap)
                drawEyeLid(canvas, faceLandmarks, offsetX, offsetY)
            }
        }
    }

    private fun drawEyeLid(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float,
    ) {
        val leftEyeLid = listOf(
            263,
            249,
            390,
            373,
            374,
            380,
            381,
            382,
            362,
            398,
            384,
            385,
            386,
            387,
            388,
            466,
            263
        )
        drawFromPoints(canvas, leftEyeLid, faceLandmarks, offsetX, offsetY);

        val rightEyeLid =
            listOf(33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7, 33)
        drawFromPoints(canvas, rightEyeLid, faceLandmarks, offsetX, offsetY);
    }

    private fun drawFaceLandmarks(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float
    ) {
        faceLandmarks.forEach { landmark ->
            val x = landmark.x() * imageWidth * scaleFactor + offsetX
            val y = landmark.y() * imageHeight * scaleFactor + offsetY
            canvas.drawPoint(x, y, pointPaint)
        }
    }


    private fun drawIrisConnectors(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float
    ) {
        val rightIris = listOf(468, 469, 470, 471, 472, 469)
        val leftIris = listOf(473, 474, 475, 476, 477, 474)

        listOf(rightIris, leftIris).forEach { iris ->
            for (i in 0 until iris.size - 1) {
                val startLandmark = faceLandmarks.getOrNull(iris[i])
                val endLandmark = faceLandmarks.getOrNull(iris[i + 1])

                if (startLandmark != null && endLandmark != null) {
                    val startX = startLandmark.x() * imageWidth * scaleFactor + offsetX
                    val startY = startLandmark.y() * imageHeight * scaleFactor + offsetY
                    val endX = endLandmark.x() * imageWidth * scaleFactor + offsetX
                    val endY = endLandmark.y() * imageHeight * scaleFactor + offsetY

                    canvas.drawLine(startX, startY, endX, endY, linePaint)
                }
            }
        }
    }

    private fun drawIrisOverlay(
        canvas: Canvas,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float,
        irisBitmap: Bitmap
    ) {
        //left iris point
        val leftIris = listOf(474, 475, 476, 477, 473)
        val leftIrisPointF = mutableListOf<PointF>()
        leftIris.forEach { index ->
            val result = getPointF(index, faceLandmarks)
            Log.d("result", result.toString())
            leftIrisPointF.add(result)
        }

        val leftEyeLid = listOf(
            263,
            249,
            390,
            373,
            374,
            380,
            381,
            382,
            362,
            398,
            384,
            385,
            386,
            387,
            388,
            466,
            263
        )
        val leftEyeLidPointF = mutableListOf<PointF>()
        leftEyeLid.forEach { index ->
            val result = getPointF(index, faceLandmarks)
            leftEyeLidPointF.add(result)
        }

        val rightIris = listOf(469, 470, 471, 472, 468)
        val rightIrisPointF = mutableListOf<PointF>()
        rightIris.forEach { index ->
            val result = getPointF(index, faceLandmarks)
            rightIrisPointF.add(result)
        }
        val rightEyeLid =
            listOf(33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7, 33)
        val rightEyeLidPointF = mutableListOf<PointF>()
        rightEyeLid.forEach { index ->
            val result = getPointF(index, faceLandmarks)
            rightEyeLidPointF.add(result)
        }

        drawCircularBitmap(canvas, irisBitmap, leftIrisPointF, offsetX, offsetY, leftEyeLidPointF)
        drawCircularBitmap(canvas, irisBitmap, rightIrisPointF, offsetX, offsetY, rightEyeLidPointF)

//        val irises = listOf(
//            468 to listOf(469, 470, 471, 472), // Right iris
//            473 to listOf(474, 475, 476, 477)  // Left iris
//        )
//
//        irises.forEach { (centerIndex, perimeterIndices) ->
//            val centerLandmark = faceLandmarks.getOrNull(centerIndex)
//
//            if (centerLandmark != null) {
//                val centerX = centerLandmark.x() * imageWidth * scaleFactor + offsetX
//                val centerY = centerLandmark.y() * imageHeight * scaleFactor + offsetY
//
//                // Define a fixed radius using the known points
//                val radius = 50f // Adjust this value based on your testing
//
//                // Scale the bitmap to fit the iris
//                val scaledBitmap = Bitmap.createScaledBitmap(
//                    irisBitmap,
//                    (radius * 2).toInt(),
//                    (radius * 2).toInt(),
//                    true
//                )
//
//                // Draw the image centered on the iris
//                canvas.drawBitmap(scaledBitmap, centerX - radius, centerY - radius, null)
//            }
//        }
    }

    private fun drawFromPoints(
        canvas: Canvas,
        pointsIndexs: List<Int>,
        faceLandmarks: List<NormalizedLandmark>,
        offsetX: Float,
        offsetY: Float
    ) {
        for (i in 0 until pointsIndexs.size - 1) {
            val startLandmark = faceLandmarks.getOrNull(pointsIndexs[i])
            val endLandmark = faceLandmarks.getOrNull(pointsIndexs[i + 1])

            if (startLandmark != null && endLandmark != null) {
                val startX = startLandmark.x() * imageWidth * scaleFactor + offsetX
                val startY = startLandmark.y() * imageHeight * scaleFactor + offsetY
                val endX = endLandmark.x() * imageWidth * scaleFactor + offsetX
                val endY = endLandmark.y() * imageHeight * scaleFactor + offsetY

                canvas.drawLine(startX, startY, endX, endY, linePaint)
            }
        }

    }

    private fun getPointF(index: Int, faceLandmarks: List<NormalizedLandmark>): PointF {
        val landmark = faceLandmarks.getOrNull(index)
        return if (landmark != null) {
            PointF(landmark.x(), landmark.y())
        } else {
            PointF(0f, 0f)
        }
    }

    private fun drawCircularBitmap(
        canvas: Canvas, bitmap: Bitmap, points: List<PointF>, offsetX: Float,
        offsetY: Float, eyeLid: List<PointF>
    ) {
        if (points.size != 5) return

        val centerLandmark = points[4]

        // Calculate center (midpoint of Left-Right and Top-Bottom)
        val centerX = centerLandmark.x * imageWidth * scaleFactor + offsetX
        val centerY = centerLandmark.y * imageHeight * scaleFactor + offsetY

        // Calculate radius (Half of the width between Left and Right)
        val radius = (points[3].x - points[2].x) / 2 * imageWidth * scaleFactor * 2f

        // Create circular bitmap
        val circularBitmap =
            Bitmap.createBitmap((radius * 2).toInt(), (radius * 2).toInt(), Bitmap.Config.ARGB_8888)
        val tempCanvas = Canvas(circularBitmap)

        // Draw circular mask
        val maskPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        }
        tempCanvas.drawCircle(
            radius,
            radius,
            radius,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK },
        )

        // Scale the bitmap to fit inside the circle
        val scaledBitmap =
            Bitmap.createScaledBitmap(bitmap, (radius * 2).toInt(), (radius * 2).toInt(), true)
        tempCanvas.drawBitmap(scaledBitmap, 0f, 0f, maskPaint)

        // Create the eyelid path
        val eyelidPath = Path().apply {
            if (eyeLid.isNotEmpty()) {
                moveTo(eyeLid[0].x * imageWidth * scaleFactor + offsetX, eyeLid[0].y * imageHeight * scaleFactor + offsetY)
                for (i in 1 until eyeLid.size) {
                    lineTo(eyeLid[i].x * imageWidth * scaleFactor + offsetX, eyeLid[i].y * imageHeight * scaleFactor + offsetY)
                }
                close()
            }
        }

        // Save the canvas state
        canvas.save()

        // Clip the canvas to the eyelid path
        canvas.clipPath(eyelidPath)

        // Draw the final circular bitmap on the main canvas
        canvas.drawBitmap(circularBitmap, centerX - radius, centerY - radius, null)

        // Restore the canvas state
        canvas.restore()
    }


    fun setResults(
        faceLandmarkerResults: FaceLandmarkerResult,
        imageHeight: Int,
        imageWidth: Int,
        runningMode: RunningMode = RunningMode.IMAGE
    ) {
        results = faceLandmarkerResults

        this.imageHeight = imageHeight
        this.imageWidth = imageWidth

        scaleFactor = when (runningMode) {
            RunningMode.IMAGE,
            RunningMode.VIDEO -> {
                min(width * 1f / imageWidth, height * 1f / imageHeight)
            }

            RunningMode.LIVE_STREAM -> {
                // PreviewView is in FILL_START mode. So we need to scale up the
                // landmarks to match with the size that the captured images will be
                // displayed.
                max(width * 1f / imageWidth, height * 1f / imageHeight)
            }
        }
        invalidate()
    }

    companion object {
        private const val LANDMARK_STROKE_WIDTH = 8F
        private const val TAG = "Face Landmarker Overlay"
    }
}

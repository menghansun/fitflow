package com.fitflow.app

import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
    /**
     * Default [RenderMode.surface] can show a black Flutter layer on some OEMs during long native
     * work (integration_test + ML Kit). Debug builds use texture compositing; release keeps surface.
     */
    override fun getRenderMode(): RenderMode {
        val debuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        return if (debuggable) RenderMode.texture else RenderMode.surface
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Debuggable builds only: keep screen on during long ML Kit / integration_test OCR.
        val debuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (debuggable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.decorView.setBackgroundColor(Color.WHITE)
        }
    }
}

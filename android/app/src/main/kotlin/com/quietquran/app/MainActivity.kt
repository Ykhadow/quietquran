package com.quietquran.app

import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

// Recitation's notification and lock-screen controls (audio_service) need
// their activity; it is a FlutterActivity.
class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The recent-apps view shows a plain card for the app, not the page
        // being read (Android 13+). Screenshots still work.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            setRecentsScreenshotEnabled(false)
        }
    }
}

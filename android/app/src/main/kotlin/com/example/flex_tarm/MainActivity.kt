package com.example.flex_tarm

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            Log.d("MainActivity", "MainActivity onCreate called")
            super.onCreate(savedInstanceState)
            Log.d("MainActivity", "MainActivity onCreate completed")
        } catch (e: Exception) {
            Log.e("MainActivity", "Error in onCreate: ${e.message}", e)
            throw e // Bu hatayı yukarı fırlat, böylece logcat'te görürüz
        }
    }
}

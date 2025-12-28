package com.example.flex_tarm

import android.app.Application
import android.util.Log
import androidx.multidex.MultiDex

class MainApplication : Application() {
    override fun onCreate() {
        try {
            super.onCreate()
            MultiDex.install(this)
            Log.d("MainApplication", "Application started successfully")
        } catch (e: Exception) {
            Log.e("MainApplication", "Error in onCreate: ${e.message}", e)
            // Uygulamanın açılmasını engelleme, sadece logla
        }
    }
}


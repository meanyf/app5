package com.example.app5

import android.app.Application
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()

class MainApplication: Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("633698cf-60eb-47ea-ba76-929725831a86")
    }
}
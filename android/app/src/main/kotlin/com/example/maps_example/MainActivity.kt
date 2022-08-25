package com.example.maps_example

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MapKitFactory.setApiKey("acd191bb-dafb-485f-b131-b60ef3913a41")
        super.configureFlutterEngine(flutterEngine)
    }
}

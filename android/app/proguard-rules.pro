# Keep Flutter wrapper and engine classes
-keep class io.flutter.** { *; }

# Keep ONNX Runtime classes
-keep class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Keep Masicai Flutter ONNX Runtime plugin classes
-keep class com.masicai.flutteronnxruntime.** { *; }
-dontwarn com.masicai.flutteronnxruntime.**

# Keep JNI classes
-keep class com.github.dart_lang.** { *; }
-dontwarn com.github.dart_lang.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Ignore missing Play Core classes (used by Flutter deferred components feature)
-dontwarn com.google.android.play.core.**

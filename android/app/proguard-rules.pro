# Keep Flutter JNI
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep ML Kit models reflection
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep file picker providers
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Keep BlinkID / Scanbot / plugins (reflection)
-keep class com.microblink.** { *; }
-keep class com.scanbot.** { *; }
-dontwarn com.microblink.**
-dontwarn com.scanbot.**

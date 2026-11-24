# Flutter Wrapper Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core deferred components suppression for Flutter
-dontwarn com.google.android.play.core.**

# Sqflite
-keep class com.tekartik.sqflite.** { *; }

# Print Bluetooth Thermal
-keep class com.print_bluetooth_thermal.** { *; }

# Mobile Scanner
-keep class com.google.mlkit.** { *; }
-keep class androidx.camera.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep annotations
-keepattributes *Annotation*

# Play Core (deferred components): Flutter los referencia pero esta app no
# usa componentes diferidos, por lo que las clases no existen en el APK.
-dontwarn com.google.android.play.core.**

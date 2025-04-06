# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }

# Keep Google Play Core libraries
-keep class com.google.android.play.core.** { *; }

# Keep specific ML Kit text recognition classes 
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.latin.** { *; }

# Keep Flutter plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes *Annotation*

# Keep specific Flutter embedding classes
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
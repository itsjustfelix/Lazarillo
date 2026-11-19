
# Lazarillo - Reglas R8
# Clases opcionales de Google ML Kit no utilizadas
# por el reconocimiento de texto latino.

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Reglas para Google ML Kit (evita que R8 borre u ofusque sus clases)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class com.google.android.libraries.barhopper.** { *; }
-keep class com.google.photos.vision.barhopper.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_**

# Mantener los plugins de Flutter intactos
-keep class io.flutter.plugins.** { *; }
-keep class com.google_mlkit_** { *; }


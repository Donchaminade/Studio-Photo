# R8 / Play Console — garder le nécessaire, laisser obfusquer le reste.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses,EnclosingMethod
-allowaccessmodification
-repackageclasses

# Activity + canal USSD natif (ne pas garder tous les membres)
-keep class com.photopicon.app.MainActivity { <init>(...); }

# Plugins Flutter : keep + obfuscation (meilleur score Play que keep tout)
-if class * implements io.flutter.embedding.engine.plugins.FlutterPlugin
-keep,allowobfuscation,allowshrinking class <1>

# Play In-App Updates
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

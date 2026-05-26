# ProGuard / R8 rules for Generational Wealth Roadmap (Capacitor 6 release).

-keepattributes Signature,*Annotation*,EnclosingMethod,InnerClasses

# Keep Capacitor / Cordova bridge classes referenced via reflection.
-keep class com.getcapacitor.** { *; }
-keep class org.apache.cordova.** { *; }

# Keep all plugin classes declared by Capacitor.
-keep @com.getcapacitor.annotation.CapacitorPlugin class * { *; }
-keep class * extends com.getcapacitor.Plugin { *; }

# Keep the application activity class.
-keep class org.wgralgo.generationalwealthroadmap.MainActivity { *; }

# Standard Android-friendly suppressions.
-dontwarn org.apache.cordova.**
-dontwarn com.getcapacitor.**

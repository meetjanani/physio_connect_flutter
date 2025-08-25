# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }

# Keep Google Pay integration classes
-keep class com.google.android.apps.nbu.paisa.inapp.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.**

# Keep other payment-related classes
-keep class com.google.android.gms.wallet.** { *; }

# Ignore missing ProGuard annotations
-dontwarn proguard.annotation.**
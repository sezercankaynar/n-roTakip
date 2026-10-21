# Bazı eklentiler (shared_preferences_android, path_provider_android) Java/Kotlin
# sınıflarına JNI üzerinden isimle erişir. Sürüm derlemesindeki küçültücü (R8)
# bu sınıfları silerse ya da adlarını değiştirirse uygulama açılış ekranında
# takılı kalır. Bu yüzden korunuyorlar.
-keep class kotlin.Unit { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }

# Bazı eklentiler (shared_preferences_android, path_provider_android) Java/Kotlin
# sınıflarına JNI üzerinden isimle erişir. Sürüm derlemesindeki küçültücü (R8)
# bu sınıfları silerse ya da adlarını değiştirirse uygulama açılış ekranında
# takılı kalır. Şu an R8 kapalı (build.gradle.kts); yeniden açılırsa bu
# kuralların eksiksiz olduğu sanal telefon testiyle doğrulanmalı.
-keep class kotlin.Unit { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }

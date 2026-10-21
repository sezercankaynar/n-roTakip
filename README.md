# NöroCep

Nöroloji servisi, nöroloji yoğun bakım ve inme ünitesinde çalışan hemşire ve hekimler için cep rehberi ve klinik araç seti. Ayrıntılı plan: [ROADMAP.md](ROADMAP.md).

> ⚠️ Sağlık profesyonelleri içindir. Klinik kararın yerine geçmez; kurum protokolleri önceliklidir. 🟡 *Taslak* işaretli içerikler henüz kontrol edilmemiştir.

## Telefona kurulum (Android)

1. Telefonunuzdan şu bağlantıyı açın: **https://github.com/sezercankaynar/n-roTakip/releases/latest/download/NoroCep.apk**
2. İndirme bitince bildirime veya "İndirilenler" klasöründeki **NoroCep.apk** dosyasına dokunun.
3. Telefon "Bilinmeyen kaynaklardan yükleme" uyarısı verirse **Ayarlar**'a dokunun ve tarayıcınız (örneğin Chrome) için **"Bu kaynaktan izin ver"** seçeneğini açın. Sonra geri dönüp **Yükle**'ye dokunun.
4. Google Play Protect "uygulama taranmadı" uyarısı verebilir. Bu uygulama henüz Play Store'da olmadığı için çıkan normal bir uyarıdır: **"Yine de yükle"**'ye dokunun.

**Yeni sürüm çıktığında** aynı bağlantıdan tekrar indirip kurmanız yeterli. Eski sürüm silinmeden güncellenir.

## Sürüm 0.1'de neler var?
- **CPR Zamanlayıcı:** toplam süre, 2 dakikalık ritim/nabız kontrolü uyarısı, adrenalin için 3–5 dakika takibi, şok/amiodaron/havayolu/ROSC kaydı, 110/dk metronom, 4H4T listesi, saat saat özet
- **NIHSS Hesaplayıcı:** 15 madde, açıklamalar, otomatik toplam ve şiddet sınıflaması
- Açılış uyarısı, açık/koyu tema

## Geliştirici notları
- Flutter 3.47 · `flutter test` · `flutter build apk`
- Her push'ta GitHub Actions APK üretir ve GitHub Releases'a yükler (`.github/workflows/android.yml`).
- `android/app/signing/test-release.jks` yalnızca test dağıtımı içindir (yeni APK eskisinin üzerine kurulabilsin diye sabit imza). Google Play yayınında gizli tutulan ayrı bir anahtar kullanılacak.
- Ses dosyaları `tool/gen_sounds.py` ile üretilir.

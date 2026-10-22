# NöroCep

Nöroloji servisi, nöroloji yoğun bakım ve inme ünitesinde çalışan hemşire ve hekimler için cep rehberi ve klinik araç seti. Ayrıntılı plan: [ROADMAP.md](ROADMAP.md).

> ⚠️ Sağlık profesyonelleri içindir. Klinik kararın yerine geçmez; kurum protokolleri önceliklidir. 🟡 *Taslak* işaretli içerikler henüz kontrol edilmemiştir.

## Telefona kurulum (Android)

1. Telefonunuzdan şu bağlantıyı açın: **https://github.com/sezercankaynar/n-roTakip/releases/latest/download/NoroCep.apk**
2. İndirme bitince bildirime veya "İndirilenler" klasöründeki **NoroCep.apk** dosyasına dokunun.
3. Telefon "Bilinmeyen kaynaklardan yükleme" uyarısı verirse **Ayarlar**'a dokunun ve tarayıcınız (örneğin Chrome) için **"Bu kaynaktan izin ver"** seçeneğini açın. Sonra geri dönüp **Yükle**'ye dokunun.
4. Google Play Protect "uygulama taranmadı" uyarısı verebilir. Bu uygulama henüz Play Store'da olmadığı için çıkan normal bir uyarıdır: **"Yine de yükle"**'ye dokunun.

**Yeni sürüm çıktığında** aynı bağlantıdan tekrar indirip kurmanız yeterli. Eski sürüm silinmeden güncellenir.

## Neler var?
- **İlaç Rehberi (0.3):** 74 ilaç (transdermal bantlar, dopamin, dobutamin, ketamin dahil; nöroloji ilaçlarının yanında antibiyotik/antiviral, analjezik, antiemetik, antihistaminik, steroid, albumin ve IV sıvılar, elektrolitler, kan ve kan ürünleri transfüzyonu, sedasyon, vazopressör, insülin, levodopa, antidotlar); etki, endikasyon, doz, hazırlama, veriliş, yan etkiler, izlem, hemşirelik uyarıları ve antidot; kategori düğmeleriyle süzme, ilaç/ticari ad/grup araması
- **İnme Merkezi (0.2):** gerçekçi çizimli etkileşimli beyin damar haritası (BT benzeri beyin kesiti ve Willis poligonu; dokunulan damar ve tarafa göre tıkanma belirtileri); hızlı tanıma (BE-FAST) ve zaman hedefleri; iskemik inme, intraserebral kanama, subaraknoid kanama, TİA; trombolitik tedavi (doz, hazırlama, kan basıncı, kanama/anjiyoödem yönetimi); kiloya göre tPA (alteplaz) ve tenekteplaz doz hesaplayıcı; etkileşimli trombolitik kontrol listesi; mekanik trombektomi; tedavi sonrası izlem çizelgesi ve damar giriş yeri bakımı; bildirimli izlem takip zamanlayıcısı (24 saat, 36 kontrol, yatak etiketiyle)
- **CPR Zamanlayıcı:** toplam süre; sabit takvimle her 2 dakikada nabız kontrolü, ilk dozu 00:00 olmak üzere her 3 dakikada adrenalin uyarısı (butona planlanan zamandan en fazla 30 sn önce veya 60 sn sonra basılırsa kayda tam planlanan zaman yazılır, basılmayanlar "onaylanmadı" görünür); şok, amiodaron, atropin, havayolu ve ROSC kaydı; adı ve dozu yazılan "diğer ilaç" kaydı; 110/dk metronom; 4H4T listesi; siklus sayısı ve uygulanan ilaç dozlarını içeren saat saat özet
- **NIHSS Hesaplayıcı:** 15 madde, açıklamalar, otomatik toplam ve şiddet sınıflaması
- Açılış uyarısı, açık/koyu tema

## Geliştirici notları
- Flutter 3.47 · `flutter test` · `flutter build apk`
- Her push'ta GitHub Actions APK üretir ve GitHub Releases'a yükler (`.github/workflows/android.yml`).
- `android/app/signing/test-release.jks` yalnızca test dağıtımı içindir (yeni APK eskisinin üzerine kurulabilsin diye sabit imza). Google Play yayınında gizli tutulan ayrı bir anahtar kullanılacak.
- Ses dosyaları `tool/gen_sounds.py` ile üretilir.

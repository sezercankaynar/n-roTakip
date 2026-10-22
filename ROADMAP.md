# NöroCep: İş Haritası

**Nöroloji servisi, nöroloji yoğun bakım ve inme ünitesinde çalışan hemşire ve hekimler için cep rehberi.**
Hastalıklar, tedaviler, ilaçlar ve prosedürler hakkında bilimsel kaynaklara dayalı bilgi sunar. Ayrıca NIHSS hesaplayıcı ve CPR zamanlayıcısı gibi klinikte kullanılan araçları içerir.

> Bu belge yaşayan bir dokümandır. Kararlar netleştikçe güncellenir. `[ ]` yapılacak, `[x]` tamamlandı demektir.

---

## 1. Sade Anlatım

### Uygulama ne yapacak?
Telefonda taşınan, internet olmadan da çalışan bir **nöroloji başvuru kitabı ve klinik araç seti**. Hasta adı, TC kimlik numarası gibi **hiçbir kişisel veri tutulmayacak.**

### İş bölümü
| Kim | Görevi |
|---|---|
| **Sen** (nöroloji hemşiresi, ürün sahibi) | Hangi bilgi ve aracın gerektiğini söylersin. Hazırlanan tıbbi içeriği kontrol edip onaylarsın. Uygulamayı deneyip geri bildirim verirsin. |
| **Claude** (geliştirici) | Bütün teknik işleri yapar, kodu yazar. Tıbbi içeriğin ilk taslağını kılavuz ve makalelerden kaynak göstererek hazırlar. Yaptığı her şeyi sade dille anlatır. |
| **Bir hekim** (isteğe bağlı, ileride) | Fırsat olursa (örneğin ünitedeki bir hekim) içeriğe ikinci bir göz olarak bakar. Zorunlu değil. |

### Çok önemli bir güvenlik kuralı
Tıbbi bilgi yanlış olursa hastaya zarar verebilir. Bu yüzden şu kurallara uyacağız:
1. Her bilgi parçasının altında **kaynağı** (kılavuz veya makale) ve **kanıt düzeyi** yazacak.
2. Uygulamadaki her içerik kartında şu üç durumdan biri görünecek:
   - 🟡 **Taslak:** Claude hazırladı, henüz kontrol edilmedi.
   - 🟢 **Hemşire onaylı:** Sen kontrol ettin.
   - 🔵 **Hekim onaylı:** (isteğe bağlı) Bir hekim de kontrol etti.
3. Taslak içerik hiçbir zaman başkalarına dağıtılan sürüme girmeyecek.
4. Her içerikte **"son kontrol tarihi"** olacak. Kılavuzlar güncellendiğinde içerik de gözden geçirilecek.
5. İlaç dozları ve protokoller kurumdan kuruma değişebileceği için, uygulamada "kurumunuzun protokolü önceliklidir" uyarısı yer alacak.

### Teknik kararlar ve maliyet
| Konu | Karar | Sade açıklama | Ücret |
|---|---|---|---|
| Yapım aracı | **Flutter** | Google'ın aracı. Önce Android, ileride aynı kodla iPhone. | Ücretsiz |
| Veriler | **Uygulamanın içinde** | Bütün bilgiler uygulamayla birlikte gelir. İnternet yokken de (ameliyathane, bodrum kat) çalışır. Sunucu yok. | Ücretsiz |
| İçeriğin saklanması | **GitHub'da düz metin dosyaları** | Her hastalık ve ilaç ayrı bir dosyada durur. Değişiklik geçmişi tutulur: kim, neyi, ne zaman değiştirdi görülür. | Ücretsiz |
| Uygulamanın hazırlanması | **GitHub Actions** | Her değişiklikten sonra kurulabilir Android dosyası (APK) otomatik hazırlanır. | Ücretsiz |
| Meslektaşlara dağıtım (ilk aşama) | APK dosyasını doğrudan paylaşmak | Dosya WhatsApp veya e-posta ile gönderilir, telefona kurulur. | Ücretsiz |
| Google Play'de yayın (sonraki aşama) | Geliştirici hesabı | Herkese açmak istendiğinde. | Tek seferlik yaklaşık 25 $ |

---

## 2. Modüller (Uygulamanın Bölümleri)

Uygulamanın ana ekranında 8 büyük bölüm olacak:

```
┌─────────────────────────────────────────┐
│  🔍  Ara: hastalık, ilaç, prosedür...   │
├───────────────────┬─────────────────────┤
│ 🧠 İnme Merkezi   │ 💓 CPR Zamanlayıcı  │
├───────────────────┼─────────────────────┤
│ 📋 Ölçekler       │ 🩺 Nörolojik Muayene│
├───────────────────┼─────────────────────┤
│ 📚 Hastalıklar    │ 💊 İlaç Rehberi     │
├───────────────────┼─────────────────────┤
│ 👩‍⚕️ Hemşirelik     │ 📝 Ünite Protokolleri│
└───────────────────┴─────────────────────┘
```

### Modül 1: 🧠 İnme Merkezi
En kapsamlı bölüm.

**1a. İnme tipleri**
- İskemik inme: alt tipleri (TOAST sınıflaması: büyük damar, kardiyoembolik, küçük damar/laküner, diğer, nedeni belirlenemeyen)
- Hemorajik inme: intraserebral kanama, subaraknoid kanama
- TİA (geçici iskemik atak)
- Her tip için: tanım, belirtiler, tanı, acil yaklaşım, tedavi, hemşirelik bakımı, komplikasyonlar ve kaynaklar

**1b. Etkileşimli beyin damar haritası** (görsel)
- Willis poligonu ve ana damarlar: ICA, ACA, MCA (M1/M2), PCA, vertebral ve baziler arterler
- Beyin üzerinde hangi damarın hangi bölgeyi beslediği renkli olarak gösterilir
- Bir damara veya bölgeye dokunulduğunda o damar tıkanırsa görülen belirtiler açılır. Örneğin sol MCA tıkanıklığında sağ hemiparezi ve afazi.
- Görseller telif sorunu olmaması için Claude tarafından sıfırdan çizilir.

**1c. Trombektomi (mekanik trombektomi)**
- Kimlere yapılır: endikasyonlar ve zaman pencereleri (0–6 saat, seçilmiş hastalarda 6–24 saat)
- Hangi tıkanıklıklarda yapılır: ICA, M1, seçilmiş M2, baziler
- Nasıl yapılır: kateterin femoral veya radial arterden girip aort ve karotis üzerinden pıhtıya ulaştığı yolun **adım adım animasyonlu görseli**
- Stent retriever ve aspirasyon yöntemleri (basit anlatım)
- Hemşirenin görevleri: işlem öncesi, sırası ve sonrası

**1d. Trombolitik tedavi (IV tPA veya tenekteplaz)**
- Uygunluk ve dışlama kriterleri için kontrol listesi
- Hazırlama ve verilme adımları
- Tedavi sırasında ve sonrasında kan basıncı hedefleri
- Kanama veya anjiyoödem gelişirse ne yapılacağı

**1e. Post-op ve post-tedavi takip**
- Trombektomi ve trombolitik sonrası **takip sıklığı çizelgesi**. Örneğin kılavuzlarda geçen: ilk 2 saat 15 dakikada bir, sonraki 6 saat 30 dakikada bir, 24. saate kadar saatte bir nörolojik muayene ve vital bulgular.
- Kateter giriş yeri (kasık veya bilek) bakımı, kanama ve hematom kontrolü, distal nabız takibi
- Kan basıncı hedefleri
- Hangi durumda hekime hemen haber verilir: kırmızı bayrak listesi
- İsteğe bağlı **takip zamanlayıcısı**: "Bir sonraki nörolojik kontrol 15 dakika sonra" şeklinde hatırlatma. Hasta bilgisi girilmez, sadece "Yatak 3" gibi bir etiket yazılabilir.

### Modül 2: 💓 CPR Zamanlayıcı
Resüsitasyon sırasında tek elle ve hızlıca kullanılabilecek şekilde tasarlanır.
- Büyük "**BAŞLAT**" butonu ve toplam CPR süresi
- **2 dakikalık döngü sayacı:** her 2 dakikada sesli ve titreşimli "Ritim ve nabız kontrolü" uyarısı
- **Adrenalin sayacı:** "Adrenalin verildi" butonuna basıldığında bir sonraki doz için 3–5 dakikalık geri sayım başlar; zamanı gelince uyarır
- Şok, amiodaron, entübasyon ve ROSC için tek dokunuşlu kayıt butonları
- Metronom: dakikada 100–120 vuruşla göğüs kompresyonu ritmi
- Geri döndürülebilir nedenler hatırlatıcısı (4H ve 4T)
- **İşlem sonu özeti:** saat saat neyin yapıldığının listesi; ekran görüntüsü alınabilir veya kopyalanabilir. Hasta adı yoktur ve kayıt kalıcı olarak saklanmaz.
- CPR sürerken ekran kapanmaz
- Kaynak: güncel AHA ve ERC resüsitasyon kılavuzları

**Resüsitasyon bilgi bölümü** (sonraki sürümlerde, CPR ekranından erişilecek)
- [ ] **EKG ritimleri:** VF, nabızsız VT, asistoli, NEA, sinüs bradikardisi, AV bloklar, SVT, AF/flutter, geniş QRS'li taşikardi, torsades de pointes. Her biri için çizilmiş örnek trase, tanıma ipuçları, şoklanabilir mi, ne yapılır.
- [ ] **Defibrilasyon:** endikasyon, bifazik/monofazik enerji dozları, ped yerleşimi, güvenlik ("herkes uzak").
- [ ] **Senkronize kardiyoversiyon:** endikasyon (nabızlı, stabil olmayan taşikardi), enerji dozları, sedasyon, senkronizasyon tuşu.
- [ ] **Antiaritmik ilaçlar:** amiodaron (arrest ve nabızlı taşikardi dozları, hazırlama, yan etkiler), lidokain, magnezyum (torsades), adenozin (SVT).
- [ ] **Bradikardi ve taşikardi algoritmaları** (nabızlı hasta): atropin, transkutan pace, dopamin/adrenalin infüzyonu.
- [ ] **ROSC sonrası bakım:** oksijen ve ventilasyon hedefleri, kan basıncı hedefi, 12 derivasyon EKG, sıcaklık kontrolü, nörolojik değerlendirme.

**CPR zamanlayıcı için aday geliştirmeler** (önceliği ürün sahibi belirleyecek)
- [ ] Şoklanabilir ritim seçilince şok hatırlatması; 3. ve 5. şoktan sonra amiodaron hatırlatması
- [ ] Damar yolu/IO, ETCO₂ değeri ve "diğer ilaç" (bikarbonat, kalsiyum, magnezyum, sıvı) kaydı
- [ ] İşaretlenebilir 4H4T kontrol listesi; işaretlenenler özete eklenir
- [ ] Sonlandırma nedeni (ROSC, exitus, transfer) ve kalite süreleri (ilk kompresyon, ilk şok)
- [ ] Sesli uyarı ("Nabız kontrolü zamanı") ve ekran kilitliyken bildirim
- [ ] Özeti PDF olarak paylaşma

### Modül 3: 📋 Ölçekler (NIHSS ve diğerleri)
İlk ölçek NIHSS. Hemşirelik ölçekleri (düşme, bası yarası, yutma) Modül 8'de anlatılıyor ama bu ekranda da listelenecek.

**NIHSS Hesaplayıcı**
- 15 maddenin her biri ayrı bir ekranda: maddenin nasıl değerlendirileceği, puan seçenekleri ve sık yapılan hatalar
- Toplam puan otomatik hesaplanır; puanın ne anlama geldiği gösterilir (hafif, orta, ağır inme)
- Sonuç bölümünde hangi maddeden kaç puan alındığı görünür
- İsteğe bağlı: aynı hasta için zaman içindeki puanları karşılaştırma (yalnızca o oturum boyunca, isim girilmeden)
- **Öğrenme modu:** her maddenin açıklaması ve örnekler
- Ek ölçekler (sonraki sürüm): Glasgow Koma Skalası, Modifiye Rankin Ölçeği, FOUR skoru, ICH skoru, Hunt-Hess ve WFNS (subaraknoid kanama)

### Modül 4: 🩺 Nörolojik Muayene Rehberi
Adım adım, görsellerle:
- Bilinç düzeyi (GKS dahil)
- Pupil muayenesi: boyut, eşitlik, ışık refleksi
- Kraniyal sinirler (12 sinir; her biri nasıl test edilir)
- Motor muayene ve kas gücü derecelendirmesi (0–5)
- Duyu muayenesi
- Refleksler ve Babinski
- Serebellar testler: parmak-burun, topuk-diz
- Meningeal irritasyon bulguları: ense sertliği, Kernig, Brudzinski
- **Hızlı nörolojik kontrol kartı:** post-op takipte her kontrolde neye bakılacağının kısa listesi

### Modül 5: 📚 Hastalık Kütüphanesi
Her hastalık için aynı düzende bir kart: **Tanım · Belirtiler · Tanı · Tedavi · Hemşirelik bakımı · Komplikasyonlar · Kaynaklar**

İlk eklenecek hastalıklar (öncelik sırasıyla):
1. İskemik inme ve TİA
2. İntraserebral kanama
3. Subaraknoid kanama ve vazospazm
4. Epilepsi ve status epileptikus
5. Kafa içi basınç artışı
6. Miyastenia gravis ve miyastenik kriz
7. Guillain-Barré sendromu
8. Multipl skleroz (atak tedavisi dahil)
9. Menenjit ve ensefalit
10. Parkinson hastalığı
11. Migren ve diğer baş ağrıları
12. Demans ve deliryum
13. ALS
14. Serebral venöz sinüs trombozu

### Modül 6: 💊 İlaç Rehberi
Her ilaç için aynı düzende: **Etki mekanizması · Endikasyon · Hazırlanışı (sulandırma, seyreltme) · Veriliş yolu ve hızı · Dozu · Yan etkiler ve olası reaksiyonlar · İzlem · Hemşirelik uyarıları · Antidot (varsa) · Kaynak**

İlk eklenecek ilaçlar:
| Grup | İlaçlar |
|---|---|
| Trombolitik | Alteplaz, tenekteplaz |
| Antikoagülan ve antidotları | Heparin, düşük molekül ağırlıklı heparin, protamin, K vitamini, protrombin kompleks konsantresi (PCC), idarusizumab |
| Antiagregan | Asetilsalisilik asit, klopidogrel |
| Antihipertansif (acil) | Labetalol, nikardipin, urapidil |
| SAK ve vazospazm | Nimodipin |
| Kafa içi basınç | Mannitol, %3 NaCl |
| Antiepileptik | Diazepam, midazolam, levetirasetam, fenitoin, valproat, lakozamid |
| Nöroimmünoloji | IVIG, metilprednizolon (pulse), piridostigmin |
| Resüsitasyon | Adrenalin, amiodaron, atropin |

- **Doz hesaplayıcı** (örneğin kiloya göre alteplaz dozu: toplam doz, bolus ve infüzyon): tıbbi cihaz mevzuatı açısından ek dikkat ister. Bu yüzden ilk sürümde formül ve örnek hesap gösterilecek; etkileşimli hesaplayıcı, uyarı metinleri ve hekim onayıyla sonraki sürümde eklenecek.

### Modül 7: 📝 Ünite Protokollerim
- Kullanıcı kendi ünitesinin protokollerini, sık kullanılan tedavi şemalarını ve notlarını kaydedebilir
- Örnek: "Ünitemizde status epileptikus akışı", "Nimodipin hazırlama: bizim eczanenin talimatı"
- Bu notlar yalnızca kullanıcının kendi telefonunda saklanır
- **Hasta adı veya kimlik bilgisi girilmemesi için** ekranda uyarı bulunur
- Notlar dışa aktarılıp ekip arkadaşlarıyla paylaşılabilir (dosya olarak)

### Modül 8: 👩‍⚕️ Hemşirelik ve Hasta Güvenliği

**8a. Hemşirelik tanıları**
- Nöroloji hastalarında sık kullanılan tanılar. Örnekler: serebral doku perfüzyonunda etkisizlik riski, düşme riski, bozulmuş fiziksel mobilite, yutmada bozulma, aspirasyon riski, sözel iletişimde bozulma, deri bütünlüğünde bozulma riski, öz bakım eksikliği.
- Her tanı için: ilişkili faktörler, tanımlayıcı özellikler, hedefler, hemşirelik girişimleri ve değerlendirme.
- Hastalık kartlarından ilgili hemşirelik tanılarına bağlantı. Örneğin inme kartından "yutmada bozulma" tanısına geçilebilir.
- ⚠️ NANDA-I sınıflaması telif kapsamındadır. Tanı adları kullanılır; tanımlar kopyalanmaz, kendi cümlelerimizle yazılır.

**8b. Hemşirelik ölçekleri** (puanlanabilir; "Ölçekler" bölümünde NIHSS ile birlikte)
- **Düşme riski:** İtaki Düşme Riski Ölçeği (Sağlık Bakanlığı'nın kullandığı) ve Morse Düşme Ölçeği
- **Bası yarası riski:** Braden Ölçeği ve bası yarası evrelendirmesi (Evre 1–4, evrelendirilemeyen, derin doku hasarı), her evre için görsel ve bakım önerileri
- **Yutma taraması:** inme hastalarında oral alım öncesi yatak başı yutma testi (GUSS gibi)
- Ölçek sonucuna göre önerilen önlemler (örneğin yüksek düşme riski görülünce yapılacaklar listesi)
- ⚠️ Bazı ölçeklerin (örneğin Braden) yazılımda kullanımı lisans gerektirebilir. Her ölçeğin kullanım izni eklenmeden önce kontrol edilecek; gerekirse lisans istenecek ya da serbest kullanılabilen bir alternatif seçilecek.

**8c. Acil durum kodları**
- Sağlıkta Kalite Standartları'ndaki (SKS) kodlar: **Mavi Kod** (kardiyopulmoner arrest), **Pembe Kod** (bebek veya çocuk kaçırılması), **Beyaz Kod** (sağlık çalışanına şiddet), ayrıca kurumda kullanılan diğer kodlar (yangın, afet vb.)
- Her kod için: ne zaman verilir, nasıl verilir (dahili numara), kim ne yapar, hedef müdahale süresi
- Kod adları ve dahili numaralar kurumdan kuruma değiştiği için **kullanıcı kendi hastanesine göre düzenleyebilecek**
- CPR Zamanlayıcı ekranından Mavi Kod bilgisine hızlı geçiş

**8d. Hasta güvenliği ve akreditasyon (JCI ve SKS)**
- **JCI Uluslararası Hasta Güvenliği Hedefleri** (6 hedef): hasta kimliğinin doğru tanımlanması, etkili iletişim (sözel order, kritik değer bildirimi, devir teslim için SBAR), yüksek riskli ilaçların güvenliği, doğru taraf, doğru prosedür ve doğru hasta, enfeksiyon riskinin azaltılması (el hijyeni, 5 endikasyon), düşme kaynaklı zararın azaltılması
- Hemşirelerin denetimlerde sık sorulan konuları: yüksek riskli ilaçlar ve benzer isimli ilaçlar listesi, ağrı değerlendirmesi, kısıtlama uygulaması, hasta eğitimi kayıtları, olay bildirimi
- Türkiye'deki hastaneler için **SKS** karşılıkları (JCI'ya benzer ulusal standartlar)
- ⚠️ JCI ve SKS standart metinleri kopyalanmaz; özetlenip kaynak ve sürüm bilgisi verilir. Standartlar her birkaç yılda güncellendiği için "son kontrol tarihi" burada özellikle önemlidir.

### Her yerde olacak ortak özellikler
- 🔍 **Arama:** tüm hastalık, ilaç ve prosedürlerde
- ⭐ **Favoriler:** sık bakılan sayfalar ana ekranda
- 📶 **İnternetsiz çalışma**
- 🌙 **Karanlık mod:** gece nöbetinde göz yormaz
- 🔤 Yazı boyutu ayarı
- ⚠️ Açılışta tek seferlik "Bu uygulama sağlık profesyonelleri içindir; klinik kararın yerine geçmez" onayı

---

## 3. Sürüm Planı

### Sürüm 0.1: "İlk Deneme" (hedef: ilk 1–2 hafta)
İskelet uygulama. Telefonuna kurup dolaşabileceğin ilk hal.
- [x] Flutter projesi, ana ekran ve 8 modülün boş sayfaları
- [ ] GitHub Actions ile otomatik APK üretimi
- [x] **CPR Zamanlayıcı** (tam çalışır halde; içerik gerektirmediği için ilk yapılacak araç)
- [x] **NIHSS Hesaplayıcı** (tam çalışır halde)
- [x] Açılış uyarısı, karanlık mod
- ✅ **Senin işin:** APK'yı telefonuna kurmak, iki aracı denemek, geri bildirim vermek

### Sürüm 0.2: "İnme Merkezi" (sonraki 2–3 hafta)
- [x] İçerik altyapısı: kaynak, onay durumu, son kontrol tarihi
- [x] İnme tipleri içeriği (taslak; senin onayın bekleniyor)
- [x] Etkileşimli beyin damar haritası (beyin kesiti ve Willis poligonu)
- [x] ~~Trombektomi adım adım görsel anlatımı~~ (ürün sahibinin kararıyla çıkarıldı)
- [x] Trombolitik tedavi kontrol listesi
- [x] Post-op ve post-tedavi takip çizelgesi
- [x] İzlem takip zamanlayıcısı (bildirimli, birden fazla yatak)
- [x] Trombolitik tedavi ve mekanik trombektomi metinleri
- ✅ **Senin işin:** İnme içeriklerini okuyup düzeltmeleri bana yazmak

### Sürüm 0.3: "İlaçlar ve Muayene" (sonraki 2–3 hafta)
- [x] İlaç rehberi: 74 ilaç (taslak; hemşire onayı bekleniyor), kategori süzme ve arama
- [x] Nörolojik muayene rehberi (10 sayfa), GKS, mRS, pupil cetveli
- [x] Arama ve favoriler (0.9'da eklendi)
- ✅ **Senin işin:** İlaç bilgilerini kendi ünitendeki uygulamayla karşılaştırmak

### Sürüm 0.4: "Hastalık Kütüphanesi" (sonraki 3–4 hafta)
- [x] Hastalık kütüphanesi: 15 hastalık (inme sayfalarıyla ortak), gruplu liste ve arama
- [x] Ünite Protokollerim bölümü (0.7.0'da eklendi)
- ✅ **Senin işin:** İçerik onayı

### Sürüm 0.5: "Hemşirelik ve Hasta Güvenliği" (sonraki 2–3 hafta)
- [x] Hemşirelik tanıları (9)
- [x] Morse ve Norton hesaplayıcıları, bası yarası evreleri, yutma taraması
- [ ] İtaki (kurum formu bekleniyor), Braden (lisans izni gerekiyor)
- [x] Acil durum kodları (hastaneye göre düzenlenebilir)
- [x] JCI hasta güvenliği hedefleri ve SKS karşılıkları
- ✅ **Senin işin:** Kendi hastanendeki kod numaralarını ve uygulamaları karşılaştırmak

### Sürüm 0.6.1: "Hemşirelik bakımı ayrıntıları"
- [x] Bası yarası ekranı: altı evrenin deri kesiti çizimleri, pozisyonlara göre risk bölgeleri, ayrıntılı önleme ve tedavi (SSKIN, beslenme, evreye göre bakım)
- [x] Yeni bakım rehberleri: ağrı değerlendirmesi, inmede pozisyon, NG sonda ve enteral beslenme, idrar sondası (CAUTI), ağız bakımı, DVT önlemleri, fiziksel kısıtlama
- [x] Hasta güvenliği: güvenli ilaç uygulama, izolasyon önlemleri, SBAR örnekleri, JCI/SKS denetim soruları ve örnek cevaplar

### Sürüm 0.7: "Ünite Protokollerim"
- [x] Kendi protokollerini yazma, düzenleme, silme; yalnızca telefonda saklanır
- [x] Hazır şablonlar: akış şeması, ilaç hazırlama, tedavi şeması, kontrol listesi
- [x] Arama ve türe göre süzme; biçimli önizleme
- [x] Mesajla paylaşma ve arkadaşın gönderdiği metni içe aktarma
- [x] Kişisel veri uyarısı (T.C. kimlik no, telefon, hasta adı kalıpları)

### Sürüm 0.8: "Vardiyam"
- [x] Vardiya başlatma (08–16, 08–20, 20–08, 16–08, 24 saat)
- [x] Yatak numarasıyla ilaç ve iş hatırlatmaları; hızlı seçim, tekrar (vardiya sonuna kadar), önemli işe 10 dk önce ek bildirim
- [x] Zamanı geçen / sıradaki / yapıldı listeleri; saate veya yatağa göre görünüm; erteleme
- [x] Devir özeti (kopyala, paylaş); vardiya bitince liste silinir, unutulursa 12 saat sonra kendiliğinden silinir
- [x] Ana ekranda sıradaki işi gösteren kart

### Sürüm 0.9: "Elimin altında"
- [x] Genel arama (ilaç, hastalık, hemşirelik, muayene, resüsitasyon sayfaları, ritimler, ölçekler, araçlar, kendi protokollerim) ve favoriler
- [x] İnfüzyon hesaplayıcı: dozdan hıza / hızdan doza, 20 ilaç için doz birimi, olağan aralık ve örnek hazırlık, doz tablosu; yükleme dozu (levetirasetam, valproat, fenitoin hız sınırı); mL/sa ve damla hesabı
- [x] İlaç sayfalarında infüzyon kartı ve hesaplayıcıya geçiş
- [x] EKG ve Resüsitasyon: 17 ritim çizimi, tanıma ipucu ve yapılacaklar; adım adım EKG okuma ve hız hesabı; arrest, bradikardi, taşikardi, defibrilasyon/kardiyoversiyon, ROSC ve ilaç sayfaları

### Sürüm 0.10: "Yeni görünüm"
- [x] Bordo ve krem renkler (açık ve koyu tema)
- [x] Bölümlere ayrılmış ana ekran: Acil, Hesapla, Bilgi, Benim
- [x] Alt menü: Ana sayfa, Ara, Favoriler, Vardiyam
- [x] Ayarlar: yazı boyutu (Normal, Büyük, Çok büyük) ve tema
- [x] Yeni uygulama simgesi ve açılış ekranı (tool/gen_icon.py ile üretilir)

### Sürüm 1.0: "Meslektaşlarla Paylaşım"
- [ ] Bütün içeriğin hemşire onaylı olması
- [ ] 5–10 meslektaşla deneme (APK paylaşımı) ve geri bildirimlerin toplanması
- [ ] Hataların düzeltilmesi, son cilalama
- [ ] Gizlilik politikası ve kullanım koşulları sayfası (ücretsiz, GitHub Pages)

### Sonraki adımlar (1.0 sonrası)
- [ ] Google Play'de yayın (yaklaşık 25 $)
- [ ] Ek ölçekler: ICH, Hunt-Hess, FOUR (GKS ve mRS 0.4'te eklendi)
- [x] tPA/tenekteplaz doz hesaplayıcı (ürün sahibinin isteğiyle 0.2.2'de eklendi; iki kişi kontrolü uyarısıyla)
- [x] Diğer etkileşimli doz hesaplayıcıları (0.9: infüzyon hesaplayıcı)
- [ ] **Uygulama güncellenmeden içerik güncelleme:** içerik internetten ücretsiz olarak indirilir, internet yoksa en son indirilen sürüm kullanılır
- [ ] Bilgi testleri ve vaka senaryoları (eğitim modu, hizmet içi eğitim için)
- [ ] iPhone sürümü (App Store yaklaşık 99 $/yıl)
- [ ] İngilizce dil desteği

> **Not:** Süreler tahminidir. Kodlamayı ben hızlı yapabilirim; asıl belirleyici olan, tıbbi içeriğin senin tarafından kontrol edilme hızıdır. Acele etmeye gerek yok, doğruluk her şeyden önemli.

---

## 4. İçerik Hazırlama Süreci

Her hastalık veya ilaç kartı şu yolu izler:

```
1. Claude taslak hazırlar          → kaynak ve kanıt düzeyiyle, 🟡 Taslak
2. Sen okursun                     → düzeltmeleri günlük dille yazarsın
3. Claude düzeltir                 → sen tekrar bakarsın
4. Sen onaylarsın                  → 🟢 Hemşire onaylı
5. (İleride, fırsat olursa) Hekim  → 🔵 Hekim onaylı
6. Uygulamaya girer
```

**Kullanılacak başlıca kaynaklar:**
- AHA/ASA akut iskemik inme kılavuzu ve intraserebral kanama kılavuzu (güncel sürümler)
- ESO (Avrupa İnme Örgütü) kılavuzları
- AHA ve ERC resüsitasyon kılavuzları
- NIH İnme Ölçeği resmi eğitim materyali (NINDS)
- Türk Nöroloji Derneği tanı ve tedavi kılavuzları
- Hakemli dergilerdeki sistematik derleme ve meta-analizler (PubMed)
- İlaçlar için ruhsat bilgileri (KÜB / KT) ve standart ilaç başvuru kaynakları

**Telif kuralı:** Makalelerden ve kitaplardan metin veya görsel kopyalanmaz. Bilgi özetlenip kendi cümlelerimizle yazılır, kaynak gösterilir. Bütün görseller sıfırdan çizilir.

---

## 5. Yasal Çerçeve (sade)
- **Kişisel veri yok** → KVKK açısından risk çok düşük. "Ünite Protokollerim" ve zamanlayıcılarda hasta adı girilmemesi için uyarı olacak. Bu bilgiler telefondan dışarı gönderilmeyecek.
- **Tıbbi cihaz mevzuatı:** Sadece bilgi veren bir başvuru kitabı genelde tıbbi cihaz sayılmaz. Ancak hastaya özel **doz hesaplayan** veya **tedavi kararı öneren** özellikler sayılabilir. Bu yüzden:
  - NIHSS ve CPR zamanlayıcısı karar vermez; sadece puanlar ve zaman tutar. Düşük risklidir.
  - Etkileşimli doz hesaplayıcıları 1.0 sonrasına bırakıldı.
  - Google Play'de herkese açık yayından önce bir hukukçuya kısaca danışılması önerilir.
- **Sorumluluk reddi:** "Klinik kararın yerine geçmez, kurum protokolleri önceliklidir" uyarısı.

---

## 6. Teknik Mimari (Claude için notlar)
- **Flutter** (Dart). Durum yönetimi Riverpod, yönlendirme go_router.
- **İçerik:** `content/` klasöründe her kart için bir Markdown dosyası. Kartın kimliği, başlığı, kategorisi, onay durumu, son kontrol tarihi ve kaynakları dosyanın başında YAML bilgisi olarak tutulur. Dosyalar derleme sırasında uygulamaya gömülür.
- **Arama:** cihazda tam metin arama (SQLite FTS5) veya basit bellek içi indeks.
- **Görseller:** SVG (beyin damar haritası etkileşimli: her bölge ayrı bir yol olarak tanımlanır). Animasyonlar için Rive veya Flutter animasyonları.
- **CPR zamanlayıcı:** ekranın açık kalması (wakelock), yerel bildirim ve ses, titreşim. Uygulama arka plana geçse de sayacın doğru kalması için gerçek zaman damgası kullanılır.
- **Ünite protokolleri:** cihazda SQLite (Drift); JSON dışa ve içe aktarma.
- **CI:** GitHub Actions ile `flutter analyze`, `flutter test` ve `flutter build apk`. APK, Actions çıktısı olarak ve etiketli sürümlerde GitHub Releases'ta yayınlanır.
- **Testler:** NIHSS puan hesaplama, CPR zamanlayıcı mantığı ve içerik dosyalarının doğrulanması (her kartta kaynak ve onay alanı zorunlu) için birim testleri.

---

## 7. Açık Sorular (senin için)
- [x] Tedavi kaydı → ünitede kullanılan isimsiz tedavi şemaları (Modül 7)
- [x] Ek bölümler → hemşirelik tanıları, düşme ve bası yarası ölçekleri, acil durum kodları, JCI (Modül 8)
- [x] İçerik kontrolü → kendi bilgimle teyit edeceğim; hekim kontrolü isteğe bağlı
- [x] Uygulamanın adı: **NöroCep** (şimdilik; ileride değiştirilebilir)

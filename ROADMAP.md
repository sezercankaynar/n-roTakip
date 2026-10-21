# NöroTakip: İş Haritası

Nörolojik hastalığı olan kişilerin (epilepsi, migren, MS, Parkinson vb.) semptomlarını, nöbetlerini ve ilaçlarını günlük olarak kaydedip bu verileri hekimleriyle paylaşabildiği bir mobil uygulama.

> Bu belge yaşayan bir dokümandır. Kararlar netleştikçe güncellenir. `[ ]` yapılacak, `[x]` tamamlandı demektir.

---

## 0. Ürün Vizyonu

**Sorun:** Hastalar nöbetlerini, ağrı ataklarını ve ilaç dozlarını çoğunlukla hatırlayarak ya da kâğıda not ederek takip ediyor. Kontrol muayenesinde hekime eksik ve dağınık bilgi ulaşıyor.

**Çözüm:** Hızlı kayıt (tek dokunuşla nöbet veya atak), ilaç hatırlatıcı ve hekime gösterilebilen düzenli raporlar.

**Hedef kullanıcılar**
| Persona | İhtiyaç |
|---|---|
| Hasta | Hızlı ve kolay kayıt, hatırlatıcılar, kendi gidişatını görmek |
| Hasta yakını / bakım veren | Hasta adına kayıt girmek, acil durumda bilgilendirilmek |
| Nörolog (ileriki faz) | Muayene öncesi özet rapor, eğilimler, ilaca uyum |

**Başarı ölçütleri (MVP)**
- Aktif kullanıcıların %60'ı haftada en az 3 gün kayıt giriyor
- İlaç hatırlatıcılarına uyum oranı %80'in üzerinde
- Kullanıcıların en az %30'u bir PDF raporu dışa aktarıyor veya paylaşıyor

---

## 1. Kritik Kararlar (Faz 0'da verilecek)

### 1.1 Teknoloji seçimi
| Seçenek | Artıları | Eksileri |
|---|---|---|
| **Flutter** (önerilen) | Tek kod tabanıyla iOS ve Android; tutarlı arayüz; güçlü grafik ve yerel bildirim paketleri; HealthKit/Health Connect eklentileri mevcut | Dart öğrenmek gerekebilir |
| React Native (Expo) | JS/TS ekipleri için tanıdık; OTA güncelleme; web paneliyle kod paylaşımı | Native modüllerde (sağlık API'leri, arka plan) ek uğraş |
| Native (Swift + Kotlin) | En iyi performans ve platform entegrasyonu | İki ayrı kod tabanı, yaklaşık iki kat maliyet |

**Öneri:** Flutter. Ekip JS/TS ağırlıklıysa ve ileride bir web hekim paneli planlanıyorsa React Native (Expo) da makul bir seçimdir.

**Backend seçenekleri**
- **Supabase** (Postgres, Auth, Storage, Row Level Security): hızlı başlangıç, SQL, kendi sunucusunda barındırılabilir. KVKK için Türkiye veya AB'de barındırma kolay. **Önerilen.**
- Firebase: çok hızlı başlangıç, ancak veri yurt dışında tutulur ve sorgu yetenekleri sınırlıdır.
- Özel backend (NestJS veya FastAPI + Postgres): tam kontrol sağlar, ancak daha uzun sürer.

### 1.2 Yasal çerçeve (Türkiye)
- **KVKK:** Sağlık verisi *özel nitelikli kişisel veri* sayılır. Açık rıza, aydınlatma metni, VERBİS kaydı (eşik aşılırsa), veri işleme envanteri ve yurt dışına aktarım kuralları gerekir.
- **Tıbbi cihaz yazılımı riski:** Uygulama teşhis koyar veya tedavi önerirse TİTCK / MDR kapsamında tıbbi cihaz sayılabilir. **MVP'de yalnızca kayıt tutma ve raporlama yapılacak; teşhis veya doz önerisi verilmeyecek.** Uygulama içinde "tıbbi tavsiye değildir" uyarısı yer alacak.
- Uygulama mağazası kuralları: Apple ve Google'ın sağlık uygulaması politikaları ve gizlilik etiketleri.
- Bu konularda bir hukuk danışmanından görüş alınması önerilir.

---

## 2. Fazlar

Aşağıdaki süreler 2–3 kişilik küçük bir ekip (mobil, backend/full-stack, yarı zamanlı tasarım) için yaklaşık değerlerdir. Tek geliştiriciyle çalışılırsa süreleri yaklaşık 1,5 ile çarpın.

### Faz 0: Keşif ve Planlama (1–2 hafta)
- [ ] 5–10 hasta ve en az 2 nörologla görüşme; ihtiyaçların doğrulanması
- [ ] Hedef hastalığın seçilmesi: MVP'yi tek bir hastalığa odaklamak (öneri: **epilepsi** veya **migren**) ve kalanları sonraya bırakmak
- [ ] Rakip analizi (Seizure Tracker, Epsy, Migraine Buddy, Bearable)
- [ ] Teknoloji kararı (bkz. 1.1) ve bunun `docs/adr/` altına mimari karar kaydı olarak yazılması
- [ ] KVKK ön değerlendirmesi ve tıbbi cihaz kapsamı için hukuki görüş
- [ ] MVP kapsamının dondurulması (bkz. Bölüm 3)
- [ ] Proje yönetimi: GitHub Projects tahtası, issue şablonları, etiketler

**Çıktı:** Onaylı MVP kapsamı, teknoloji kararı, kişi listesi (persona) ve kullanıcı yolculuğu haritası.

### Faz 1: Tasarım (2–3 hafta, Faz 2 ile kısmen paralel)
- [ ] Bilgi mimarisi ve ekran akışları
- [ ] Wireframe'ler: kayıt ve giriş, onboarding, ana sayfa, hızlı kayıt, ilaçlar, takvim, rapor
- [ ] Tasarım sistemi: renkler, tipografi, bileşenler (Figma)
- [ ] **Erişilebilirlik öncelikli tasarım:** büyük dokunma alanları, yüksek kontrast, dinamik yazı boyutu, ekran okuyucu desteği. Titreme veya bilişsel zorluk yaşayan kullanıcılar düşünülmeli.
- [ ] Yüksek çözünürlüklü tasarımlar ve tıklanabilir prototip
- [ ] Prototipin 3–5 kullanıcıyla test edilmesi

### Faz 2: Altyapı ve Temel Kurulum (1–2 hafta)
- [ ] Mono-repo yapısı: `/mobile`, `/backend` (veya `/supabase`), `/docs`
- [ ] Mobil proje iskeleti: klasör yapısı, durum yönetimi (Riverpod veya Bloc), yönlendirme, tema, i18n (TR ve EN)
- [ ] Ortamlar: dev, staging ve prod
- [ ] CI/CD: GitHub Actions ile lint, test ve derleme; Fastlane veya Codemagic ile TestFlight ve Play Internal dağıtımı
- [ ] Veritabanı şeması v1 ve migration'lar
- [ ] Kimlik doğrulama: e-posta ile şifre, Apple ile giriş, Google ile giriş
- [ ] Hata izleme (Sentry) ve gizliliğe saygılı analitik (PostHog, kendi sunucusunda veya AB'de)
- [ ] Güvenlik temeli: TLS, Row Level Security politikaları, cihazda güvenli saklama (Keychain ve Keystore)

### Faz 3: MVP Geliştirme (6–8 hafta)

**Sprint 1: Hesap ve Profil**
- [ ] Onboarding, KVKK aydınlatma metni ve açık rıza ekranı (rıza kaydı tutularak)
- [ ] Profil: tanı, doğum yılı, hekim bilgisi (isteğe bağlı), acil durum kişisi
- [ ] Uygulama kilidi: PIN veya biyometrik

**Sprint 2: Olay Kaydı (çekirdek özellik)**
- [ ] **Hızlı kayıt butonu:** tek dokunuşla "şu an nöbet/atak başladı" kaydı ve kronometre
- [ ] Ayrıntılı kayıt: tür, süre, şiddet (1–10), tetikleyiciler (uykusuzluk, stres, ışık, adet döngüsü…), belirtiler, notlar
- [ ] Geçmiş kayıtları düzenleme ve silme
- [ ] **Çevrimdışı öncelikli çalışma:** yerel veritabanı (Drift/SQLite veya Isar) ve bağlantı gelince senkronizasyon

**Sprint 3: İlaç Yönetimi**
- [ ] İlaç ekleme: ad, doz, sıklık, saatler
- [ ] Yerel bildirimle hatırlatıcılar; "aldım / atladım / ertele" eylemleri
- [ ] İlaca uyum geçmişi
- [ ] Yaygın nöroloji ilaçları için öneri listesi (veri kaynağı netleştirilecek)

**Sprint 4: Günlük ve Görselleştirme**
- [ ] Günlük check-in: ruh hali, uyku süresi, stres, genel durum (30 saniyeden kısa sürmeli)
- [ ] Takvim görünümü: olaylar ve ilaç uyumu
- [ ] Grafikler: aylık olay sayısı, ortalama şiddet, en sık tetikleyiciler, ilaç değişikliğiyle ilişkisi

**Sprint 5: Rapor ve Paylaşım**
- [ ] Seçilen tarih aralığı için PDF rapor (hekime gösterilecek formatta)
- [ ] Paylaşım: e-posta, WhatsApp, yazdırma
- [ ] Veri dışa aktarma (CSV/JSON) ve hesap silme (KVKK kapsamındaki haklar)

**Sprint 6: Cilalama**
- [ ] Boş, yükleme ve hata durumları
- [ ] Erişilebilirlik denetimi (VoiceOver ve TalkBack)
- [ ] Performans: soğuk açılış süresi 2 saniyenin altında
- [ ] Uygulama içi geri bildirim formu

### Faz 4: Test ve Kalite (2 hafta, geliştirme boyunca da sürer)
- [ ] Birim testleri (iş mantığı için %70'in üzerinde kapsam hedefi)
- [ ] Widget ve entegrasyon testleri (kritik akışlar: kayıt, olay ekleme, hatırlatıcı, rapor)
- [ ] Çevrimdışı ve senkronizasyon senaryoları, çakışma çözümü
- [ ] Güvenlik testi: OWASP MASVS kontrol listesi, temel sızma testi
- [ ] Bildirimlerin farklı cihazlarda ve pil tasarrufu modlarında güvenilir çalışması (özellikle Xiaomi, Huawei ve Samsung'da Android arka plan kısıtlamaları)
- [ ] Kapalı beta: TestFlight ve Play Internal üzerinden 20–50 kullanıcı, 2–3 hafta

### Faz 5: Yayın (1–2 hafta)
- [ ] Mağaza materyalleri: ikon, ekran görüntüleri, açıklama (TR ve EN), tanıtım videosu
- [ ] Gizlilik politikası ve kullanım koşullarının web'de yayınlanması
- [ ] App Store gizlilik etiketleri ve Google Play Veri Güvenliği formu
- [ ] Sağlık uygulaması beyanları ve tıbbi uyarı metni
- [ ] Basit bir tanıtım sitesi (landing page)
- [ ] Kademeli yayın (Android'de %10 → %50 → %100)
- [ ] İzleme panosu: çökme oranı, aktif kullanıcı, tutunma (retention)

### Faz 6: Yayın Sonrası ve Yol Haritası (sürekli)

**v1.1: Kısa vade**
- [ ] Bakım veren hesabı (birden fazla hasta profili ve davetle bağlanma)
- [ ] Apple HealthKit ve Google Health Connect entegrasyonu (uyku, adım, kalp atış hızı)
- [ ] Ana ekran widget'ı ve Apple Watch / Wear OS üzerinden hızlı kayıt
- [ ] Ek hastalık modülleri (MS, Parkinson, migren veya epilepsi; hangisi MVP'de yoksa)

**v2: Orta vade**
- [ ] **Hekim paneli (web):** hastanın izin verdiği verileri görüntüleme, muayene öncesi özet
- [ ] Nöbet anında acil durum kişisine konumla birlikte SMS veya bildirim gönderme
- [ ] Hava durumu ve basınç verisinin otomatik eklenmesi (migren tetikleyicileri için)
- [ ] Tetikleyici korelasyon analizi (istatistiksel; teşhis amaçlı değil)

**v3: Uzun vade**
- [ ] Giyilebilir cihazlarla nöbet algılama (bu özellik tıbbi cihaz düzenlemesine girer; ayrı bir regülasyon süreci gerektirir)
- [ ] Hastane ve klinik entegrasyonları (HL7 FHIR)
- [ ] Araştırma modülü: anonimleştirilmiş veriyle klinik çalışmalara katılım (etik kurul onayıyla)

---

## 3. MVP Kapsamı: Özet

| Dahil ✅ | Hariç ❌ (sonraki sürümler) |
|---|---|
| Tek hastalık odağı | Çoklu hastalık modülleri |
| Hesap, profil, uygulama kilidi | Bakım veren / çoklu profil |
| Hızlı ve ayrıntılı olay kaydı | Giyilebilir cihazla otomatik algılama |
| İlaç hatırlatıcı ve uyum takibi | Hekim web paneli |
| Günlük check-in | HealthKit / Health Connect |
| Takvim ve temel grafikler | Yapay zekâ ile tahmin |
| PDF rapor, paylaşım, veri dışa aktarma | Acil durum SMS'i |
| Çevrimdışı çalışma, TR ve EN dil desteği | Uygulama içi mesajlaşma |

---

## 4. Veri Modeli (taslak)

```
users            (id, email, created_at, locale)
profiles         (user_id, diagnosis, birth_year, emergency_contact, ...)
consents         (user_id, type, version, granted_at, revoked_at)
events           (id, user_id, type, started_at, duration_sec, severity, notes)
event_triggers   (event_id, trigger_code)
event_symptoms   (event_id, symptom_code)
medications      (id, user_id, name, dose, unit, schedule_json, active)
medication_logs  (id, medication_id, scheduled_at, status[taken|skipped|snoozed], logged_at)
daily_checkins   (id, user_id, date, mood, sleep_hours, stress, note)
```
Tüm tablolarda Row Level Security uygulanır: kullanıcı yalnızca kendi verisini görür. Hassas notlar için alan düzeyinde şifreleme değerlendirilecek.

---

## 5. Riskler

| Risk | Etki | Önlem |
|---|---|---|
| Uygulamanın tıbbi cihaz sayılması | Yüksek | Teşhis veya öneri yok; hukuki görüş; açık uyarı metni |
| KVKK ihlali veya veri sızıntısı | Yüksek | Şifreleme, RLS, veriyi en aza indirme, Türkiye/AB'de barındırma, düzenli denetim |
| Bildirimlerin Android'de çalışmaması | Orta | Pil optimizasyonu rehberi, exact alarm izni, cihaz matrisi testleri |
| Düşük kullanıcı bağlılığı | Orta | 5 saniyede kayıt, widget, nazik hatırlatıcılar, anlamlı raporlar |
| Kapsamın büyümesi | Orta | Tek hastalık odağı, MVP tablosuna sıkı bağlılık |

---

## 6. Zaman Çizelgesi (yaklaşık)

```
Hafta:      1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
Faz 0       ██
Faz 1          ████
Faz 2             ███
Faz 3                ████████████████
Faz 4                            ██████
Faz 5                                     ███
```
**Toplam:** Küçük bir ekiple yaklaşık **14–16 hafta** (3,5–4 ay), tek geliştiriciyle **5–6 ay**.

---

## 7. Açık Sorular
- [ ] MVP hangi hastalığa odaklanacak?
- [ ] Ekip yapısı ve bütçe nedir?
- [ ] Gelir modeli ne olacak: ücretsiz, freemium (gelişmiş raporlar veya bakım veren özelliği ücretli) ya da kurumsal (klinik lisansı)?
- [ ] Bir hekim veya klinikle iş birliği yapılacak mı (danışman, pilot uygulama)?
- [ ] Teknoloji: Flutter mı, React Native mi?

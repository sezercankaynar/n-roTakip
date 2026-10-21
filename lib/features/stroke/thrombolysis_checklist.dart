import 'package:flutter/material.dart';

import '../../widgets/content_status.dart';

/// Trombolitik tedavi uygunluk ve dışlama kontrol listesi.
///
/// Karar vermez; işaretlenen maddelere göre hekime bildirilecek durumu
/// özetler. Seçimler kaydedilmez.
enum ChecklistGroup {
  inclusion('Uygunluk', 'Hepsi "evet" olmalı'),
  absolute('Dışlama ölçütleri', 'Biri bile varsa trombolitik önerilmez'),
  caution(
    'Dikkat gerektiren durumlar',
    'Hekim yarar/zarar değerlendirmesi yapar',
  );

  const ChecklistGroup(this.title, this.hint);

  final String title;
  final String hint;
}

class ChecklistItem {
  const ChecklistItem(this.group, this.text);

  final ChecklistGroup group;
  final String text;
}

const thrombolysisSources = [
  'Powers WJ, Rabinstein AA, Ackerson T, et al. Guidelines for the Early '
      'Management of Patients With Acute Ischemic Stroke: 2019 Update to the '
      '2018 Guidelines. Stroke. 2019;50(12):e344-e418. (Tablo 8)',
  'Berge E, Whiteley W, Audebert H, et al. European Stroke Organisation (ESO) '
      'guidelines on intravenous thrombolysis for acute ischaemic stroke. '
      'Eur Stroke J. 2021;6(1):I-LXII.',
];

const thrombolysisItems = <ChecklistItem>[
  ChecklistItem(
    ChecklistGroup.inclusion,
    'Akut iskemik inme düşündüren, ölçülebilir nörolojik defisit',
  ),
  ChecklistItem(ChecklistGroup.inclusion, 'Beyin BT\'de kanama yok'),
  ChecklistItem(
    ChecklistGroup.inclusion,
    'Son normal görülme zamanından itibaren 4,5 saat içinde (veya ileri görüntülemeyle seçilmiş hasta)',
  ),
  ChecklistItem(ChecklistGroup.inclusion, 'Yaş 18 ve üzeri'),
  ChecklistItem(
    ChecklistGroup.absolute,
    'BT\'de geniş, belirgin hipodens alan (yaygın erken infarkt)',
  ),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Belirtiler subaraknoid kanamayı düşündürüyor',
  ),
  ChecklistItem(ChecklistGroup.absolute, 'Daha önce geçirilmiş beyin kanaması'),
  ChecklistItem(ChecklistGroup.absolute, 'Son 3 ayda ciddi kafa travması'),
  ChecklistItem(ChecklistGroup.absolute, 'Son 3 ayda iskemik inme'),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Son 3 ayda beyin veya omurilik ameliyatı',
  ),
  ChecklistItem(ChecklistGroup.absolute, 'İntrakraniyal (intra-aksiyel) tümör'),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Son 21 günde gastrointestinal kanama veya GİS malignitesi',
  ),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Trombosit < 100.000/mm³, INR > 1,7, aPTT > 40 sn veya PT > 15 sn',
  ),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Son 24 saatte tedavi dozunda düşük molekül ağırlıklı heparin',
  ),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Son 48 saatte yeni nesil oral antikoagülan (DOAK) alımı (laboratuvar testleri normal değilse)',
  ),
  ChecklistItem(ChecklistGroup.absolute, 'Enfektif endokardit'),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Bilinen veya şüpheli aort arkı diseksiyonu',
  ),
  ChecklistItem(
    ChecklistGroup.absolute,
    'Tedaviyle düşürülemeyen kan basıncı > 185/110 mmHg',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Hafif ve sakatlık yaratmayan veya hızla düzelen belirtiler',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Kan şekeri < 50 veya > 400 mg/dL (düzeltildikten sonra yeniden değerlendirilir)',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Başlangıçta nöbet (belirtiler nöbet sonrası durumla açıklanabilir mi?)',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Son 14 günde büyük ameliyat veya ciddi travma',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Son 7 günde basılamayan bölgeye arter ponksiyonu',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Son 21 günde idrar yolu veya genital kanama',
  ),
  ChecklistItem(ChecklistGroup.caution, 'Son 3 ayda miyokard enfarktüsü'),
  ChecklistItem(
    ChecklistGroup.caution,
    'Gebelik veya doğum sonrası erken dönem',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Bilinen intrakraniyal anevrizma veya damar malformasyonu',
  ),
  ChecklistItem(
    ChecklistGroup.caution,
    'Aktif malignite, ağır karaciğer hastalığı',
  ),
];

enum ChecklistResult { incomplete, excluded, caution, noExclusion }

/// [checked]: işaretlenen maddelerin indeksleri ([thrombolysisItems] içinde).
ChecklistResult evaluateChecklist(Set<int> checked) {
  bool any(ChecklistGroup g) => [
    for (var i = 0; i < thrombolysisItems.length; i++)
      if (thrombolysisItems[i].group == g && checked.contains(i)) i,
  ].isNotEmpty;
  final allInclusion = [
    for (var i = 0; i < thrombolysisItems.length; i++)
      if (thrombolysisItems[i].group == ChecklistGroup.inclusion) i,
  ].every(checked.contains);

  if (any(ChecklistGroup.absolute)) return ChecklistResult.excluded;
  if (!allInclusion) return ChecklistResult.incomplete;
  if (any(ChecklistGroup.caution)) return ChecklistResult.caution;
  return ChecklistResult.noExclusion;
}

class ThrombolysisChecklistScreen extends StatefulWidget {
  const ThrombolysisChecklistScreen({super.key});

  @override
  State<ThrombolysisChecklistScreen> createState() =>
      _ThrombolysisChecklistScreenState();
}

class _ThrombolysisChecklistScreenState
    extends State<ThrombolysisChecklistScreen> {
  final _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = evaluateChecklist(_checked);
    final (Color color, IconData icon, String text) = switch (result) {
      ChecklistResult.excluded => (
        Colors.red.shade700,
        Icons.block,
        'Dışlama ölçütü işaretlendi. Hemen hekime bildirin.',
      ),
      ChecklistResult.incomplete => (
        Colors.grey.shade600,
        Icons.pending_outlined,
        'Uygunluk maddelerinin hepsi henüz işaretlenmedi.',
      ),
      ChecklistResult.caution => (
        Colors.orange.shade800,
        Icons.warning_amber,
        'Dikkat gerektiren durum var. Hekimin yarar/zarar değerlendirmesi '
            'gerekir.',
      ),
      ChecklistResult.noExclusion => (
        Colors.green.shade700,
        Icons.check_circle_outline,
        'İşaretli dışlama ölçütü yok. Tedavi kararı hekimindir.',
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trombolitik Kontrol Listesi'),
        actions: [
          IconButton(
            tooltip: 'Temizle',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(_checked.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: color,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final group in ChecklistGroup.values) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(group.title, style: theme.textTheme.titleLarge),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                    child: Text(group.hint, style: theme.textTheme.bodySmall),
                  ),
                  for (var i = 0; i < thrombolysisItems.length; i++)
                    if (thrombolysisItems[i].group == group)
                      CheckboxListTile(
                        value: _checked.contains(i),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(thrombolysisItems[i].text),
                        onChanged: (v) => setState(
                          () =>
                              v == true ? _checked.add(i) : _checked.remove(i),
                        ),
                      ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Liste kılavuzlardaki başlıca ölçütleri içerir; tam '
                    'değildir. Seçimler kaydedilmez. Kurum protokolü ve '
                    'hekim kararı esastır.',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SourcesCard(
                    status: ReviewStatus.draft,
                    sources: thrombolysisSources,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../content/markdown_view.dart';
import '../drugs/drug_guide_screen.dart' show normalizeForSearch;
import 'unit_protocol.dart';

IconData kindIcon(ProtocolKind k) => switch (k) {
  ProtocolKind.flow => Icons.account_tree,
  ProtocolKind.drugPrep => Icons.science,
  ProtocolKind.regimen => Icons.calendar_month,
  ProtocolKind.checklist => Icons.checklist,
  ProtocolKind.note => Icons.sticky_note_2,
};

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Okuma görünümü için hazırlar: onay kutularını simgeye çevirir, şablondan
/// kalan boş madde satırlarını gizler.
String renderChecklist(String body) => body
    .replaceAll(
      RegExp(r'^\s*(-|\d+\.)( \[[ xX]\])?\s*$\n?', multiLine: true),
      '',
    )
    .replaceAllMapped(
      RegExp(r'^(\s*)- \[ \]', multiLine: true),
      (m) => '${m[1]}- ☐',
    )
    .replaceAllMapped(
      RegExp(r'^(\s*)- \[[xX]\]', multiLine: true),
      (m) => '${m[1]}- ☑',
    );

class _PrivacyBanner extends StatelessWidget {
  const _PrivacyBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hasta adı, kimlik numarası, dosya numarası veya telefon '
              'yazmayın. Notlar yalnızca bu telefonda saklanır; siz '
              'paylaşmadıkça hiçbir yere gönderilmez.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ünite protokolleri: kullanıcının kendi notları ve talimatları.
class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key, this.store});

  final UnitProtocolStore? store;

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> {
  late final UnitProtocolStore _store = widget.store ?? UnitProtocolStore();
  List<UnitProtocol>? _items;
  String _query = '';
  ProtocolKind? _kind;

  @override
  void initState() {
    super.initState();
    _store.load().then((v) {
      if (mounted) setState(() => _items = v);
    });
  }

  Future<void> _save(List<UnitProtocol> items) async {
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    setState(() => _items = items);
    await _store.save(items);
  }

  Future<void> _upsert(UnitProtocol p) async {
    final items = [...?_items]..removeWhere((e) => e.id == p.id);
    await _save(items..add(p));
  }

  Future<void> _delete(UnitProtocol p) =>
      _save([...?_items]..removeWhere((e) => e.id == p.id));

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _create() async {
    final template = await showModalBottomSheet<(String, ProtocolKind, String)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Neyle başlayalım?'),
            ),
            for (final t in protocolTemplates)
              ListTile(
                leading: Icon(kindIcon(t.$2)),
                title: Text(t.$1),
                onTap: () => Navigator.pop(ctx, t),
              ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('Paylaşılan protokolü yapıştır'),
              onTap: () =>
                  Navigator.pop(ctx, ('', ProtocolKind.note, '\u0000')),
            ),
          ],
        ),
      ),
    );
    if (template == null || !mounted) return;
    if (template.$3 == '\u0000') return _import();
    final draft = UnitProtocol(
      id: _newId(),
      title: '',
      kind: template.$2,
      body: template.$3,
      updatedAt: DateTime.now(),
    );
    final saved = await Navigator.of(context).push<UnitProtocol>(
      MaterialPageRoute(builder: (_) => ProtocolEditor(initial: draft)),
    );
    if (saved != null) await _upsert(saved);
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final controller = TextEditingController(text: clip?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Protokol içe aktar'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Arkadaşınızın gönderdiği metni buraya yapıştırın',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Devam'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final draft = UnitProtocol.parseShared(text, id: _newId());
    final saved = await Navigator.of(context).push<UnitProtocol>(
      MaterialPageRoute(builder: (_) => ProtocolEditor(initial: draft)),
    );
    if (saved != null) await _upsert(saved);
  }

  Future<void> _open(UnitProtocol p) async {
    final result = await Navigator.of(context).push<_DetailResult>(
      MaterialPageRoute(builder: (_) => ProtocolDetailScreen(protocol: p)),
    );
    switch (result) {
      case _Updated(:final protocol):
        await _upsert(protocol);
      case _Deleted():
        await _delete(p);
      case null:
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final q = normalizeForSearch(_query);
    final shown = [
      for (final p in items ?? const <UnitProtocol>[])
        if ((_kind == null || p.kind == _kind) &&
            (q.isEmpty ||
                normalizeForSearch('${p.title} ${p.body}').contains(q)))
          p,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Ünite Protokollerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Yeni'),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const _PrivacyBanner(),
                if (items.isEmpty)
                  const _EmptyState()
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Protokollerde ara',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('Tümü (${items.length})'),
                          selected: _kind == null,
                          onSelected: (_) => setState(() => _kind = null),
                        ),
                        for (final k in ProtocolKind.values)
                          if (items.any((p) => p.kind == k))
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(k.label),
                                selected: _kind == k,
                                onSelected: (_) => setState(() => _kind = k),
                              ),
                            ),
                      ],
                    ),
                  ),
                  for (final p in shown)
                    ListTile(
                      leading: Icon(kindIcon(p.kind)),
                      title: Text(p.title),
                      subtitle: Text('${p.kind.label} · ${_date(p.updatedAt)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _open(p),
                    ),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Eşleşen protokol yok')),
                    ),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('Henüz protokol yok', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Ünitenizin akış şemalarını, eczanenizin ilaç hazırlama '
            'talimatlarını, tedavi şemalarını ve kontrol listelerini buraya '
            'yazın. "Yeni" düğmesiyle hazır şablondan başlayabilir veya '
            'arkadaşınızın paylaştığı protokolü yapıştırabilirsiniz.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Protokolü liste ekranı dışından (arama, favoriler) açar; düzenleme
/// veya silme sonucunu kaydeder.
Future<void> openProtocol(
  BuildContext context,
  UnitProtocol p, {
  UnitProtocolStore? store,
}) async {
  final result = await Navigator.of(context).push<_DetailResult>(
    MaterialPageRoute(builder: (_) => ProtocolDetailScreen(protocol: p)),
  );
  if (result == null) return;
  final s = store ?? UnitProtocolStore();
  final items = await s.load()
    ..removeWhere((e) => e.id == p.id);
  if (result case _Updated(:final protocol)) items.add(protocol);
  items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  await s.save(items);
}

sealed class _DetailResult {}

class _Updated extends _DetailResult {
  _Updated(this.protocol);
  final UnitProtocol protocol;
}

class _Deleted extends _DetailResult {}

/// Protokolün okunur hali; düzenleme, paylaşma ve silme.
class ProtocolDetailScreen extends StatefulWidget {
  const ProtocolDetailScreen({super.key, required this.protocol});

  final UnitProtocol protocol;

  @override
  State<ProtocolDetailScreen> createState() => _ProtocolDetailScreenState();
}

class _ProtocolDetailScreenState extends State<ProtocolDetailScreen> {
  late UnitProtocol _p = widget.protocol;
  bool _changed = false;

  void _close([_DetailResult? r]) =>
      Navigator.of(context).pop(r ?? (_changed ? _Updated(_p) : null));

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<UnitProtocol>(
      MaterialPageRoute(builder: (_) => ProtocolEditor(initial: _p)),
    );
    if (saved != null) {
      setState(() {
        _p = saved;
        _changed = true;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('"${_p.title}" kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _close(_Deleted());
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _p.toShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kopyalandı; mesaja yapıştırabilirsiniz')),
    );
  }

  Future<void> _share() => SharePlus.instance.share(
    ShareParams(text: _p.toShareText(), subject: _p.title),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_p.title),
          actions: [
            IconButton(
              tooltip: 'Düzenle',
              icon: const Icon(Icons.edit),
              onPressed: _edit,
            ),
            PopupMenuButton<String>(
              onSelected: (v) => switch (v) {
                'share' => _share(),
                'copy' => _copy(),
                _ => _confirmDelete(),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'share', child: Text('Paylaş')),
                PopupMenuItem(value: 'copy', child: Text('Metni kopyala')),
                PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Row(
              children: [
                Icon(kindIcon(_p.kind), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_p.kind.label} · son düzenleme ${_date(_p.updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_p.body.trim().isEmpty)
              const Text('Bu protokol henüz boş. Düzenle düğmesine dokunun.')
            else
              MarkdownView(renderChecklist(_p.body)),
            const SizedBox(height: 24),
            Text(
              'Bu sayfa sizin veya ekibinizin yazdığı bir nottur; NöroCep '
              'tarafından kontrol edilmemiştir.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Protokol yazma ve düzenleme ekranı. Kaydedilince protokolü döndürür.
class ProtocolEditor extends StatefulWidget {
  const ProtocolEditor({super.key, required this.initial});

  final UnitProtocol initial;

  @override
  State<ProtocolEditor> createState() => _ProtocolEditorState();
}

class _ProtocolEditorState extends State<ProtocolEditor> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _body = TextEditingController(text: widget.initial.body);
  late ProtocolKind _kind = widget.initial.kind;
  bool _preview = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _title.text != widget.initial.title ||
      _body.text != widget.initial.body ||
      _kind != widget.initial.kind;

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık yazın')));
      return;
    }
    final warnings = personalDataWarnings('$title\n${_body.text}');
    if (warnings.isNotEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.privacy_tip),
          title: const Text('Kişisel veri olabilir'),
          content: Text(
            'Metinde şunlar bulundu:\n• ${warnings.join('\n• ')}\n\n'
            'Hasta bilgisi kaydetmeyin. Yine de kaydedilsin mi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Düzelt'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hasta bilgisi değil, kaydet'),
            ),
          ],
        ),
      );
      if (go != true) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      widget.initial.copyWith(
        title: title,
        kind: _kind,
        body: _body.text.trimRight(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Değişiklikler kaydedilmedi'),
        content: const Text('Çıkarsanız yazdıklarınız kaybolacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Yazmaya devam'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _insert(String prefix) {
    final sel = _body.selection;
    final text = _body.text;
    final at = sel.isValid ? sel.start : text.length;
    final lineStart = at == 0 ? 0 : text.lastIndexOf('\n', at - 1) + 1;
    final needsBreak = at > lineStart;
    final insert = needsBreak ? '\n$prefix' : prefix;
    _body.value = TextEditingValue(
      text: text.replaceRange(at, at, insert),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_dirty || await _confirmDiscard()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.initial.title.isEmpty ? 'Yeni protokol' : 'Düzenle',
          ),
          actions: [
            IconButton(
              tooltip: _preview ? 'Yazmaya dön' : 'Önizleme',
              icon: Icon(_preview ? Icons.edit : Icons.visibility),
              onPressed: () => setState(() => _preview = !_preview),
            ),
            TextButton(onPressed: _save, child: const Text('Kaydet')),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            const _PrivacyBanner(),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'ör. Ünitemizde status epileptikus akışı',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProtocolKind>(
              initialValue: _kind,
              decoration: const InputDecoration(
                labelText: 'Tür',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final k in ProtocolKind.values)
                  DropdownMenuItem(value: k, child: Text(k.label)),
              ],
              onChanged: (k) => setState(() => _kind = k ?? _kind),
            ),
            const SizedBox(height: 12),
            if (_preview)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _body.text.trim().isEmpty
                      ? const Text('Önizlenecek metin yok')
                      : MarkdownView(renderChecklist(_body.text)),
                ),
              )
            else ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (label, prefix) in const [
                    ('Başlık', '## '),
                    ('Madde', '- '),
                    ('Adım', '1. '),
                    ('Kutu', '- [ ] '),
                    ('Uyarı', '> '),
                  ])
                    ActionChip(
                      label: Text(label),
                      onPressed: () => _insert(prefix),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _body,
                minLines: 12,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Metin',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'İpucu: satır başına "## " başlık, "- " madde, "1. " adım, '
                '"> " uyarı kutusu yapar. **iki yıldız** arası kalın yazılır.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../content/content_screen.dart';
import 'emergency_codes.dart';

/// Hastaneye özel acil kod listesi: ad, dahili numara, açıklama.
class EmergencyCodesScreen extends StatefulWidget {
  const EmergencyCodesScreen({super.key, this.store});

  final EmergencyCodeStore? store;

  @override
  State<EmergencyCodesScreen> createState() => _EmergencyCodesScreenState();
}

class _EmergencyCodesScreenState extends State<EmergencyCodesScreen> {
  late final EmergencyCodeStore _store = widget.store ?? EmergencyCodeStore();
  List<EmergencyCode>? _codes;

  static const _palette = [
    0xFF1565C0,
    0xFFD81B60,
    0xFF757575,
    0xFFC62828,
    0xFFEF6C00,
    0xFFF9A825,
    0xFF2E7D32,
    0xFF6A1B9A,
    0xFF000000,
  ];

  @override
  void initState() {
    super.initState();
    _store.load().then((c) {
      if (mounted) setState(() => _codes = c);
    });
  }

  Future<void> _edit({int? index}) async {
    final existing = index == null ? null : _codes![index];
    final result = await showDialog<EmergencyCode>(
      context: context,
      builder: (_) => _CodeDialog(
        initial: existing,
        defaultColor: _palette[_codes!.length % _palette.length],
      ),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _codes!.add(result);
      } else {
        _codes![index] = result;
      }
    });
    await _store.save(_codes!);
  }

  Future<void> _delete(int index) async {
    setState(() => _codes!.removeAt(index));
    await _store.save(_codes!);
  }

  Future<void> _reset() async {
    setState(() => _codes = [...defaultEmergencyCodes]);
    await _store.save(_codes!);
  }

  @override
  Widget build(BuildContext context) {
    final codes = _codes;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acil Kodlarım'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'reset' ? _reset() : null,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reset', child: Text('Varsayılanlara dön')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: codes == null ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Kod ekle'),
      ),
      body: codes == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                const Text(
                  'Kendi hastanenizin kodlarını ve dahili numaralarını girin. '
                  'Bilgiler yalnızca bu telefonda saklanır.',
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < codes.length; i++)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(codes[i].colorValue),
                        child: const Icon(Icons.campaign, color: Colors.white),
                      ),
                      title: Text(codes[i].name),
                      subtitle: Text(
                        [
                          codes[i].extension.isEmpty
                              ? 'Dahili: girilmedi'
                              : 'Dahili: ${codes[i].extension}',
                          if (codes[i].description.isNotEmpty)
                            codes[i].description,
                        ].join('\n'),
                      ),
                      isThreeLine: codes[i].description.isNotEmpty,
                      trailing: IconButton(
                        tooltip: 'Sil',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(i),
                      ),
                      onTap: () => _edit(index: i),
                    ),
                  ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Acil durum kodları hakkında'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ContentScreen(
                        asset: 'assets/content/hemsirelik/acil-kodlar.md',
                        title: 'Acil Durum Kodları',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({this.initial, required this.defaultColor});

  final EmergencyCode? initial;
  final int defaultColor;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _ext = TextEditingController(
    text: widget.initial?.extension ?? '',
  );
  late final _desc = TextEditingController(
    text: widget.initial?.description ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _ext.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Yeni kod' : 'Kodu düzenle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Kod adı'),
            ),
            TextField(
              controller: _ext,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Dahili numara'),
            ),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Ne zaman verilir?'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              EmergencyCode(
                name: _name.text.trim(),
                colorValue: widget.initial?.colorValue ?? widget.defaultColor,
                extension: _ext.text.trim(),
                description: _desc.text.trim(),
              ),
            );
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

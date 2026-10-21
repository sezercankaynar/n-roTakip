import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norocep/features/stroke/thrombolysis_checklist.dart';

Set<int> indexes(ChecklistGroup g) => {
  for (var i = 0; i < thrombolysisItems.length; i++)
    if (thrombolysisItems[i].group == g) i,
};

void main() {
  final inclusion = indexes(ChecklistGroup.inclusion);
  final absolute = indexes(ChecklistGroup.absolute);
  final caution = indexes(ChecklistGroup.caution);

  test('boş liste eksik sayılır', () {
    expect(evaluateChecklist({}), ChecklistResult.incomplete);
  });

  test('uygunluk tam, dışlama yok', () {
    expect(evaluateChecklist(inclusion), ChecklistResult.noExclusion);
  });

  test('dışlama ölçütü her zaman öncelikli', () {
    expect(evaluateChecklist({absolute.first}), ChecklistResult.excluded);
    expect(
      evaluateChecklist({...inclusion, absolute.last, caution.first}),
      ChecklistResult.excluded,
    );
  });

  test('dikkat gerektiren durum', () {
    expect(
      evaluateChecklist({...inclusion, caution.first}),
      ChecklistResult.caution,
    );
  });

  testWidgets('ekranda dışlama uyarısı görünür', (tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: ThrombolysisChecklistScreen()),
    );
    expect(find.textContaining('henüz işaretlenmedi'), findsOneWidget);
    final item = find.text(thrombolysisItems[absolute.first].text);
    await tester.scrollUntilVisible(item, 200);
    await tester.tap(item);
    await tester.pump();
    expect(find.textContaining('Dışlama ölçütü işaretlendi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

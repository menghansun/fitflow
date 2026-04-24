import 'package:fitflow/services/swim_ocr_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps normal Chinese OCR labels into parser dialect', () {
    const raw = '\u534e\u4e3a\u8fd0\u52a8\u5065\u5eb7\n'
        '\u6d3b\u52a8\u70ed\u91cf 286 \u5343\u5361\n'
        '\u5e73\u5747\u5fc3\u7387 144\n'
        '\u5212\u6c34\u6b21\u6570 414';

    final normalized = normalizeSwimOcrText(raw);

    expect(
      normalized,
      contains('\u9357\u5e9d\u8d1f\u6769\u612c\u59e9\u934b\u30e5\u608d'),
    );
    expect(normalized, contains('\u5a32\u8bf2\u59e9\u9411\ue162\u567a 286 \u9357\u51a8\u5d31'));
    expect(normalized, contains('\u9a9e\u51b2\u6f4e\u8e47\u51aa\u5dfc 144'));
    expect(normalized, contains('\u9352\u6393\u6309\u5a06\u2103\u669f 414'));
  });

  test('normalizes common kcal OCR typos', () {
    const raw = '\u5c0f\u7c73\u8fd0\u52a8\u5065\u5eb7\n'
        '\u8fd0\u52a8\u65f6\u957f 00:33:55 286kca1';

    final normalized = normalizeSwimOcrText(raw);

    expect(
      normalized,
      contains('\u704f\u5fd5\u80cc\u6769\u612c\u59e9\u934b\u30e5\u608d'),
    );
    expect(normalized, contains('286kcal'));
  });
}

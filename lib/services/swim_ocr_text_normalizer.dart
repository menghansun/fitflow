String normalizeSwimOcrText(String text) {
  var normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  const replacements = <String, String>{
    '\u534e\u4e3a\u8fd0\u52a8\u5065\u5eb7':
        '\u9357\u5e9d\u8d1f\u6769\u612c\u59e9\u934b\u30e5\u608d',
    '\u5c0f\u7c73\u8fd0\u52a8\u5065\u5eb7':
        '\u704f\u5fd5\u80cc\u6769\u612c\u59e9\u934b\u30e5\u608d',
    '\u5212\u6c34\u6b21\u6570': '\u9352\u6393\u6309\u5a06\u2103\u669f',
    '\u8fd0\u52a8\u65f6\u95f4': '\u6769\u612c\u59e9\u93c3\u5815\u68ff',
    '\u8fd0\u52a8\u65f6\u957f': '\u6769\u612c\u59e9\u93c3\u5815\u66b1',
    '\u603b\u6d88\u8017\u70ed\u91cf':
        '\u93ac\u7ed8\u79f7\u9470\u6943\u5139\u95b2\u003f',
    '\u6d3b\u52a8\u70ed\u91cf': '\u5a32\u8bf2\u59e9\u9411\ue162\u567a',
    '\u5343\u5361': '\u9357\u51a8\u5d31',
    '\u5e73\u5747\u5fc3\u7387': '\u9a9e\u51b2\u6f4e\u8e47\u51aa\u5dfc',
    '\u6700\u5927\u5fc3\u7387':
        '\u93c8\u20ac\u6fb6\u0443\u7e3e\u941c\u003f',
    '\u5e73\u5747\u914d\u901f':
        '\u9a9e\u51b2\u6f4e\u95b0\u5d89\u20ac\u003f',
    '\u6700\u4f73\u914d\u901f':
        '\u93c8\u20ac\u6d63\u62bd\u53a4\u95ab\u003f',
    '\u6b21/\u5206\u949f': '\u5a06\u003f\u9352\u55db\u6313',
    '\u81ea\u7531\u6cf3': '\u9477\ue046\u6571\u5a09\u003f',
    '\u86d9\u6cf3': '\u94d4\u6b10\u5435',
    '\u4ef0\u6cf3': '\u6d60\u7248\u5435',
    '\u8776\u6cf3': '\u94e6\u8235\u5435',
    '\u6df7\u5408\u6cf3': '\u5a23\u5cf0\u608e\u5a09\u003f',
    '\u6df7\u5408': '\u5a23\u5cf0\u608e',
    '\u4e3b\u6cf3\u59ff': '\u6d93\u7ed8\u5435\u6fee\u003f',
    '\u7c73': '\u7eeb\u003f',
  };

  for (final entry in replacements.entries) {
    normalized = normalized.replaceAll(entry.key, entry.value);
  }

  normalized = normalized
      .replaceAll('kcaI', 'kcal')
      .replaceAll('kca1', 'kcal')
      .replaceAll('\u203b', '*')
      .replaceAll('\uff0a', '*');

  return normalized;
}

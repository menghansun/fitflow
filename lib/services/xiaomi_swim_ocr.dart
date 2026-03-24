// Xiaomi Health swim screenshot parsing only — no Huawei logic.

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'swim_ocr_types.dart';

/// Entry point for Xiaomi OCR (text-only or ML Kit blocks + text).
class XiaomiSwimOcrParser {
  XiaomiSwimOcrParser._();

  static SwimOcrResult parse(String text) => _XiaomiTextParser.parse(text);

  static SwimOcrResult parseWithBlocks(
    List<TextBlock> blocks,
    String rawText,
  ) =>
      _XiaomiPositionalParser.parse(blocks, rawText);
}

int _hmsToMinutes(String h, String m, String s) {
  final hours = int.tryParse(h) ?? 0;
  final mins = int.tryParse(m) ?? 0;
  final total = hours * 60 + mins;
  return total == 0 ? 1 : total;
}

DateTime? _xiaomiParseWorkoutDateTime(String text) {
  final reg = RegExp(r'(\d{4})/(\d{1,2})/(\d{1,2})\s*(\d{1,2}):(\d{2})');
  final m = reg.firstMatch(text);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

int? _xiaomiParseDistance(String text) {
  // Device OCR: "1000." "500*" "1025%" "1050" right under 小米运动健康.
  final afterBrand = RegExp(
    r'小米运动健康\s*\n\s*(\d{3,4})[.\*%※＊]?\s*(?:\n|$)',
    multiLine: true,
  ).firstMatch(text);
  if (afterBrand != null) {
    final val = int.tryParse(afterBrand.group(1)!);
    if (val != null && val >= 100 && val <= 5000) return val;
  }

  final xiaomiMatch =
      RegExp(r'小米运动健康[^\n]*\n\s*(\d+)\s*(?:\n|米)').firstMatch(text);
  if (xiaomiMatch != null) {
    final val = int.tryParse(xiaomiMatch.group(1) ?? '');
    if (val != null && val >= 25 && val <= 10000) return val;
  }

  final headLen = text.length > 900 ? 900 : text.length;
  final head = text.substring(0, headLen);
  for (final m in RegExp(r'^\s*(\d{3,4})\s*米\s*$', multiLine: true)
      .allMatches(head)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val >= 100 && val <= 5000) return val;
  }

  int? fromCommaM;
  for (final m in RegExp(r'(\d{2,4})\s*米[，,]').allMatches(text)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val >= 100 && val <= 5000) {
      if (fromCommaM == null || val > fromCommaM) fromCommaM = val;
    }
  }
  if (fromCommaM != null) return fromCommaM;

  // Header-only standalone (avoid tail garbage like 3000 / 520).
  final head320 = text.length > 320 ? text.substring(0, 320) : text;
  int? headMax;
  for (final m in RegExp(r'^\s*(\d{3,4})[.。]?\s*$', multiLine: true)
      .allMatches(head320)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val >= 100 && val <= 3000) {
      if (headMax == null || val > headMax) headMax = val;
    }
  }
  if (headMax != null) return headMax;

  int? best;
  for (final m in RegExp(r'(\d+)\s*米').allMatches(text)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val >= 25 && val <= 10000) {
      if (best == null || val > best) best = val;
    }
  }
  return best;
}

bool _xiaomiHmsNonZero(String h, String m, String s) {
  final ih = int.tryParse(h) ?? 0;
  final im = int.tryParse(m) ?? 0;
  final iSec = int.tryParse(s) ?? 0;
  return ih + im + iSec > 0;
}

int? _xiaomiParseDurationMinutes(String text) {
  // Row: "00:33:55 286kcal" (wall clock + activity kcal).
  final rowKcal = RegExp(
    r'\b(\d{1,2}):(\d{2}):(\d{2})\s+\d{2,4}\s*kca',
    caseSensitive: false,
  ).firstMatch(text);
  if (rowKcal != null &&
      _xiaomiHmsNonZero(
        rowKcal.group(1)!,
        rowKcal.group(2)!,
        rowKcal.group(3)!,
      )) {
    return _hmsToMinutes(
      rowKcal.group(1)!,
      rowKcal.group(2)!,
      rowKcal.group(3)!,
    );
  }

  final dur = RegExp(
    r'运动时长[^\d]{0,120}?(\d{1,2}):(\d{2}):(\d{2})',
    dotAll: true,
  ).firstMatch(text);
  if (dur != null &&
      _xiaomiHmsNonZero(dur.group(1)!, dur.group(2)!, dur.group(3)!)) {
    return _hmsToMinutes(dur.group(1)!, dur.group(2)!, dur.group(3)!);
  }

  // First non-zero H:M:S in the summary header (skip 00:00:00 lap placeholders).
  final headEnd = text.length > 620 ? 620 : text.length;
  final head = text.substring(0, headEnd);
  for (final m in RegExp(r'\b(\d{1,2}):(\d{2}):(\d{2})\b').allMatches(head)) {
    if (!_xiaomiHmsNonZero(m.group(1)!, m.group(2)!, m.group(3)!)) continue;
    final totalSec = (int.parse(m.group(1)!)) * 3600 +
        (int.parse(m.group(2)!)) * 60 +
        int.parse(m.group(3)!);
    if (totalSec < 120) continue;
    if (totalSec > 21600) continue;
    return _hmsToMinutes(m.group(1)!, m.group(2)!, m.group(3)!);
  }

  for (final m in RegExp(r'\b(\d{1,2}):(\d{2}):(\d{2})\b').allMatches(text)) {
    if (!_xiaomiHmsNonZero(m.group(1)!, m.group(2)!, m.group(3)!)) continue;
    final totalSec = (int.parse(m.group(1)!)) * 3600 +
        (int.parse(m.group(2)!)) * 60 +
        int.parse(m.group(3)!);
    if (totalSec < 120) continue;
    return _hmsToMinutes(m.group(1)!, m.group(2)!, m.group(3)!);
  }
  return null;
}

String? _xiaomiParseDurationRaw(String text) {
  final rowKcal = RegExp(
    r'\b(\d{1,2}:\d{2}:\d{2})\s+\d{2,4}\s*kca',
    caseSensitive: false,
  ).firstMatch(text);
  if (rowKcal != null) return rowKcal.group(1);
  final dur = RegExp(
    r'运动时长[^\d]{0,120}?(\d{1,2}:\d{2}:\d{2})',
    dotAll: true,
  ).firstMatch(text);
  if (dur != null && dur.group(1) != '00:00:00') return dur.group(1);
  final headEnd = text.length > 620 ? 620 : text.length;
  final head = text.substring(0, headEnd);
  for (final m in RegExp(r'\b(\d{1,2}:\d{2}:\d{2})\b').allMatches(head)) {
    if (m.group(1) == '00:00:00') continue;
    return m.group(1);
  }
  return RegExp(r'(\d{1,2}:\d{2}:\d{2})').firstMatch(text)?.group(0);
}

int? _xiaomiParseCalories(String text) {
  final totalM = RegExp(
    r'总(?:消耗)?卡(?:路里)?[^\d]{0,50}(\d{2,4})\s*(?:千卡|kcal)',
    caseSensitive: false,
  ).firstMatch(text);
  if (totalM != null) {
    final v = int.tryParse(totalM.group(1)!);
    if (v != null && v >= 50 && v <= 3000) return v;
  }
  final headLen = text.length > 1000 ? 1000 : text.length;
  final head = text.substring(0, headLen);
  int? best;
  for (final m in RegExp(r'(\d{2,4})\s*(千卡|kcal)', caseSensitive: false)
      .allMatches(head)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val == null || val < 50 || val > 3000) continue;
    if (best == null || val > best) best = val;
  }
  // "312kc" without "al" on device OCR.
  for (final m
      in RegExp(r'(\d{2,4})\s*kc(?:al)?', caseSensitive: false).allMatches(head)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val == null || val < 50 || val > 3000) continue;
    if (best == null || val > best) best = val;
  }
  if (best != null) return best;
  final reg = RegExp(r'(\d+)\s*(千卡|kcal|Cal)', caseSensitive: false);
  for (final m in reg.allMatches(text)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val >= 50 && val <= 3000) return val;
  }
  return null;
}

String? _xiaomiParseSwimStyle(String text) {
  final known = RegExp(r'(蛙泳|自由泳|仰泳|蝶泳|混合泳|混合)');
  final m = known.firstMatch(text);
  if (m != null) {
    final raw = m.group(1)!;
    return raw == '混合' ? '混合泳' : raw;
  }
  if (RegExp(r'[參参]\S*泳').hasMatch(text)) return '蛙泳';

  final pos = text.indexOf('主泳姿');
  if (pos >= 0) {
    final start = (pos - 300).clamp(0, text.length);
    final end = (pos + 300).clamp(0, text.length);
    final window = text.substring(start, end);
    for (final match in RegExp(r'(\S{1,4}泳)').allMatches(window)) {
      final val = match.group(1)!;
      if (val == '游泳') continue;
      if (val.endsWith('泳姿')) continue;
      if (val.contains('自由')) return '自由泳';
      if (val.contains('仰')) return '仰泳';
      if (val.contains('蝶')) return '蝶泳';
      if (val.contains('混')) return '混合泳';
      if (val.contains('蛙')) return '蛙泳';
      return '蛙泳';
    }
  }
  return null;
}

int? _xiaomiParseLaps(String text) {
  for (final m in RegExp(r'(\d{1,3})[^\S\n]*趟数').allMatches(text)) {
    final v = int.tryParse(m.group(1)!);
    if (v != null && v >= 1 && v <= 300) return v;
  }
  final afterLabel = RegExp(
    r'趟[数教數請逬通]*[^\d\n]{0,10}\n\s*(\d{1,3})\s',
    multiLine: true,
  ).firstMatch(text);
  if (afterLabel != null) {
    final v = int.tryParse(afterLabel.group(1)!);
    if (v != null && v >= 1 && v <= 200) return v;
  }
  return null;
}

/// When OCR garbles "趟数", a lone lap count often sits on the line after distance (e.g. 40 for 1000m/25m).
int? _xiaomiInferLapsFromHeaderLayout(String text, int? distanceMeters) {
  if (distanceMeters == null || distanceMeters < 100) return null;
  final lines = text.split('\n');
  var seenBrand = false;
  for (var i = 0; i < lines.length && i < 28; i++) {
    final line = lines[i];
    if (line.contains('小米运动健康')) {
      seenBrand = true;
      continue;
    }
    if (!seenBrand) continue;
    final m = RegExp(r'^\s*(\d{1,3})\s*$').firstMatch(line);
    if (m == null) continue;
    final v = int.tryParse(m.group(1)!);
    if (v == null || v < 4 || v > 160) continue;
    if (distanceMeters % 25 == 0 && distanceMeters ~/ 25 == v) return v;
    if (distanceMeters % 50 == 0 && distanceMeters ~/ 50 == v) return v;
  }
  return null;
}

int? _xiaomiInferPoolLength(int? parsed, int? distance, int? laps) {
  if (parsed != null) return parsed;
  if (distance == null || laps == null || laps <= 0) return null;
  final calc = distance ~/ laps;
  if (calc >= 15 &&
      calc <= 100 &&
      (calc * laps - distance).abs() <= laps) {
    return calc;
  }
  return null;
}

int? _xiaomiInferLaps(int? parsed, int? distance, int? pool) {
  if (parsed != null) return parsed;
  if (distance == null || pool == null || pool <= 0) return null;
  final calc = distance ~/ pool;
  if (calc >= 1 && (calc * pool - distance).abs() <= pool) return calc;
  return null;
}

int? _xiaomiParsePoolLength(String text) {
  final reg1 = RegExp(r'泳池[长度]*[^\d]*(\d+)\s*[米m]|(\d+)\s*[米m]\s*泳池');
  final m1 = reg1.firstMatch(text);
  if (m1 != null) {
    final v = int.tryParse(m1.group(1) ?? m1.group(2) ?? '');
    if (v != null && v >= 15 && v <= 100) return v;
  }
  final reg2 = RegExp(r'(?<!\d)(25|50)(?=\s*[米m])');
  final m2 = reg2.firstMatch(text);
  if (m2 != null) return int.tryParse(m2.group(1)!);
  return null;
}

/// Strip per-lap lines so pace/SWOLF heuristics do not grab segment values.
String _xiaomiTextWithoutLapRows(String text) {
  final buf = StringBuffer();
  for (final line in text.split('\n')) {
    if (RegExp(r'第\s*\d+\s*趟').hasMatch(line)) continue;
    if (RegExp(r'第\s*\d+\s*段').hasMatch(line)) continue;
    buf.writeln(line);
  }
  return buf.toString();
}

/// First M'SS" in the header (first ~900 chars) as seconds; used to gate garbled-inch best pace.
int? _xiaomiHeaderAvgPaceSeconds(String text) {
  final paceSeg = RegExp(
    r'(\d{1,2})[\x27\u2019\u2032](\d{2})[\x22\u201D\u2033]',
  );
  final headLen = text.length > 900 ? 900 : text.length;
  final m = paceSeg.firstMatch(text.substring(0, headLen));
  if (m == null) return null;
  final min = int.tryParse(m.group(1)!);
  final sec = int.tryParse(m.group(2)!);
  if (min == null || sec == null || min > 45) return null;
  return min * 60 + sec;
}

/// Footer: last total `NNN kcal` / `NNNkc` block, then first plausible M'SS" (not always adjacent).
String? _xiaomiParseBestPaceFromFooter(String text) {
  final sq = String.fromCharCode(0x27);
  final dq = String.fromCharCode(0x22);
  final paceSeg = RegExp(
    r'(\d{1,2})[\x27\u2019\u2032](\d{2})[\x22\u201D\u2033]',
  );

  bool plausiblePace(int min, int sec) {
    if (min < 1 || min > 10 || sec < 0 || sec > 59) return false;
    return true;
  }

  String? formatPace(RegExpMatch p) =>
      "${p.group(1)}$sq${p.group(2)}$dq";

  final kcRe = RegExp(r'(\d{2,4})\s*kc(?:al|a)?\b', caseSensitive: false);
  final kcMatches = kcRe.allMatches(text).toList();
  if (kcMatches.isNotEmpty) {
    final threshold = (text.length * 0.52).floor();
    RegExpMatch? pick;
    for (final cand in kcMatches.reversed) {
      if (cand.start >= threshold) {
        pick = cand;
        break;
      }
    }
    pick ??= kcMatches.last;
    final kcalVal = int.tryParse(pick.group(1)!);
    if (kcalVal != null && kcalVal >= 80 && kcalVal <= 4500) {
      final after = text.substring(
        pick.end,
        (pick.end + 520).clamp(0, text.length),
      );
      String? pickPace(String slice, {required bool preferLast}) {
        String? first;
        String? last;
        for (final p in paceSeg.allMatches(slice)) {
          final min = int.tryParse(p.group(1)!);
          final sec = int.tryParse(p.group(2)!);
          if (min != null && sec != null && plausiblePace(min, sec)) {
            first ??= formatPace(p);
            last = formatPace(p);
          }
        }
        return preferLast ? last : first;
      }

      String? paceSecondOnSameLine() {
        for (final line in after.split('\n')) {
          final ms = paceSeg.allMatches(line).toList();
          if (ms.length < 2) continue;
          final p = ms[1];
          final min = int.tryParse(p.group(1)!);
          final sec = int.tryParse(p.group(2)!);
          if (min != null && sec != null && plausiblePace(min, sec)) {
            return formatPace(p);
          }
        }
        return null;
      }

      // After total kcal: paired "avg+fast" on one line (synthetic ML Kit); else first pace.
      final fromAfter =
          paceSecondOnSameLine() ?? pickPace(after, preferLast: false);
      if (fromAfter != null) return fromAfter;
      final headAfter = text.substring(
        pick.end,
        (pick.end + 140).clamp(0, text.length),
      );
      final avgSec = _xiaomiHeaderAvgPaceSeconds(text);
      if (avgSec == null || avgSec >= 11 * 60) {
        for (final inchSoon in RegExp(
          r'^\s*[|｜]?\s*(\d)(\d{2})[\x22\u201D\u2033]\s*$',
          multiLine: true,
        ).allMatches(headAfter)) {
          final min = int.tryParse(inchSoon.group(1)!);
          final sec = int.tryParse(inchSoon.group(2)!);
          if (min != null && sec != null && plausiblePace(min, sec)) {
            return "$min$sq${sec.toString().padLeft(2, '0')}$dq";
          }
        }
      }
      final before = text.substring(
        (pick.start - 280).clamp(0, pick.start),
        pick.start,
      );
      final fromBeforeStd = pickPace(before, preferLast: true);
      if (fromBeforeStd != null) return fromBeforeStd;
      final beforeInchOnly = text.substring(
        (pick.start - 100).clamp(0, pick.start),
        pick.start,
      );
      RegExpMatch? inchPick;
      for (final m in RegExp(
        r'^\s*(\d)(\d{2})[\x22\u201D\u2033]\s*$',
        multiLine: true,
      ).allMatches(beforeInchOnly)) {
        inchPick = m;
      }
      if (inchPick != null) {
        final min = int.tryParse(inchPick.group(1)!);
        final sec = int.tryParse(inchPick.group(2)!);
        if (min != null && sec != null && plausiblePace(min, sec)) {
          return "$min$sq${sec.toString().padLeft(2, '0')}$dq";
        }
      }
    }
  }

  for (final lbl in ['最快配速', '最佳配速']) {
    var idx = text.lastIndexOf(lbl);
    if (idx < 0) continue;
    final slice = text.substring(idx, (idx + 240).clamp(0, text.length));
    for (final p in paceSeg.allMatches(slice)) {
      final min = int.tryParse(p.group(1)!);
      final sec = int.tryParse(p.group(2)!);
      if (min != null && sec != null && plausiblePace(min, sec)) {
        return formatPace(p);
      }
    }
  }
  return null;
}

({String? avg, String? best}) _xiaomiParsePacePair(String text) {
  final sq = String.fromCharCode(0x27);
  final dq = String.fromCharCode(0x22);
  final paceSeg = RegExp(
    r'(\d{1,2})[\x27\u2019\u2032](\d{2})[\x22\u201D\u2033]',
  );
  final swimIdx = text.indexOf('游泳配速');
  if (swimIdx >= 0) {
    final win =
        text.substring(swimIdx, (swimIdx + 200).clamp(0, text.length));
    final list = paceSeg.allMatches(win).toList();
    if (list.isNotEmpty) {
      final avg =
          "${list[0].group(1)}$sq${list[0].group(2)}$dq";
      String? best;
      if (list.length >= 2) {
        best = "${list[1].group(1)}$sq${list[1].group(2)}$dq";
      }
      return (avg: avg, best: best);
    }
  }
  final filtered = _xiaomiTextWithoutLapRows(text);
  final all = paceSeg.allMatches(filtered).toList();
  if (all.isEmpty) return (avg: null, best: null);
  final avg = "${all[0].group(1)}$sq${all[0].group(2)}$dq";
  String? best;
  if (all.length >= 2) {
    best = "${all[1].group(1)}$sq${all[1].group(2)}$dq";
  }
  return (avg: avg, best: best);
}

({int? avg, int? best}) _xiaomiParseSwolfSummary(String text) {
  int? parsedBest;

  final bestTail = RegExp(
    r'最佳\s*SWOLF\s*\n[^\n]*\n\s*(\d{2,3})\s',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(text);
  if (bestTail != null) {
    final b = int.tryParse(bestTail.group(1)!);
    if (b != null && b >= 10 && b <= 130) parsedBest = b;
  }

  final bestOneLine = RegExp(
    r'最佳\s*SWOL[FfI1]?\s*\n\s*(\d{2,3})\s',
    caseSensitive: false,
    multiLine: true,
  ).firstMatch(text);
  if (bestOneLine != null && parsedBest == null) {
    final b = int.tryParse(bestOneLine.group(1)!);
    if (b != null && b >= 10 && b <= 130) parsedBest = b;
  }

  int posLbl = text.lastIndexOf('最佳SWOLF');
  for (final alt in ['最佳SWOL', '最住SWOLF', '最佳SWOLi']) {
    final p = text.lastIndexOf(alt);
    if (p > posLbl) posLbl = p;
  }
  if (posLbl >= 0) {
    final after = text.substring(
      posLbl,
      (posLbl + 80).clamp(0, text.length),
    );
    final nextLine =
        RegExp(r'最佳\s*SWOL[FfI1]?\s*\n\s*([^\n]+)', caseSensitive: false)
            .firstMatch(after);
    final nextRaw = nextLine?.group(1)?.trim() ?? '';
    final nextNum = RegExp(r'^(\d{2,3})$').firstMatch(nextRaw);
    final nextTooBig =
        nextNum != null &&
        (int.tryParse(nextNum.group(1)!) ?? 0) > 130;
    final nextIsTime = RegExp(r'\d{1,2}:\d{2}').hasMatch(nextRaw);
    if (nextIsTime || nextTooBig || nextRaw.isEmpty) {
      final before = text.substring((posLbl - 220).clamp(0, posLbl), posLbl);
      final lines = before.split('\n');
      for (var i = lines.length - 1; i >= 0 && i >= lines.length - 12; i--) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        if (RegExp(r'\d{1,2}:\d{2}').hasMatch(line)) continue;
        final m = RegExp(r'^(\d{2,3})$').firstMatch(line);
        if (m == null) continue;
        final v = int.tryParse(m.group(1)!);
        if (v != null && v >= 25 && v <= 130) {
          parsedBest ??= v;
          break;
        }
      }
    }
  }

  final avgBeforeSwol = RegExp(
    r'(\d{2,3})\s*\n\s*平均\s*SWOL[FfI1]?\b',
    caseSensitive: false,
    multiLine: true,
  ).allMatches(text).toList();
  for (var i = avgBeforeSwol.length - 1; i >= 0; i--) {
    final m = avgBeforeSwol[i];
    final curLineStart = text.lastIndexOf('\n', m.start - 1) + 1;
    if (curLineStart <= 0) continue;
    final prevEnd = curLineStart - 1;
    if (prevEnd < 0) continue;
    final prevLineStart = text.lastIndexOf('\n', prevEnd - 1) + 1;
    final preLine = text.substring(prevLineStart, prevEnd + 1).trim();
    if (RegExp(r'SWOLF\s*G\b', caseSensitive: false).hasMatch(preLine)) {
      continue;
    }
    final a = int.tryParse(m.group(1)!);
    if (a != null && a >= 20 && a <= 220) {
      return (avg: a, best: parsedBest);
    }
  }

  final avgNear = RegExp(
    r'平均划频[\s\S]{0,160}?SWOL[FfI1]?(?:\s*O)?\s*\n\s*(\d{2,3})',
    caseSensitive: false,
  ).firstMatch(text);
  if (avgNear != null) {
    final a = int.tryParse(avgNear.group(1)!);
    if (a != null && a >= 20 && a <= 220) {
      return (avg: a, best: parsedBest);
    }
  }

  final stacked = RegExp(
    r'平均\s*SWOLF\s*最佳\s*SWOLF\s*\n\s*(\d{2,3})\s*\n\s*(\d{2,3})',
    caseSensitive: false,
    multiLine: true,
  ).allMatches(text).toList();
  if (stacked.isNotEmpty) {
    final m = stacked.last;
    final a = int.tryParse(m.group(1)!);
    final b = int.tryParse(m.group(2)!);
    if (a != null &&
        b != null &&
        a >= 20 &&
        a <= 220 &&
        b >= 10 &&
        b <= 220) {
      return (avg: a, best: b);
    }
  }
  if (parsedBest != null) {
    final matches = RegExp(
      r'平均\s*SWOL[FfI1]?',
      caseSensitive: false,
    ).allMatches(text).toList();
    if (matches.isNotEmpty) {
      final last = matches.last;
      final slice =
          text.substring(last.end, (last.end + 100).clamp(0, text.length));
      final nums = RegExp(r'\b(\d{2,3})\b')
          .allMatches(slice)
          .map((m) => int.tryParse(m.group(1)!))
          .whereType<int>()
          .where((v) => v >= 25 && v <= 200)
          .toList();
      if (nums.isNotEmpty) {
        return (avg: nums.first, best: parsedBest);
      }
    }
  }
  final matches = RegExp(
    r'平均\s*SWOL[FfI1]?',
    caseSensitive: false,
  ).allMatches(text).toList();
  if (matches.isEmpty) return (avg: null, best: null);
  final last = matches.last;
  final slice =
      text.substring(last.end, (last.end + 100).clamp(0, text.length));
  final nums = RegExp(r'\b(\d{2,3})\b').allMatches(slice).map((m) => int.tryParse(m.group(1)!)).whereType<int>().where((v) => v >= 25 && v <= 200).toList();
  if (nums.isEmpty) return (avg: null, best: null);
  int avg = nums.first;
  int? best = nums.length >= 2 ? nums[1] : null;
  if (best != null && best > avg) {
    final t = avg;
    avg = best;
    best = t;
  }
  return (avg: avg, best: parsedBest ?? best);
}

int? _xiaomiParseStrokeRate(String text) {
  final afterStroke = RegExp(
    r'[|｜]?\s*划频\s*\n\s*(\d{1,2})\s',
    multiLine: true,
  ).firstMatch(text);
  if (afterStroke != null) {
    final v = int.tryParse(afterStroke.group(1)!);
    if (v != null && v >= 4 && v <= 40) return v;
  }
  final twoLine = RegExp(
    r'平均划频\s*最高划频\s*\n\s*(\d{1,2})\s*\n\s*(\d{1,2})',
    multiLine: true,
  ).firstMatch(text);
  if (twoLine != null) {
    final v = int.tryParse(twoLine.group(1)!);
    if (v != null && v >= 3 && v <= 60) return v;
  }
  final idx = text.indexOf('平均划频');
  if (idx >= 0) {
    final win = text.substring(idx, (idx + 160).clamp(0, text.length));
    int? lastOk;
    for (final m in RegExp(r'(?<![\d.])(\d{1,2})(?![\d.])').allMatches(win)) {
      final v = int.tryParse(m.group(1)!);
      if (v != null && v >= 4 && v <= 35) lastOk = v;
    }
    if (lastOk != null) return lastOk;
  }
  final srReg =
      RegExp(r'(\d+)\s*平均划频|平均划频[^\d\n]{0,16}\n?\s*(\d+)');
  final srm = srReg.firstMatch(text);
  if (srm != null) {
    final v = int.tryParse(srm.group(1) ?? srm.group(2) ?? '');
    if (v != null && v >= 3 && v <= 60) return v;
  }
  return _xiaomiParseStrokeRateFromFooter(text);
}

/// Xiaomi footer: a standalone 1–2 digit line just above `最高划频` is often average stroke rate.
int? _xiaomiParseStrokeRateFromFooter(String text) {
  final idx = text.lastIndexOf('最高划频');
  if (idx < 0) return null;
  final before = text.substring((idx - 140).clamp(0, idx), idx);
  final lines = before.split('\n').reversed;
  for (final line in lines.take(8)) {
    final t = line.trim();
    if (t.isEmpty) continue;
    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(t)) continue;
    final m = RegExp(r'^(\d{1,2})$').firstMatch(t);
    if (m == null) continue;
    final v = int.tryParse(m.group(1)!);
    if (v != null && v >= 4 && v <= 50) return v;
  }
  return null;
}

int? _xiaomiParseStrokeCount(String text) {
  final pre = RegExp(r'(\d{3,4})\s*总划水[数教數]').firstMatch(text);
  if (pre != null) {
    final val = int.tryParse(pre.group(1)!);
    if (val != null && val >= 100 && val <= 8000) return val;
  }
  final post = RegExp(r'总划水[数教數]\D{0,24}(\d{3,4})\b').firstMatch(text);
  if (post != null) {
    final val = int.tryParse(post.group(1)!);
    if (val != null && val >= 100 && val <= 8000) return val;
  }
  for (final kw in ['总划水数', '总划水教']) {
    final pos = text.lastIndexOf(kw);
    if (pos < 0) continue;
    final back = text.substring((pos - 400).clamp(0, pos), pos);
    for (final line in back.split('\n').reversed) {
      final t = line.trim();
      if (RegExp(r'段|SWOLF|SwOLF', caseSensitive: false).hasMatch(t)) {
        continue;
      }
      final m = RegExp(r'^(\d{3,4})$').firstMatch(t);
      if (m == null) continue;
      final val = int.tryParse(m.group(1)!);
      if (val != null && val >= 150 && val <= 8000) return val;
    }
  }
  final fwdReg = RegExp(r'(?:划水次数|总划水数).{0,20}?(\d+)', dotAll: true);
  final fwdMatch = fwdReg.firstMatch(text);
  if (fwdMatch != null) {
    final val = int.tryParse(fwdMatch.group(1) ?? '');
    if (val != null && val >= 100 && val <= 5000) return val;
  }
  for (final keyword in ['划水次数', '总划水数']) {
    final pos = text.indexOf(keyword);
    if (pos < 0) continue;
    final window = text.substring((pos - 300).clamp(0, text.length), pos);
    final lineMatches =
        RegExp(r'^\s*(\d+)\s*$', multiLine: true).allMatches(window).toList();
    for (final m in lineMatches.reversed) {
      final val = int.tryParse(m.group(1) ?? '');
      if (val != null && val > 220 && val <= 5000) return val;
    }
  }
  for (final m in RegExp(r'(\d+)\s+次(?![/分])').allMatches(text)) {
    final val = int.tryParse(m.group(1) ?? '');
    if (val != null && val > 220 && val <= 5000) return val;
  }
  return null;
}

class _XiaomiPositionalParser {
  static String? _nearLabel(
    List<TextBlock> blocks,
    String labelPattern, {
    bool above = true,
    bool below = true,
    double hTolerance = 1.5,
    bool pureNumber = false,
    double maxDistPx = double.infinity,
  }) {
    TextBlock? labelBlock;
    for (final b in blocks) {
      if (RegExp(labelPattern).hasMatch(b.text)) {
        labelBlock = b;
        break;
      }
    }
    if (labelBlock == null) return null;

    final lbText = labelBlock.text;
    final lbMatch = RegExp(labelPattern).firstMatch(lbText);
    if (lbMatch != null) {
      final after = lbText.substring(lbMatch.end).trim();
      if (after.isNotEmpty && RegExp(r'\d').hasMatch(after)) return after;
    }

    final lRect = labelBlock.boundingBox;
    final lCx = lRect.left + lRect.width / 2;
    final lCy = lRect.top + lRect.height / 2;
    final maxHDist = lRect.width * hTolerance;

    TextBlock? best;
    double bestDist = double.infinity;

    for (final b in blocks) {
      if (b == labelBlock) continue;
      if (!RegExp(r'\d').hasMatch(b.text)) continue;
      if (pureNumber && !RegExp(r'^\d+$').hasMatch(b.text.trim())) continue;

      final bRect = b.boundingBox;
      final bCx = bRect.left + bRect.width / 2;
      final bCy = bRect.top + bRect.height / 2;

      if ((bCx - lCx).abs() > maxHDist) continue;

      final isAbove = bRect.bottom <= lRect.top + lRect.height * 0.3;
      final isBelow = bRect.top >= lRect.bottom - lRect.height * 0.3;
      if (!above && isAbove) continue;
      if (!below && isBelow) continue;

      final dist = (bCy - lCy).abs();
      if (dist > maxDistPx) continue;
      if (dist < bestDist) {
        bestDist = dist;
        best = b;
      }
    }
    return best?.text.trim();
  }

  static int? _int(String? raw) {
    if (raw == null) return null;
    final m = RegExp(r'\d+').firstMatch(raw);
    return m != null ? int.tryParse(m.group(0)!) : null;
  }

  static SwimOcrResult parse(List<TextBlock> blocks, String rawText) {
    final imgH = blocks.fold(
        0.0, (m, b) => b.boundingBox.bottom > m ? b.boundingBox.bottom : m);
    int? distanceMeters;
    if (imgH > 0) {
      final topBlocks = blocks
          .where((b) => b.boundingBox.bottom <= imgH * 0.25)
          .toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
      // Require "米" on the same block (or a 4-digit session distance). Optional "米" caused
      // ML Kit to bind "458" (stroke count) in the header as distance when "米" was missing.
      for (final b in topBlocks) {
        final t = b.text.trim();
        final withM = RegExp(r'^(\d{3,4})\s*米$').firstMatch(t);
        if (withM != null) {
          final v = int.tryParse(withM.group(1)!);
          if (v != null && v >= 25 && v <= 10000) {
            distanceMeters = v;
            break;
          }
        }
        final bare4 = RegExp(r'^(\d{4})$').firstMatch(t);
        if (bare4 != null) {
          final v = int.tryParse(bare4.group(1)!);
          if (v != null && v >= 400 && v <= 2000) {
            distanceMeters = v;
            break;
          }
        }
      }
    }
    distanceMeters ??= _xiaomiParseDistance(rawText);

    final pacePair = _xiaomiParsePacePair(rawText);
    final sQ = String.fromCharCode(0x27);
    final dQ = String.fromCharCode(0x22);
    final paceReg = RegExp("(\\d{1,2})[\x27\u2019\u2032](\\d{2})[\x22\u201D\u2033]");

    String? avgPace = pacePair.avg;
    String? bestPace = pacePair.best;

    final avgPaceRaw = _nearLabel(blocks, r'平均配速');
    if (avgPaceRaw != null) {
      final m = paceReg.firstMatch(avgPaceRaw);
      if (m != null) {
        avgPace = "${m.group(1)}$sQ${m.group(2)}$dQ";
      }
    }
    final bestPaceRaw = _nearLabel(blocks, r'最佳配速|最快配速');
    if (bestPaceRaw != null) {
      final m = paceReg.firstMatch(bestPaceRaw);
      if (m != null) {
        bestPace = "${m.group(1)}$sQ${m.group(2)}$dQ";
      }
    }
    if (avgPace == null) {
      final all = paceReg.allMatches(rawText).toList();
      if (all.isNotEmpty) {
        avgPace = "${all[0].group(1)}$sQ${all[0].group(2)}$dQ";
      }
      if (all.length >= 2) {
        bestPace ??= "${all[1].group(1)}$sQ${all[1].group(2)}$dQ";
      }
    }

    int? laps;
    final lapsRaw = _nearLabel(blocks, r'趟数',
        above: true, below: false, pureNumber: true, maxDistPx: 250);
    final lapsVal = _int(lapsRaw);
    if (lapsVal != null && lapsVal >= 1 && lapsVal <= 300) laps = lapsVal;

    final swSum = _xiaomiParseSwolfSummary(rawText);
    int? swolfAvg = swSum.avg;
    int? swolfBest = swSum.best;
    final swRaw = _nearLabel(blocks, r'平均\s*SWOLF', hTolerance: 2.0);
    final swVal = _int(swRaw);
    if (swVal != null && swVal >= 20 && swVal <= 200) {
      swolfAvg ??= swVal;
    }
    final sbRaw = _nearLabel(blocks, r'最[低佳]\s*SWOLF', hTolerance: 2.0);
    final sbVal = _int(sbRaw);
    if (sbVal != null && sbVal >= 10 && sbVal <= 130) {
      swolfBest ??= sbVal;
    }

    int? strokeRate = _xiaomiParseStrokeRate(rawText);
    // Do not use bare "划频" — ML Kit often places it near "00:33:55"-style timestamps (e.g. 33).
    final srRaw = _nearLabel(blocks, r'平均划频');
    final srVal = _int(srRaw);
    if (srVal != null && srVal >= 3 && srVal <= 60) {
      strokeRate ??= srVal;
    }

    final fromTextStrokes = _xiaomiParseStrokeCount(rawText);
    final scRaw = _nearLabel(blocks, r'划水次数|总划水数');
    final scVal = _int(scRaw);
    final strokeCount = (fromTextStrokes != null && fromTextStrokes >= 150)
        ? fromTextStrokes
        : (scVal ?? fromTextStrokes);

    if (distanceMeters != null &&
        strokeCount != null &&
        distanceMeters == strokeCount) {
      final alt = _xiaomiParseDistance(rawText);
      if (alt != null && alt != distanceMeters) {
        distanceMeters = alt;
      }
    }

    final finalPoolLength = _xiaomiParsePoolLength(rawText);
    final finalLaps = _xiaomiInferLaps(
      laps ??
          _xiaomiParseLaps(rawText) ??
          _xiaomiInferLapsFromHeaderLayout(rawText, distanceMeters),
      distanceMeters,
      finalPoolLength,
    );

    final footerBestPace = _xiaomiParseBestPaceFromFooter(rawText);
    if (footerBestPace != null) bestPace = footerBestPace;

    return SwimOcrResult(
      sourceBrand: OcrSourceBrand.xiaomi,
      distanceMeters: distanceMeters,
      durationMinutes: _xiaomiParseDurationMinutes(rawText),
      durationRaw: _xiaomiParseDurationRaw(rawText),
      calories: _xiaomiParseCalories(rawText),
      avgHeartRate: null,
      maxHeartRate: null,
      swimStyle: _xiaomiParseSwimStyle(rawText),
      laps: finalLaps,
      poolLength: _xiaomiInferPoolLength(finalPoolLength, distanceMeters, finalLaps),
      avgPace: avgPace,
      bestPace: bestPace,
      swolfAvg: swolfAvg,
      swolfBest: swolfBest,
      strokeRate: strokeRate,
      strokeCount: strokeCount,
      workoutDateTime: _xiaomiParseWorkoutDateTime(rawText),
    );
  }
}

class _XiaomiTextParser {
  static SwimOcrResult parse(String text) {
    final pacePair = _xiaomiParsePacePair(text);
    String? avgPace = pacePair.avg;
    String? bestPace = pacePair.best;
    if (avgPace == null) {
      final singleQ = String.fromCharCode(0x27);
      final doubleQ = String.fromCharCode(0x22);
      final paceReg =
          RegExp("(\\d{1,2})[\x27\u2019\u2032](\\d{2})[\x22\u201D\u2033]");
      final paceMatches = paceReg.allMatches(text).toList();
      if (paceMatches.isNotEmpty) {
        avgPace =
            "${paceMatches[0].group(1)}$singleQ${paceMatches[0].group(2)}$doubleQ";
      }
      if (paceMatches.length >= 2) {
        bestPace ??=
            "${paceMatches[1].group(1)}$singleQ${paceMatches[1].group(2)}$doubleQ";
      } else {
        final bpReg =
            RegExp(r'最佳配速[^\d]*(\d+)' + singleQ + r'(\d+)' + doubleQ);
        final bpm = bpReg.firstMatch(text);
        if (bpm != null) {
          bestPace ??= "${bpm.group(1)}$singleQ${bpm.group(2)}$doubleQ";
        }
      }
    }
    final footerBest = _xiaomiParseBestPaceFromFooter(text);
    if (footerBest != null) {
      bestPace = footerBest;
    }

    final sw = _xiaomiParseSwolfSummary(text);
    int? swolfAvg = sw.avg;
    int? swolfBest = sw.best;

    final strokeRate = _xiaomiParseStrokeRate(text);

    final xDist = _xiaomiParseDistance(text);
    final xPool = _xiaomiParsePoolLength(text);
    final xLaps = _xiaomiInferLaps(
      _xiaomiParseLaps(text) ?? _xiaomiInferLapsFromHeaderLayout(text, xDist),
      xDist,
      xPool,
    );

    return SwimOcrResult(
      sourceBrand: OcrSourceBrand.xiaomi,
      distanceMeters: xDist,
      durationMinutes: _xiaomiParseDurationMinutes(text),
      durationRaw: _xiaomiParseDurationRaw(text),
      calories: _xiaomiParseCalories(text),
      avgHeartRate: null,
      maxHeartRate: null,
      swimStyle: _xiaomiParseSwimStyle(text),
      laps: xLaps,
      poolLength: _xiaomiInferPoolLength(xPool, xDist, xLaps),
      avgPace: avgPace,
      bestPace: bestPace,
      swolfAvg: swolfAvg,
      swolfBest: swolfBest,
      strokeRate: strokeRate,
      strokeCount: _xiaomiParseStrokeCount(text),
      workoutDateTime: _xiaomiParseWorkoutDateTime(text),
    );
  }
}

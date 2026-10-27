class LyricLine {
  final Duration timestamp;
  final String text;

  LyricLine(this.timestamp, this.text);
}

/// Parses standard LRC format: `[mm:ss.xx]lyric text`.
class LrcParser {
  static List<LyricLine> parse(String content) {
    final lines = <LyricLine>[];
    final pattern = RegExp(r'\[(\d{2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

    for (final rawLine in content.split('\n')) {
      final match = pattern.firstMatch(rawLine.trim());
      if (match == null) continue;
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fraction = match.group(3);
      final millis = fraction == null ? 0 : int.parse(fraction.padRight(3, '0'));
      final text = match.group(4)?.trim() ?? '';
      if (text.isEmpty) continue;

      lines.add(LyricLine(
        Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
        text,
      ));
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  static int currentLineIndex(List<LyricLine> lines, Duration position) {
    var index = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }
}

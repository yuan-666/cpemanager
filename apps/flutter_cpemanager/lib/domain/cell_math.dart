int? parseFlexibleInt(String? value) {
  if (value == null) {
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed == '--') {
    return null;
  }
  final cleaned = trimmed
      .replaceAll(RegExp(r'[^0-9A-Fa-fxX-]'), '')
      .replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (cleaned.isEmpty || cleaned == '-') {
    return null;
  }
  final looksHex = cleaned.startsWith('0x') ||
      cleaned.startsWith('0X') ||
      RegExp(r'[A-Fa-f]').hasMatch(cleaned);
  return int.tryParse(
    cleaned.replaceFirst(RegExp(r'^0[xX]'), ''),
    radix: looksHex ? 16 : 10,
  );
}

int? parseTacDecimal(String? value) {
  return parseFlexibleInt(value);
}

int? computeEci({String? enbId, String? cellId}) {
  final enb = parseFlexibleInt(enbId);
  final cell = parseFlexibleInt(cellId);
  if (enb == null || cell == null) {
    return null;
  }
  return enb * 256 + cell;
}

int? computeGci({String? gnbId, String? cellId}) {
  final gnb = parseFlexibleInt(gnbId);
  final cell = parseFlexibleInt(cellId);
  if (gnb == null || cell == null) {
    return null;
  }
  return gnb * 4096 + cell;
}

({int baseId, int localCellId})? splitEci(String? eci) {
  final value = parseFlexibleInt(eci);
  if (value == null) {
    return null;
  }
  return (baseId: value ~/ 256, localCellId: value % 256);
}

({int baseId, int localCellId})? splitGci(String? gci) {
  final value = parseFlexibleInt(gci);
  if (value == null) {
    return null;
  }
  return (baseId: value ~/ 4096, localCellId: value % 4096);
}

String decimalText(int? value) {
  return value == null ? '--' : value.toString();
}

String compoundCellText({String? baseId, String? localCellId}) {
  final base = parseFlexibleInt(baseId);
  final cell = parseFlexibleInt(localCellId);
  if (base == null || cell == null) {
    return '--';
  }
  return '$base-$cell';
}

String deriveNrGnbCell({
  String? gnbId,
  String? localCellId,
  String? gci,
}) {
  final direct = compoundCellText(baseId: gnbId, localCellId: localCellId);
  if (direct != '--') {
    return direct;
  }
  final split = splitGci(gci);
  if (split == null) {
    return '--';
  }
  return '${split.baseId}-${split.localCellId}';
}

String deriveLteEnbCell({
  String? enbId,
  String? localCellId,
  String? eci,
}) {
  final direct = compoundCellText(baseId: enbId, localCellId: localCellId);
  if (direct != '--') {
    return direct;
  }
  final split = splitEci(eci);
  if (split == null) {
    return '--';
  }
  return '${split.baseId}-${split.localCellId}';
}

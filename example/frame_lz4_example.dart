import 'dart:typed_data';

import 'package:frame_lz4/frame_lz4.dart';

void main() {
  final lz4 = FrameLZ4();

  final original = Uint8List.fromList(List<int>.generate(1000, (i) => i % 256));
  final compressed = lz4.compress(original);
  final decompressed = lz4.decompress(compressed, original.length);

  print('Original size: ${original.length}');
  print('Compressed size: ${compressed.length}');
  print('Compression ratio: ${compressed.length / original.length}');
  print('Data matches: ${listEquals(original, decompressed)}');
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

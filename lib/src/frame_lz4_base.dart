import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';

class LZ4Exception implements Exception {
  final String message;
  LZ4Exception(this.message);
  @override
  String toString() => 'LZ4Exception: $message';
}

typedef LZ4CompressFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> source,
    ffi.Pointer<ffi.Void> dest,
    ffi.Int32 sourceSize,
    ffi.Int32 destSize);

typedef LZ4CompressFuncDart = int Function(
    ffi.Pointer<ffi.Void> source,
    ffi.Pointer<ffi.Void> dest,
    int sourceSize,
    int destSize);

typedef LZ4DecompressFunc = ffi.Int32 Function(
    ffi.Pointer<ffi.Void> source,
    ffi.Pointer<ffi.Void> dest,
    ffi.Int32 compressedSize,
    ffi.Int32 destCapacity);

typedef LZ4DecompressFuncDart = int Function(
    ffi.Pointer<ffi.Void> source,
    ffi.Pointer<ffi.Void> dest,
    int compressedSize,
    int destCapacity);

class FrameLZ4 {
  late final ffi.DynamicLibrary _lib;
  late final LZ4CompressFuncDart _compress;
  late final LZ4DecompressFuncDart _decompress;

  FrameLZ4() {
    _lib = _loadLibrary();
    _compress = _lib
        .lookupFunction<LZ4CompressFunc, LZ4CompressFuncDart>('LZ4_compress_default');
    _decompress = _lib
        .lookupFunction<LZ4DecompressFunc, LZ4DecompressFuncDart>('LZ4_decompress_safe');
  }

  ffi.DynamicLibrary _loadLibrary() {
    String libraryPath = '';
    if (Platform.isAndroid) {
      libraryPath = 'liblz4.so';
    } else if (Platform.isIOS) {
      libraryPath = 'lz4.framework/lz4';
    } else {
      throw LZ4Exception('Unsupported platform');
    }

    try {
      return ffi.DynamicLibrary.open(libraryPath);
    } catch (e) {
      throw LZ4Exception('Failed to load LZ4 library: $e');
    }
  }

  List<int> compress(List<int> source) {
    final sourcePointer = calloc<ffi.Uint8>(source.length);
    final sourceList = sourcePointer.asTypedList(source.length);
    sourceList.setAll(0, source);

    // LZ4 compression bound is source size + 0.4% + 8 bytes
    final maxDestSize = (source.length * 1.004).ceil() + 8;
    final destPointer = calloc<ffi.Uint8>(maxDestSize);

    try {
      final compressedSize = _compress(
        sourcePointer.cast(),
        destPointer.cast(),
        source.length,
        maxDestSize,
      );

      if (compressedSize <= 0) {
        throw LZ4Exception('Compression failed');
      }

      return destPointer.asTypedList(compressedSize).toList();
    } finally {
      calloc.free(sourcePointer);
      calloc.free(destPointer);
    }
  }

  List<int> decompress(List<int> compressed, int originalSize) {
    final sourcePointer = calloc<ffi.Uint8>(compressed.length);
    final sourceList = sourcePointer.asTypedList(compressed.length);
    sourceList.setAll(0, compressed);

    final destPointer = calloc<ffi.Uint8>(originalSize);

    try {
      final decompressedSize = _decompress(
        sourcePointer.cast(),
        destPointer.cast(),
        compressed.length,
        originalSize
      );

      if (decompressedSize <= 0) {
        throw LZ4Exception('Decompression failed');
      }

      return destPointer.asTypedList(decompressedSize).toList();
    } finally {
      calloc.free(sourcePointer);
      calloc.free(destPointer);
    }
  }
}

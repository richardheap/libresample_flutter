import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

/*
'C' Header definition
void* lrs_open(WORD highQuality,
               double minFactor,
               double maxFactor) {
 */
typedef lrs_open_func = Pointer<Void> Function(Int32, Double, Double);
typedef LrsOpen = Pointer<Void> Function(int, double, double);

/*
'C' Header definition
void lrs_close(void *handle) {
 */
typedef lrs_close_func = Void Function(Pointer<Void>);
typedef LrsClose = void Function(Pointer<Void>);

/*
'C' Header definition
WORD lrs_process(void *handle,
                double factor,
                float *inBuffer,
                WORD inBufferLen,
                WORD lastFlag,
                WORD *inBufferUsed,
                float *outBuffer,
                WORD outBufferLen) {
 */
typedef lrs_process_func = Int32 Function(
  Pointer<Void>,
  Double,
  Pointer<Float>,
  Int32,
  Int32,
  Pointer<Int32>,
  Pointer<Float>,
  Int32,
);
typedef LrsProcess = int Function(
  Pointer<Void>,
  double,
  Pointer<Float>,
  int,
  int,
  Pointer<Int32>,
  Pointer<Float>,
  int,
);

/// The singleton plugin API
///
/// The public API is exposed by the [Resampler] class
class LibresampleFlutter {
  static LibresampleFlutter _instance;

  LrsOpen _lrsOpen;
  LrsClose _lrsClose;
  LrsProcess _lrsProcess;

  factory LibresampleFlutter() {
    if (_instance == null) {
      _instance = LibresampleFlutter._();
    }
    return _instance;
  }

  LibresampleFlutter._() {
    final DynamicLibrary nativeLrsLib = Platform.isAndroid
        ? DynamicLibrary.open("libnative_libresample.so")
        : DynamicLibrary.process();

    _lrsOpen = nativeLrsLib
        .lookup<NativeFunction<lrs_open_func>>('lrs_open')
        .asFunction();

    _lrsClose = nativeLrsLib
        .lookup<NativeFunction<lrs_close_func>>('lrs_close')
        .asFunction();

    _lrsProcess = nativeLrsLib
        .lookup<NativeFunction<lrs_process_func>>('lrs_process')
        .asFunction();
  }
}

/// The Flutter ffi wrapper around the libresample resampler.
///
/// See: https://github.com/minorninth/libresample
class Resampler {
  double _maxFactor;

  Pointer<Void> _nativeInstance;
  var _closed = false;

  Pointer<Int32> _inUsed = allocate<Int32>();

  Pointer<Float> _inBuf;
  var _inLen = 0;

  Pointer<Float> _outBuf;
  var _outLen = 0;

  /// Creates a resampler.
  ///
  /// The [minFactor] and [maxFactor] parameters specify the lower and upper
  /// bounds on the resampling factor that will be accepted in [process]. If
  /// a fixed refactoring factor is required they may be the same.
  ///
  /// The [highQuality] setting makes the resample create more filters, leading
  /// to better quality output.
  Resampler(bool highQuality, double minFactor, double maxFactor) {
    _maxFactor = maxFactor;
    _nativeInstance = LibresampleFlutter()._lrsOpen(
      highQuality ? 1 : 0,
      minFactor,
      maxFactor,
    );
  }

  void _ensureBuffers(int inSize) {
    // output buffer needs to be factor * input buffer
    var outSize = (inSize * _maxFactor).ceil();
    // plus some for luck
    outSize += min(100, (outSize * 0.1).ceil());

    if (_inLen == 0) {
      _inLen = inSize;
      _inBuf = allocate<Float>(count: inSize);
    } else if (inSize > _inLen) {
      free(_inBuf);
      _inLen = inSize;
      _inBuf = allocate<Float>(count: inSize);
    }

    if (_outLen == 0) {
      _outLen = outSize;
      _outBuf = allocate<Float>(count: outSize);
    } else if (outSize > _outLen) {
      free(_outBuf);
      _outLen = outSize;
      _outBuf = allocate<Float>(count: outSize);
    }
  }

  /// Processes a block of audio from one sample rate to another.
  ///
  /// [factor] must be between the two extremes provided in the constructor.
  /// [input] is a list of floats that will be processed, returning a list
  /// approximately [input.length] * [factor] long. If this is the last block,
  /// set [last], to flush the internal buffers with the output.
  Float32List process(double factor, Float32List input, bool last) {
    if (_closed) {
      throw Exception('already closed');
    }

    _ensureBuffers(input.length);
    _inBuf.asTypedList(_inLen).setRange(0, input.length, input);

    var processed = LibresampleFlutter()._lrsProcess(
      _nativeInstance,
      factor,
      _inBuf,
      input.length,
      last ? 1 : 0,
      _inUsed,
      _outBuf,
      _outLen,
    );

    if (processed <= 0) {
      print('hmmm $processed');
      return null;
    }

    var output = Float32List(processed);
    output.setRange(0, processed, _outBuf.asTypedList(_outLen));

    return output;
  }

  /// Closes the resampler and frees its native resources.
  void close() {
    if (!_closed) {
      LibresampleFlutter()._lrsClose(_nativeInstance);
      _closed = true;
    }
  }
}

/// A chainable audio processor, implementing a fixed resampling factor.
///
/// After construction, use [setInputStream] to provide an [Iterator] of float
/// lists. (Typically this comes from a similar effect earlier in the chain -
/// for example a jitter buffer.) Supply the output of this block in the chain
/// to the next by using [getOutputStream().iterator()].
///
/// The last block in the audio processing chain is typically supplying the
/// sound card by pulling on its output stream iterator. This in turn pulls
/// on the preceding block in the chain by calling [inputStream.moveNext()]
/// until that returns [false] at the end of the audio.
class ResamplerStream {
  double _factor;
  Resampler _resampler;
  Iterator<Float32List> inputStream;

  /// Creates a wrapper around a resampler with an [Iterator] as input and an
  /// [Iterable] as output.
  ///
  /// See [Resampler] for an explanation of [_factor] and [highQuality].
  ResamplerStream(this._factor, bool highQuality) {
    _resampler = Resampler(highQuality, _factor, _factor);
  }

  /// Sets the input of this audio block to the [Iterator]
  void setInputStream(Iterator<Float32List> stream) {
    inputStream = stream;
  }

  /// Retrieves the [Iterable] that can be used by the next block in the chain.
  Iterable<Float32List> getOutputStream() sync* {
    while (true) {
      if (!inputStream.moveNext()) break;
      yield _resampler.process(_factor, inputStream.current, false);
    }
  }
}

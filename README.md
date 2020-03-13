# libresample_flutter

An implementation of [libresample](https://github.com/minorninth/libresample)
as a Flutter plugin using `dart:ffi`.

## Usage

Firstly, import the package:

```dart
import 'package:libresample_flutter/libresample_flutter.dart';
```

You don't need to interact with the plugin class directly.
(All its members are private anyway.) Instead, use the Dart wrapper classes
`Resampler` or `ResamplerStream`.

## Using Resampler

```dart
    // create a 2:1 upsampler
    var resampler = Resampler(true, 2, 2);

    // process a block of 160 floats
    resampler.process(2, Float32List(160), false);
    // etc

    // process the last block of 160 floats
    resampler.process(2, Float32List(160), true);

    // and free the native resources 
    resampler.close();
```

## Using ResamplerStream

```dart
    // create a resampler node upsampling from 16kHz to the native sound card rate
    // and set its input to a previous processing block's output iterator
    var upsamplerStream = ResamplerStream(nativeRate / 16000.0, true)
      ..setInputStream(helper.getOutputStream().iterator);

    // and grab its iterator for use by the next block
    // (in the case of the ressmpler, the next block is typically the sound card,
    // perhaps using the companion project audio_worklet
    stream = upsamplerStream.getOutputStream().iterator;
```
See [audio_worklet](https://github.com/richardheap/audio_worklet) fo
the companion project.

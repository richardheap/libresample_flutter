import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:libresample_flutter/libresample_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    var resampler = Resampler(true, 2, 2);
    resampler.process(2, Float32List(160), false);
    resampler.process(2, Float32List(160), false);
    resampler.process(2, Float32List(160), false);
    resampler.process(2, Float32List(160), false);
    resampler.process(2, Float32List(160), true);
    resampler.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Testing'),
        ),
      ),
    );
  }
}

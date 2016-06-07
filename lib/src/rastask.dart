// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastask;

import 'dart:async' show
    Future;

import 'dart:isolate' show
    Isolate;

import 'dart:io' show
    File,
    IOSink;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'options.dart' show
    OptionParser,
    Options;

import 'run_single.dart' show
    RunSingle;

Future openWrite(Uri uri, f(IOSink sink)) async {
  IOSink sink = new File.fromUri(uri).openWrite();
  try {
    await f(sink);
  } finally {
    await sink.close();
  }
  print("Wrote $uri");
}

abstract class Rastask extends CompilerTask {
  final Stopwatch wallClock;
  final Options options;

  Rastask(CustomCompiler compiler, this.wallClock, this.options)
      : super(compiler);

  String get name => "rastak";

  CustomCompiler get compiler => super.compiler;

  Future run();

  static Future<Rastask> setup(
      Stopwatch wallClock,
      List<String> arguments) async {
    Options options = new OptionParser(arguments, Uri.base).parse();
    List<String> compilerOptions =
        options.isVerbose ? <String>['--verbose'] : <String>[];
    Uri script = await Isolate.resolvePackageUri(
        Uri.parse("package:rasta/src/rastak.dart"));
    Uri targetSpecification = Uri.base.resolveUri(script)
        .resolve("../../dart_vm_standalone.json");
    IoCompilerFactory factory = new IoCompilerFactory(
        targetSpecification, compilerOptions, <String, dynamic>{});
    (await factory.diagnostics)
        ..verbose = options.isVerbose
        ..showWarnings = true
        ..throwOnError = false
        ..throwOnErrorCount = 1;

    CustomCompiler compiler = await factory.compiler;
    Rastask task;
    task = new RunSingle(compiler, wallClock, options);
    compiler.tasks.add(task);
    return task;
  }
}

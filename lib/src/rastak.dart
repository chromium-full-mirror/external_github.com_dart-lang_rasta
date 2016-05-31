// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastak;

import 'dart:io' show
    File,
    IOSink;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'package:rasta/kernel.dart' show
    Kernel;

class Options {
  final Uri input;
  final Uri output;
  final bool generateLibrary;
  final bool isVerbose;

  Options(this.input, this.output, {this.generateLibrary, this.isVerbose});
}

class OptionParser {
  Options parse(List<String> arguments, Uri base) {
    Iterator<String> iterator = arguments.iterator;
    // Null means not specified.
    bool generateLibrary = null;
    bool hasNext = false;
    bool isVerbose = false;
    while (hasNext = iterator.moveNext()) {
      if (!iterator.current.startsWith("-")) break;
      if (iterator.current == "--") break;
      switch (iterator.current) {
        case "--library":
          generateLibrary = true;
          break;

        case "--program":
          generateLibrary = false;
          break;

        case "--verbose":
          isVerbose = true;
          break;

        default:
          throw "Unknown option: '${iterator.current}'.";
      }
    }
    if (!hasNext) {
      throw "Missing required arguments: [input] [output].";
    }
    Uri input = base.resolve(iterator.current);
    if (!iterator.moveNext()) {
      throw "Missing required argument: [output].";
    }
    Uri output = base.resolve(iterator.current);
    if (iterator.moveNext()) {
      throw "Missing additional argument: '${iterator.current}'.";
    }
    return new Options(
        input, output, generateLibrary: generateLibrary, isVerbose: isVerbose);
  }
}

Stopwatch wallClock;

Future<Null> main(List<String> arguments, isolateArgument) {
  wallClock = new Stopwatch()..start();
  return slowMain(arguments, isolateArgument);
}

Future<Null> slowMain(List<String> arguments, isolateArgument) async {
  Options options = new OptionParser().parse(arguments, Uri.base);
  List<String> compilerOptions =
      options.isVerbose ? <String>['--verbose'] : <String>[];
  IoCompilerFactory factory = new IoCompilerFactory(
      Uri.base.resolve("dart_vm_standalone.json"), compilerOptions,
      <String, dynamic>{});

  (await factory.diagnostics)
      ..verbose = options.isVerbose
      ..showWarnings = true
      ..throwOnError = true
      ..throwOnErrorCount = 1;

  CustomCompiler compiler = await factory.compiler;
  await compiler.setupSdk();

  await compiler.setupPackages(options.input);

  Duration setupDuration = wallClock.elapsed;

  Kernel kernel = new Kernel(compiler);
  ir.Library library = await kernel.loadLibrary(options.input);

  bool generateLibrary = options.generateLibrary;
  if (generateLibrary == null) {
    generateLibrary = !kernel.hasMainMethod(options.input);
  }
  if (generateLibrary) {
    kernel.processWorkQueue(targetLibrary: options.input);
  } else {
    if (!kernel.hasMainMethod(options.input)) {
      throw "No main method in ${options.input}.";
    }
    kernel.processWorkQueue();
  }

  ir.Program program;
  if (!generateLibrary) {
    Iterable<ir.Procedure> mainMethods = library.procedures.where(
        (ir.Procedure function) => function.name.name == "main");
    program =
        new ir.Program(new List<ir.Library>.from(kernel.libraries.values))
            ..mainMethod = mainMethods.single;
  }
  compiler.printVerboseTimings(setupDuration);
  IOSink sink = new File.fromUri(options.output).openWrite();
  try {
    BinaryPrinter printer = new BinaryPrinter(sink);
    if (generateLibrary) {
      printer.writeLibraryFile(library);
    } else {
      printer.writeProgramFile(program);
    }
  } finally {
    await sink.close();
  }
  print("Wrote ${options.output}");
}

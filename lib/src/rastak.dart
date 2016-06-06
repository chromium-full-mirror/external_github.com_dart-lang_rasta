// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastak;

import 'dart:async' show
    Future;

import 'dart:io' show
    File,
    IOSink;

import 'dart:isolate' show
    Isolate;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:compiler/src/elements/elements.dart' show
    CompilationUnitElement,
    LibraryElement;

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
  final Uri dependenciesFile;
  final bool generateLibrary;
  final bool isVerbose;

  Options(this.input, this.output,
          {this.dependenciesFile, this.generateLibrary, this.isVerbose});
}

class OptionParser {
  Options parse(List<String> arguments, Uri base) {
    Iterator<String> iterator = arguments.iterator;
    String getArgument(String name) {
      if (!iterator.moveNext()) {
        throw "Missing argument to option '$name'";
      }
      return iterator.current;
    }
    // Null means not specified.
    bool generateLibrary = null;
    bool hasNext = false;
    bool isVerbose = false;
    Uri dependenciesFile;
    while (hasNext = iterator.moveNext()) {
      if (!iterator.current.startsWith("-")) break;
      if (iterator.current == "--") break;
      String name = iterator.current;
      String argument;
      int equalSignIndex = name.indexOf("=");
      if (equalSignIndex != -1) {
        argument = name.substring(equalSignIndex + 1);
        name = name.substring(0, equalSignIndex);
      }
      switch (name) {
        case "--library":
          generateLibrary = true;
          break;

        case "--program":
          generateLibrary = false;
          break;

        case "--verbose":
          isVerbose = true;
          break;

        case "--list-dependencies":
          argument ??= getArgument(name);
          dependenciesFile = Uri.base.resolveUri(new Uri.file(argument));
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
        input, output, dependenciesFile: dependenciesFile,
        generateLibrary: generateLibrary, isVerbose: isVerbose);
  }
}

class Rastask extends CompilerTask {
  Rastask(CustomCompiler compiler)
      : super(compiler);

  String get name => "rastak";
}

Future openWrite(Uri uri, f(IOSink sink)) async {
  IOSink sink = new File.fromUri(uri).openWrite();
  try {
    await f(sink);
  } finally {
    await sink.close();
  }
  print("Wrote $uri");
}

Future<Null> main(List<String> arguments, isolateArgument) async {
  Stopwatch wallClock = new Stopwatch()..start();
  Options options = new OptionParser().parse(arguments, Uri.base);
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
  Rastask task = new Rastask(compiler);
  compiler.tasks.add(task);

  // Due to an implementation detail (an optimization that may be wrong) in
  // zones, a `then` handler on a future may be run recursively inside a
  // measuring zone. If the handler belongs to a non-measuring zone, its run
  // time will be incorrectly counted in the measuring zone. In practice, the
  // library loader was blamed for the execution time of rastak. By adding a
  // Rasta task, we avoid counting rastak towards the library loader, and we
  // get a counter for rastak.
  await task.measure(() => run(wallClock, compiler, options));
}

Future<Null> run(
    Stopwatch wallClock,
    CustomCompiler compiler,
    Options options) async {
  Duration setupDuration = wallClock.elapsed;

  await compiler.setupSdk();

  await compiler.setupPackages(options.input);

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
  await openWrite(options.output, (IOSink sink) {
    BinaryPrinter printer = new BinaryPrinter(sink);
    if (generateLibrary) {
      printer.writeLibraryFile(library);
    } else {
      printer.writeProgramFile(program);
    }
  });

  if (options.dependenciesFile != null) {
    await openWrite(options.dependenciesFile, (IOSink sink) {
      void writeCompilationUnit(CompilationUnitElement unit) {
        sink.write("${unit.script.resourceUri}\n");
      }
      kernel.forEachLibraryElement((LibraryElement library) {
        library.compilationUnits.forEach(writeCompilationUnit);
      });
    });
  }
}

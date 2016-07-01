// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastask;

import 'dart:async' show
    Future;

import 'dart:io' show
    File,
    IOSink;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:compiler/src/elements/elements.dart' show
    CompilationUnitElement,
    LibraryElement;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show
    Printer;

import '../io_compiler_factory.dart' show
    IoCompilerFactory;

import '../custom_compiler.dart' show
    CustomCompiler;

import '../kernel.dart' show
    Kernel;

import 'options.dart' show
    OptionParser,
    Options;

import 'run_single.dart' show
    RunSingle;

import 'run_batch.dart' show
    RunBatch;

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
  final Options globalOptions;
  Duration setupDuration;
  Kernel kernel;
  ir.Library coreLibrary;

  Rastask(CustomCompiler compiler, this.wallClock, this.globalOptions)
      : super(compiler);

  String get name => "rastak";

  CustomCompiler get compiler => super.compiler;

  Future run();

  Future<Null> setup([Uri uri]) async {
    if (setupDuration != null) {
      throw new StateError("[setup] can only be called once.");
    }
    setupDuration = wallClock.elapsed;
    await compiler.setupSdk();
    await compiler.setupPackages(uri);
    kernel = new Kernel(compiler);

    coreLibrary = await loadLibrary(Uri.parse("dart:core"));
    print(
        "Loading platform libraries took: "
        "${(wallClock.elapsedMilliseconds).toStringAsFixed(3)}ms");
  }

  Future<ir.Library> loadLibrary(Uri uri) async {
    ir.Library library = await kernel.loadLibrary(uri);
    kernel.processWorkQueue();
    return library;
  }

  Future<ir.TreeNode> runOne(Options options) async {
    ir.Library library = await loadLibrary(options.input);

    bool generateLibrary = options.generateLibrary;
    if (generateLibrary == null) {
      generateLibrary = !kernel.hasMainMethod(options.input);
    }
    if (!generateLibrary && !kernel.hasMainMethod(options.input)) {
      throw "No main method in ${options.input}.";
    }

    ir.Program program;
    if (!generateLibrary) {
      Iterable<ir.Procedure> mainMethods = library.procedures.where(
          (ir.Procedure function) => function.name.name == "main");
      program = new ir.Program(kernel.libraryDependencies(options.input))
          ..mainMethod = mainMethods.single;
    }
    compiler.printVerboseTimings(setupDuration);
    if (options.output != null) {
      await openWrite(options.output, (IOSink sink) {
        BinaryPrinter printer = new BinaryPrinter(sink);
        if (generateLibrary) {
          printer.writeLibraryFile(library);
        } else {
          printer.writeProgramFile(program);
        }
      });
    } else {
      StringBuffer buffer = new StringBuffer();
      Printer printer = new Printer(buffer);
      if (generateLibrary) {
        printer.writeLibraryFile(library);
      } else {
        printer.writeProgramFile(program);
      }
      print("$buffer");
    }

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
    return generateLibrary ? library : program;
  }

  static Future<Rastask> create(
      Stopwatch wallClock,
      List<String> arguments) async {
    Options options = await new OptionParser(arguments, Uri.base).parse();
    List<String> compilerOptions =
        options.isVerbose ? <String>['--verbose'] : <String>[];
    IoCompilerFactory factory = new IoCompilerFactory(
        options.targetSpecification, compilerOptions, <String, dynamic>{});
    (await factory.diagnostics)
        ..verbose = options.isVerbose
        ..showWarnings = true
        ..throwOnError = options.throwOnError
        ..throwOnErrorCount = options.throwOnErrorCount;

    CustomCompiler compiler = await factory.compiler;
    if (options.analyze) {
      compiler.checker.enabled = true;
    }
    Rastask task;
    if (options.isBatch) {
      task = new RunBatch(compiler, wallClock, options);
    } else {
      task = new RunSingle(compiler, wallClock, options);
    }
    compiler.tasks.add(task);
    return task;
  }
}

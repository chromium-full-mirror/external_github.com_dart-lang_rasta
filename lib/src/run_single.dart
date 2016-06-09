// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.run_single;

import 'dart:async' show
    Future;

import 'dart:io' show
    IOSink;

import 'package:compiler/src/elements/elements.dart' show
    CompilationUnitElement,
    LibraryElement;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:kernel/text/ast_to_text.dart' show
    Printer;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'package:rasta/kernel.dart' show
    Kernel;

import 'options.dart' show
    Options;

import 'rastask.dart' show
    Rastask,
    openWrite;

class RunSingle extends Rastask {
  RunSingle(CustomCompiler compiler, Stopwatch wallClock, Options options)
      : super(compiler, wallClock, options);

  Future<ir.TreeNode> run() async {
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
}

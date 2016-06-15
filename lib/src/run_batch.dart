// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.run_batch;

import 'dart:async' show
    Future,
    Stream;

import 'dart:io' show
    File,
    IOSink;

import 'dart:convert' show
    LineSplitter,
    UTF8;

import 'package:compiler/src/util/uri_extras.dart' show
    relativize;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'package:rasta/kernel.dart' show
    Kernel;

import 'package:rasta/testing.dart' show
    TestDescription,
    listTests;

import 'options.dart' show
    Options;

import 'rastask.dart' show
    Rastask,
    openWrite;

// Reads lines of the form '<input> <output>' (space separated) from the given
// file and generates a test case that compiles each input to the corresponding
// output file.
Stream<TestDescription> readTestsFromFile(Stream<List<int>> input) async* {
  Stream<String> lines = input
      .transform(UTF8.decoder)
      .transform(new LineSplitter());
  await for (String line in lines) {
    int splitPoint = line.indexOf(' ');
    if (splitPoint < 0) {
      print("Skipping garbage in input file: $line");
    } else {
      Uri input = Uri.parse(line.substring(0, splitPoint));
      Uri output = Uri.parse(line.substring(splitPoint + 1));
      yield new TestDescription(new File.fromUri(input), output: output);
    }
  }
}

class RunBatch extends Rastask {
  RunBatch(CustomCompiler compiler, Stopwatch wallClock, Options options)
      : super(compiler, wallClock, options);

  Future<Null> run() async {
    await compiler.setupSdk();

    await compiler.setupPackages(null);

    Kernel kernel = new Kernel(compiler);
    await kernel.loadLibrary(Uri.parse("dart:core"));
    kernel.processWorkQueue();

    wallClock.stop();
    print(
        "Loading platform libraries took: "
        "${(wallClock.elapsedMilliseconds).toStringAsFixed(3)}ms");
    wallClock
        ..reset()
        ..start();


    Uri testUri = compiler.translateUri(null, options.input);

    // TODO(ahe): This lists all tests in [testUri] if it is a directory
    // and generates Kernel IR for them all. If [testUri] is a file, it
    // reads the file as a sequence of lines with pairs of test inputs and
    // outputs. However, batch mode should be a server that is controlled
    // by test.dart.

    // TODO(ahe): Share more code with RunSingle.

    List<TestDescription> failures = <TestDescription>[];

    int count = 0;
    print("\n");

    File inputFile = new File.fromUri(testUri);
    Stream<TestDescription> tests = await inputFile.exists()
        ? readTestsFromFile(inputFile.openRead())
        : listTests(<Uri>[testUri], pattern: options.pattern);

    await for (TestDescription description in tests) {
      count++;
      try {
        Uri output = description.output;
        output ??= description.uri.resolve("${description.uri.path}.bart");

        Options options = new Options(
            description.uri,
            output,
            generateLibrary: this.options.generateLibrary);

        ir.Library library = await kernel.loadLibrary(options.input);
        if (this.options.generateLibrary) {
          kernel.processWorkQueue(targetLibrary: options.input);
        } else {
          kernel.processWorkQueue();
        }

        if (options.generateLibrary == true) {
          await openWrite(options.output, (IOSink sink) {
            BinaryPrinter printer = new BinaryPrinter(sink);
            printer.writeLibraryFile(library);
          });
        } else {
          Iterable<ir.Procedure> mainMethods = library.procedures.where(
              (ir.Procedure function) => function.name.name == "main");

          ir.Program program =
              new ir.Program(kernel.libraryDependencies(options.input))
                  ..mainMethod = mainMethods.single;

          await openWrite(options.output, (IOSink sink) {
            BinaryPrinter printer = new BinaryPrinter(sink);
            printer.writeProgramFile(program);
          });
        }
      } catch (e, s) {
        if (this.options.isVerbose) {
          print("${description.uri} failed: $e\n$s\n\n");
        }
        failures.add(description);
      }
      String averageTimeMs =
          (wallClock.elapsedMilliseconds / count).toStringAsFixed(3);
      String successes = padTo(count - failures.length, 5);
      String failuresPadded = padTo(failures.length, 5);
      print(
          "\u001b[1A"
          "\u001b[2K"
          "\u001b[1A"
          "\u001b[2K"
          "Average time per test: ${averageTimeMs}ms\n"
          "[${wallClock.elapsed} | --% | +$successes | -$failuresPadded ]"
        );
    }
    wallClock.stop();
    String averageTimeMs =
        (wallClock.elapsedMilliseconds / count).toStringAsFixed(3);

    if (failures.isNotEmpty) {
      print("\n=== Failures ===\n");
      for (TestDescription description in failures) {
        print("${relativize(Uri.base, description.uri, false)}: Fail");
      }
    }

    print(
"""

=== Summary ===
Total: $count
Failures: ${failures.length}
Average time per test: ${averageTimeMs}ms
Success rate: ${(100 - failures.length * 100/count).toStringAsFixed(2)}%""");
  }
}

String padTo(int i, int pad) {
  String result = (" " * pad) + "$i";
  return result.substring(result.length - pad);
}

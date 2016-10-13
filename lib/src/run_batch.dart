// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.run_batch;

import 'dart:async' show
    Future,
    Stream;

import 'dart:io' show
    File,
    stderr,
    stdin;

import 'dart:convert' show
    LineSplitter,
    UTF8;

import 'package:compiler/src/util/uri_extras.dart' show
    relativize;

import '../custom_compiler.dart' show
    CustomCompiler;

import 'package:testing/testing.dart' show
    TestDescription,
    listTests;

import 'options.dart' show
    Options;

import 'rastask.dart' show
    Rastask;

// Reads lines of the form '<input> <output>' (space separated) from the
// given stream and generates a test case that compiles each input to the
// corresponding output file.
Stream<TestDescription> readTestsFromStream(Stream<List<int>> input) async* {
  Stream<String> lines = input
      .transform(UTF8.decoder)
      .transform(new LineSplitter());
  await for (String line in lines) {
    int splitPoint = line.indexOf(' ');
    if (splitPoint < 0) {
      throw "Got garbage in input file: $line";
    } else {
      Uri input = Uri.base.resolve(line.substring(0, splitPoint));
      Uri output = Uri.base.resolve(line.substring(splitPoint + 1));
      yield new TestDescription(
          Uri.base.resolve("/"), new File.fromUri(input), output: output);
    }
  }
}

class RunBatch extends Rastask {
  RunBatch(CustomCompiler compiler, Stopwatch wallClock, Options options)
      : super(compiler, wallClock, options);

  Future<Null> run() async {
    await setup();

    wallClock.reset();

    List<TestDescription> failures = <TestDescription>[];

    int count = 0;
    print("\n");

    Stream<TestDescription> tests;

    bool batchFromStdin = (globalOptions.input == null);
    if (batchFromStdin) {
      tests = readTestsFromStream(stdin);
    } else {
      Uri testUri = compiler.translateUri(null, globalOptions.input);
      File inputFile = new File.fromUri(testUri);
      tests = await inputFile.exists()
          ? readTestsFromStream(inputFile.openRead())
          : listTests(<Uri>[testUri], pattern: globalOptions.pattern);
    }

    await for (TestDescription description in tests) {
      assert(kernel.isInternalStateConsistent);
      count++;

      Uri output = description.output;
      output ??= description.uri.resolve("${description.uri.path}.dill");

      Options options = new Options(
          description.uri,
          output,
          dependenciesFile: null,
          generateLibrary: globalOptions.generateLibrary,
          isVerbose: globalOptions.isVerbose || batchFromStdin,
          isBatch: false,
          pattern: null);

      bool hasCrashed = false;
      try {
        await runOne(options);
      } catch (e, s) {
        kernel.recoverFromCrash();
        if (options.isVerbose) {
          print("${description.uri} failed: $e\n$s\n\n");
        }
        failures.add(description);
        hasCrashed = true;
      }

      if (batchFromStdin) {
        if (hasCrashed) {
          print(">>> TEST CRASH");
        } else if (!hasCompileTimeErrors) {
          print(">>> TEST OK");
        } else {
          print(">>> TEST FAIL");
        }
        stderr.write(">>> EOF STDERR\n");
      } else {
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
            "[${wallClock.elapsed} | --% | +$successes | -$failuresPadded ]");
      }
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

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.dart2js_test;

import 'dart:async' show
    Future,
    Stream;

import 'dart:io' show
    File,
    IOSink,
    Platform,
    exitCode;

import 'package:compiler/src/util/uri_extras.dart' show
    relativize;

import 'package:test.dart/status_file_parser.dart' show
    Expectation,
    ReadTestExpectations,
    TestExpectations;

import 'package:kernel/text/ast_to_text.dart' show
    Printer;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/repository.dart' show
    Repository;

import 'package:kernel/binary/loader.dart' show
    BinaryLoader;

import 'package:rasta/testing.dart' show
    TestDescription,
    listTests;

import 'package:rasta/src/rastask.dart' show
    Rastask,
    openWrite;

import 'package:rasta/src/options.dart' show
    Options;

const bool generateExpectations =
    const bool.fromEnvironment("generateExpectations");

const String dartExtension = ".dart";
const String kernelExtension = ".dill";

Future<Null> addRegressions(Map<Uri, Uri> tests, Uri temp) async {
  Stream<TestDescription> regressions = listTests(
      <Uri>[Uri.base.resolve("test/kernel/regression/")],
      pattern: dartExtension);
  await for (TestDescription regression in regressions) {
    tests[regression.uri] =
        temp.resolve("${regression.shortName}$kernelExtension");
  }
}

Future<Null> main() async {
  Stopwatch wallClock = new Stopwatch()..start();
  Rastask task = await Rastask.create(
      wallClock, <String>["--library", "${Platform.script}"]);
  await task.measureSubtask("runTests", () => runTests(task));
}

Future<Null> runTests(Rastask task) async {
  await task.setup();

  // When running via `testa.dart`, [Platform.script] is located in a temporary
  // directory.
  Uri temp = Platform.script;
  Map<Uri, Uri> tests = <Uri, Uri>{
    Uri.parse("dart:core"): temp.resolve("core$kernelExtension"),

    Uri.parse("package:compiler/src/dart2js$dartExtension"):
    temp.resolve("dart2js$kernelExtension"),
  };

  await addRegressions(tests, temp);

  Uri statusFile = Uri.base.resolve("test/rasta.status");
  TestExpectations expectations =
      await ReadTestExpectations(<String>[statusFile.toFilePath()], {});

  List<Uri> fails = <Uri>[];

  for (Uri source in tests.keys) {
    assert(task.kernel.isInternalStateConsistent);

    bool isRegression = source.path.contains("/regression/");

    print("Rastarizing $source");
    Uri dill = tests[source];
    File output = new File.fromUri(dill);
    await output.parent.create(recursive: true);

    Options options = new Options(
        source, dill, dependenciesFile: null,
        generateLibrary: isRegression ? isRegression : null,
        isVerbose: true, isBatch: false, pattern: null);

    ir.TreeNode node;
    Expectation outcome = Expectation.PASS;
    var error;
    StackTrace trace;
    try {
      node = await task.runOne(options);
    } catch (e, t) {
      outcome = Expectation.CRASH;
      task.kernel.recoverFromCrash();
      error = e;
      trace = t;
    }

    if (isRegression && outcome == Expectation.PASS) {
      outcome = await checkAgainstExpectations(node);
    }
    if (outcome == Expectation.PASS) {
      outcome = checkRoundTrip(dill);
    }

    Set<Expectation> expectedOutcomes = isRegression
        ? expectations.expectations(
            relativize(statusFile.resolve("."), source, false))
        : <Expectation>[Expectation.PASS].toSet();

    if (!expectedOutcomes.contains(outcome)) {
      print("$source: '$outcome' isn't one of '$expectedOutcomes'.");
      if (error != null) print(error);
      if (trace != null) print(trace);
      fails.add(source);
    }
  }
  if (fails.isNotEmpty) {
    exitCode = 1;
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(
        fails.map((Uri uri) => relativize(Uri.base, uri, false)), "\n  ");
    print("The following tests failed:\n  $buffer");
  }
}

/// Check that the textual representation of [node] matches expectation file
/// (golden file). The expectation file is found by appending `.txt` to the
/// location of the input library.
///
/// [node] must be either an [ir.Library] or an [ir.Program]. In the former
/// case, [node] is the input library. In the latter case, the input library is
/// the `main` method's library.
Future<Expectation> checkAgainstExpectations(ir.Node node) async {
  ir.Library library = (node is ir.Program) ? node.mainMethod.parent : node;
  Uri uri = library.importUri;

  StringBuffer buffer = new StringBuffer();
  new Printer(buffer).writeLibraryFile(library);
  File expectedFile = new File("${uri.toFilePath()}.txt");
  if (await expectedFile.exists()) {
    String expected = await expectedFile.readAsString();
    if (expected.trim() != "$buffer".trim()) {
      print("$uri doesn't match ${expectedFile.uri}");
      return Expectation.FAIL;
    }
  } else if (generateExpectations) {
    await openWrite(expectedFile.uri, (IOSink sink) {
      sink.writeln("$buffer".trim());
    });
    print("Generated ${expectedFile.uri}");
    return Expectation.FAIL;
  } else {
    print("""
Please create file ${expectedFile.path} with this content:
$buffer""");
    return Expectation.FAIL;
  }
  return Expectation.PASS;
}

/// Check that the serialized Kernel IR in [uri] can be deserialized.
Expectation checkRoundTrip(Uri uri) {
  print("Deserializing $uri");
  Repository repository = new Repository();
  ir.TreeNode programOrLibrary =
      new BinaryLoader(repository).loadProgramOrLibrary("$uri");
  Printer printer = new Printer(new StringBuffer());
  if (programOrLibrary is ir.Program) {
    printer.writeProgramFile(programOrLibrary);
  } else {
    printer.writeLibraryFile(programOrLibrary);
  }
  return Expectation.PASS;
}

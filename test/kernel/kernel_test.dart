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
    Platform;

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

Future<Null> addRegressions(Map<Uri, Uri> tests, Uri temp) async {
  Stream<TestDescription> regressions = listTests(
      <Uri>[Uri.base.resolve("test/kernel/regression/")], pattern: ".dart");
  await for (TestDescription regression in regressions) {
    tests[regression.uri] = temp.resolve("${regression.shortName}.bart");
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
    Uri.parse("dart:core"): temp.resolve("core.bart"),

    Uri.parse("package:compiler/src/dart2js.dart"):
    temp.resolve("dart2js.bart"),
  };

  await addRegressions(tests, temp);

  List<Uri> generated = <Uri>[];
  Map<Uri, Uri> mismatches = <Uri, Uri>{};

  for (Uri source in tests.keys) {
    bool isRegression = source.path.contains("/regression/");

    print("Rastarizing $source");
    Uri bart = tests[source];
    File output = new File.fromUri(bart);
    await output.parent.create(recursive: true);

    Options options = new Options(
        source, bart, dependenciesFile: null,
        generateLibrary: isRegression ? isRegression : null,
        isVerbose: true, isBatch: false, pattern: null);

    ir.TreeNode node = await task.runOne(options);

    if (isRegression) {
      await checkAgainstExpectations(node, generated, mismatches);
    }
    checkRoundTrip(bart);
  }
  if (generated.isNotEmpty) {
    throw "The following files were generated, "
        "please check them and re-run this test: ${generated}";
  }
  if (mismatches.isNotEmpty) {
    StringBuffer sb = new StringBuffer();
    mismatches.forEach((Uri test, Uri expectation) {
      sb.writeln("Output from '$test' doesn't match '$expectation'.");
    });
    throw "$sb";
  }
}

/// Check that the textual representation of [node] matches expectation file
/// (golden file). The expectation file is found by appending `.txt` to the
/// location of the input library.
///
/// [node] must be either an [ir.Library] or an [ir.Program]. In the former
/// case, [node] is the input library. In the latter case, the input library is
/// the `main` method's library.
Future<Null> checkAgainstExpectations(
    ir.Node node,
    List<Uri> generated,
    Map<Uri, Uri> mismatches) async {
  ir.Library library = (node is ir.Program) ? node.mainMethod.parent : node;
  Uri uri = library.importUri;

  StringBuffer buffer = new StringBuffer();
  new Printer(buffer).writeLibraryFile(library);
  File expectedFile = new File("${uri.toFilePath()}.txt");
  if (await expectedFile.exists()) {
    String expected = await expectedFile.readAsString();
    if (expected.trim() != "$buffer".trim()) {
      print("$uri doesn't match ${expectedFile.uri}");
      mismatches[uri] = expectedFile.uri;
    }
  } else if (generateExpectations) {
    await openWrite(expectedFile.uri, (IOSink sink) {
      sink.write("$buffer".trim());
    });
    generated.add(expectedFile.uri);
  } else {
    throw """
Please create file ${expectedFile.path} with this content:
$buffer""";
  }
}

/// Check that the serialized Kernel IR in [uri] can be deserialized.
void checkRoundTrip(Uri uri) {
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
}

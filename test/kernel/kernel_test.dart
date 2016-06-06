// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.dart2js_test;

import 'dart:async' show
    Future;

import 'dart:io' show
    File,
    Platform,
    Process,
    stderr;

import 'package:rasta/testing.dart' show
    dartSdk,
    startDart;

import '../../bin/rastak.dart' as rastak show main;

void addRegressions(Map<Uri, Uri> tests, Uri temp) {
  // TODO(ahe): Generate this list with listTests. Also, compare to golden
  // files.
  List<String> regressions = [
      "test/kernel/regression/issue_000001.dart",
      "test/kernel/regression/issue_000002.dart",
      // "test/kernel/regression/issue_000004.dart",
      "test/kernel/regression/issue_000006.dart",
  ];
  for (String regression in regressions) {
    tests[Uri.base.resolve(regression)] = temp.resolve("${regression}.bart");
  }
}

Future<Null> main() async {
  // When running via `testa.dart`, [Platform.script] is located in a temporary
  // directory.
  Uri temp = Platform.script;
  Map<Uri, Uri> tests = <Uri, Uri>{
    Uri.parse("dart:core"): temp.resolve("core.bart"),

    Uri.base.resolve("hello.dart"): temp.resolve("hello.bart"),

    Uri.parse("package:compiler/src/dart2js.dart"):
    temp.resolve("dart2js.bart"),
  };

  addRegressions(tests, temp);

  for (Uri source in tests.keys) {
    print("Rastarizing $source");
    Uri bart = tests[source];
    File output = new File.fromUri(bart);
    await output.parent.create(recursive: true);
    await rastak.main(<String>["$source", "$bart"], null);

    Uri textOutput = bart.resolve("${bart.path}.txt");
    print("Kernelizing $bart to $textOutput");
    Process process = await startDart(
        Uri.base.resolve("third_party/kernel/bin/dartk.dart"),
        <String>["--sdk=${dartSdk.toFilePath()}", "${bart.toFilePath()}"],
        const <String>[]);
    process.stdin.close();
    Future stdoutFuture =
        process.stdout.pipe(new File.fromUri(textOutput).openWrite());
    Future stderrFuture =
        process.stderr.listen((data) => stderr.add(data)).asFuture();
    int exitCode = await process.exitCode;
    await stdoutFuture;
    await stderrFuture;
    if (exitCode != 0) {
      throw "non-zero exit code ($exitCode) from rastak";
    }
  }
}

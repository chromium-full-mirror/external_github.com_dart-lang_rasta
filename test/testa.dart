// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.testa;

import 'dart:io' show
    Directory,
    File,
    FileSystemEntity,
    Platform,
    Process,
    stderr,
    stdout;

import 'dart:isolate' show
    ReceivePort;

import 'dart:async' show
    Future,
    Stream,
    StreamController,
    StreamSubscription;

main() async {
  final ReceivePort port = new ReceivePort();
  List<TestDescription> descriptions =
      await listTests(<Uri>[Platform.script.resolve(".")]).toList();
  descriptions.sort();
  StringBuffer sb = new StringBuffer();
  sb.writeln("library testa_combined;\n");
  sb.writeln("import '${Platform.script.path}' show runTests;\n");
  for (TestDescription description in descriptions) {
    sb.writeln(
        "import '${description.uri.path}' as ${description.shortName} "
        "show main;");
  }
  sb.writeln("\nvoid main() {");
  sb.writeln("  runTests(<String, Function> {");
  for (TestDescription description in descriptions) {
    String shortName = description.shortName;
    sb.writeln(
        '    "$shortName": $shortName.main,');
  }
  sb.writeln("  });");
  sb.write("}");

  Stopwatch sw = new Stopwatch()..start();
  Directory tmp = await Directory.systemTemp.createTemp();
  try {
    File generated = new File.fromUri(tmp.uri.resolve("generated.dart"));
    await generated.writeAsString("$sb", flush: true);
    print("==> ${generated.path} <==");
    print(numberedLines('$sb'));
    String packageConfig = Platform.packageConfig;
    if (packageConfig == null) {
      packageConfig = Platform.script.resolve(".packages").path;
    }
    Process process = await Process.start(Platform.resolvedExecutable,
        <String>["-c", "--packages=$packageConfig", generated.path]);
    process.stdin.close();
    Future stdoutFuture =
        process.stdout.listen((data) => stdout.add(data)).asFuture();
    Future stderrFuture =
        process.stderr.listen((data) => stderr.add(data)).asFuture();
    int exitCode = await process.exitCode;
    await stdoutFuture;
    await stderrFuture;
    if (exitCode != 0) {
      throw "non-zero exit code ($exitCode) from ${generated.path}";
    }
  } finally {
    tmp.delete(recursive: true);
  }
  sw.stop();
  print("Running tests took: ${sw.elapsed}");
  port.close();
}

Stream<TestDescription> listTests(List<Uri> testRoots) {
  StreamController<TestDescription> controller =
      new StreamController<TestDescription>();
  Map<Uri, StreamSubscription> subscriptions = <Uri, StreamSubscription>{};
  for (Uri testRootUri in testRoots) {
    subscriptions[testRootUri] = null;
    Directory testRoot = new Directory.fromUri(testRootUri);
    testRoot.exists().then((bool exists) {
      if (exists) {
        Stream<FileSystemEntity> stream =
            testRoot.list(recursive: true, followLinks: false);
        var subscription = stream.listen((FileSystemEntity entity) {
          TestDescription description = TestDescription.from(entity);
          if (description != null) {
            controller.add(description);
          }
        }, onError: (error, StackTrace trace) {
          controller.addError(error, trace);
        }, onDone: () {
          subscriptions.remove(testRootUri);
          if (subscriptions.isEmpty) {
            controller.close(); // TODO(ahe): catchError???
          }
        });
        subscriptions[testRootUri] = subscription;
      } else {
        controller.addError("$testRootUri isn't a directory");
        subscriptions.remove(testRootUri);
      }
      if (subscriptions.isEmpty) {
        controller.close(); // TODO(ahe): catchError???
      }
    });
  }
  return controller.stream;
}

Future<Null> runTests(Map<String, Function> tests) async {
  final ReceivePort port = new ReceivePort();
  for (String name in tests.keys) {
    print("Running test $name");
    await tests[name]();
  }
  port.close();
}

class TestDescription implements Comparable<TestDescription> {
  final File file;

  TestDescription(this.file);

  Uri get uri => file.uri;

  String get shortName {
    String baseName = uri.path.split("/").last;
    return baseName.substring(0, baseName.length - ".dart".length);
  }

  static TestDescription from(FileSystemEntity entity) {
    if (entity is File) {
      if ("${entity.uri}".endsWith("_test.dart")) {
        return new TestDescription(entity);
      }
    }
    return null;
  }

  int compareTo(TestDescription other) => "$uri".compareTo("${other.uri}");
}

String numberedLines(String text) {
  StringBuffer result = new StringBuffer();
  int lineNumber = 1;
  List<String> lines = splitLines(text);
  int pad = "${lines.length}".length;
  String fill = " " * pad;
  for (String line in lines) {
    String paddedLineNumber = "$fill$lineNumber";
    paddedLineNumber =
        paddedLineNumber.substring(paddedLineNumber.length - pad);
    result.write("$paddedLineNumber: $line");
    lineNumber++;
  }
  return '$result';
}

List<String> splitLines(String text) {
  return text.split(new RegExp('^', multiLine: true));
}

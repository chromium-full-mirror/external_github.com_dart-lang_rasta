// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.bench;

import 'dart:async' show
    Future;

import 'dart:io' show
    File;

import 'package:compiler/src/scanner/scanner.dart' show
    Scanner;

import 'package:compiler/src/tokens/token.dart' show
    Token;

import 'package:compiler/src/script.dart' show
    Script;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'package:compiler/src/parser/parser.dart' show
    Parser;

import 'package:compiler/src/options.dart' show
    ParserOptions;

import 'package:compiler/src/util/util.dart' show
    Link;

import 'bench_listener.dart' show
    BenchListener;

class BenchParserOptions extends ParserOptions {
  const BenchParserOptions();
  @override bool get enableGenericMethodSyntax => false;
}

class Bench {
  final CustomCompiler compiler;
  final Map<Uri, Token> tokensByUnit = <Uri, Token>{};
  final Map<Uri, Script> scriptsByUnit = <Uri, Script>{};
  final Map<Uri, Future<Script>> futureScriptsByUnit = <Uri, Future<Script>>{};
  final Map<Uri, Link<String>> parserEventsByUnit = <Uri, Link<String>>{};

  Bench(this.compiler);

  Future<Script> readUri(Uri uri) {
    return futureScriptsByUnit.putIfAbsent(
        uri, () => compiler.readScript(uri).then(
            (Script script) => scriptsByUnit[uri] = script));
  }

  Token scanCompilationUnit(Uri uri) {
    return tokensByUnit.putIfAbsent(
        uri, () => new Scanner(scriptsByUnit[uri].file).tokenize());
  }

  Parser getParser() {
    return new Parser(
        new BenchListener(), const BenchParserOptions(),
        asyncAwaitKeywordsEnabled: true);
  }

  Link<String> parseCompilationUnit(Uri uri) {
    return parserEventsByUnit.putIfAbsent(uri, () {
      Parser parser = getParser();
      parser.parseUnit(scanCompilationUnit(uri));
      BenchListener listener = parser.listener;
      return listener.messagesLink;
    });
  }

  void clear() {
    tokensByUnit.clear();
    parserEventsByUnit.clear();
  }
}

measure(String message, f) {
  Stopwatch clock = new Stopwatch()..start();
  var result = f();
  if (result is Future) {
    return result.then((value) {
      clock.stop();
      print("$message in ${clock.elapsed}");
      return result;
    });
  } else {
    clock.stop();
    print("$message in ${clock.elapsed}");
    return result;
  }
}

main(List<String> arguments) async {
  Stopwatch wallClock = new Stopwatch()..start();
  Uri deps = Uri.base.resolveUri(new Uri.file(arguments.single));
  List<String> compilerOptions = <String>['--verbose'];
  IoCompilerFactory factory = new IoCompilerFactory(
      Uri.base.resolve("dart_vm_standalone.json"), compilerOptions,
      <String, dynamic>{});
  (await factory.diagnostics)
      ..verbose = true
      ..showWarnings = true
      ..throwOnError = true
      ..throwOnErrorCount = 1;

  Bench bench = new Bench(await factory.compiler);

  List<Uri> uris = new List<Uri>.from(
      (await new File.fromUri(deps).readAsLines()).map(Uri.base.resolve));
  await measure(
      "Read ${uris.length} files", () => Future.forEach(uris, bench.readUri));
  for (int i = 0; i < 10; i++) {
    measure("Scanned ${uris.length} files", () {
      for (Uri uri in uris) {
        bench.scanCompilationUnit(uri);
      }
    });
    measure("Parsed ${uris.length} files", () {
      for (Uri uri in uris) {
        try {
          bench.parseCompilationUnit(uri);
        } catch (e) {
          print("$uri: $e");
        }
      }
    });
    StringBuffer eventBuffer = new StringBuffer();
    measure("String concat ${uris.length} files", () {
      for (Uri uri in uris) {
        try {
          Link<String> events = bench.parserEventsByUnit[uri];
          events.printOn(eventBuffer, ", ");
        } catch (e) {
          print("$uri: $e");
        }
      }
    });
    wallClock.stop();
    print("$eventBuffer".hashCode);
    print("Total time elapsed: ${wallClock.elapsed}");
    bench.clear();
  }
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.testing.rasta_chain;

import 'dart:async' show
    Future;

import 'dart:io' show
    File,
    Platform;

import 'package:kernel/ast.dart' show
    Program;

import 'package:kernel/repository.dart' show
    Repository;

import 'package:kernel/binary/loader.dart' show
    BinaryLoader;

import 'package:testing/testing.dart' show
    ChainContext,
    Result,
    Step,
    TestDescription;

import 'package:rasta/src/rastask.dart' show
    Rastask;

import 'package:rasta/src/options.dart' show
    Options;

const bool generateExpectations =
    const bool.fromEnvironment("generateExpectations");

const String kernelExtension = ".dill";

Future<Rastask> createTask([List<String> arguments]) async {
  arguments ??= const <String>[];
  Stopwatch wallClock = new Stopwatch()..start();
  Rastask task = await Rastask.create(wallClock,
      <String>["--library", "${Platform.script}"]..addAll(arguments));

  await task.measureSubtask("setup", task.setup);
  return task;
}

abstract class RastaContext extends ChainContext {
  Rastask get task;
  Uri get temp;
}

class RastaStep extends Step<TestDescription, Program, RastaContext> {
  final String prefix;

  /// When true, return a copy of the program (by loading it from serialized
  /// .dill file).
  final bool reload;

  const RastaStep(this.prefix, {this.reload: false});

  String get name => "rasta";

  Future<Result<Program>> run(
      TestDescription description, RastaContext context) async {
    Uri source = description.uri;
    Rastask task = context.task;

    assert(task.kernel.isInternalStateConsistent);

    print("Rastarizing $source");
    Uri dill = context.temp.resolve(
        "$prefix/${description.shortName}$kernelExtension");

    File output = new File.fromUri(dill);
    await output.parent.create(recursive: true);

    Options options = new Options(
        source, dill, dependenciesFile: null,
        generateLibrary: false,
        isVerbose: true, isBatch: false, pattern: null);

    Program program;
    try {
      program = await task.runOne(options);
    } catch (e, t) {
      task.kernel.recoverFromCrash();
      return crash(e, t);
    }

    if (reload) {
      // TODO(ahe): We need to load the serialized form as we otherwise
      // attempt to modify an unmodifiable list.
      Repository repository = new Repository();
      program = new BinaryLoader(repository).loadProgram(dill.toFilePath());
    }

    return pass(program);
  }
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_compiler_test;

import 'dart:async' show
    Future;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element,
    LibraryElement;

import 'package:rasta/compiler_factory.dart' show
    CompilerFactory;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'target_specification_test.dart' show
    targetSpecificationUri;

const bool isVerbose =
    const bool.fromEnvironment("verbose", defaultValue: false);

Future<Null> main() async {
  Stopwatch sw = new Stopwatch()..start();
  List<String> options = isVerbose ? <String>[] : <String>['--verbose'];
  CompilerFactory factory = new IoCompilerFactory(
      targetSpecificationUri, options, <String, dynamic>{});
  (await factory.diagnostics)
      ..showWarnings = isVerbose
      ..throwOnError = true;
  CustomCompiler compiler = await factory.compiler;

  Uri entryPoint = Uri.base.resolve(
      "third_party/dart-sdk/pkg/compiler/lib/src/dart2js.dart");

  await compiler.setupSdk();

  await compiler.setupPackages(entryPoint);

  Duration setupDuration = compiler.measurer.wallClock.elapsed;

  await compiler.libraryLoader.loadLibrary(entryPoint);

  for (LibraryElement library in compiler.libraryLoader.libraries) {
    library.forEachLocalMember((Element e) {
      if (e.isClass) {
        ClassElement cls = e;
        cls.ensureResolved(compiler.resolution);
        cls.forEachLocalMember((Element member) {
          compiler.analyzeElement(member);
        });
      } else {
        compiler.analyzeElement(e);
      }
    });
  }

  sw.stop();
  print("Took ${sw.elapsed}");

  printTimings(compiler.measurer, compiler.tasks, setupDuration);
}

// TODO(ahe): This is copied from dart2js and should be removed when we pull in
// the latest upstream version.
printTimings(measurer, tasks, setupDuration) {
  StringBuffer timings = new StringBuffer();
  timings.writeln("Timings:");
  Duration totalDuration = measurer.wallClock.elapsed;
  Duration asyncDuration = measurer.asyncWallClock.elapsed;
  Duration cumulatedDuration = Duration.ZERO;
  for (final task in tasks) {
    String running = task.isRunning ? "*" : "";
    Duration duration = task.duration;
    if (duration != Duration.ZERO) {
      cumulatedDuration += duration;
      timings.writeln(
          '    $running${task.name} took'
          ' ${duration.inMilliseconds}msec');
      for (String subtask in task.subtasks) {
        int subtime = task.getSubtaskTime(subtask);
        running = task.getSubtaskIsRunning(subtask) ? "*" : "";
        timings.writeln(
            '    $running${task.name} > $subtask took ${subtime}msec');
      }
    }
  }
  Duration unaccountedDuration =
      totalDuration - cumulatedDuration - setupDuration - asyncDuration;
  double percent = unaccountedDuration.inMilliseconds * 100
      / totalDuration.inMilliseconds;
  timings.write(
      '    Total compile-time ${totalDuration.inMilliseconds}msec;'
      ' setup ${setupDuration.inMilliseconds}msec;'
      ' async ${asyncDuration.inMilliseconds}msec;'
      ' unaccounted ${unaccountedDuration.inMilliseconds}msec'
      ' (${percent.toStringAsFixed(2)}%)');
  print("$timings");
}
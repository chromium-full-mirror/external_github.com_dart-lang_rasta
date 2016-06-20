// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_compiler;

import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;

import 'package:compiler/compiler_new.dart' show
    CompilerDiagnostics,
    CompilerInput,
    CompilerOutput;

import 'package:compiler/src/compiler.dart' show
    CompilerDiagnosticReporter,
    MakeBackendFuncion,
    MakeReporterFunction;

import 'package:compiler/src/patch_parser.dart' show
    PatchParserTask;

import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind;

import 'package:compiler/src/diagnostics/spannable.dart' show
    Spannable;

import 'package:compiler/src/mirrors_used.dart' show
    MirrorUsageAnalyzerTask;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'custom_compiler_options.dart' show
    CustomCompilerOptions;

import 'target_specification.dart' show
    TargetSpecification;

import 'custom_backend.dart' show
    CustomBackend;

import 'custom_patch_parser.dart' show
    CustomPatchParserTask;

import 'custom_mirror_usage_analyzer_task.dart' show
    CustomMirrorUsageAnalyzerTask;

class CustomCompiler extends CompilerImpl {
  final TargetSpecification target;

  CustomCompiler(
      CompilerInput input,
      CompilerOutput output,
      CompilerDiagnostics diagnostics,
      CustomCompilerOptions options,
      TargetSpecification target,
      {MakeBackendFuncion makeBackend,
       MakeReporterFunction makeReporter})
      : target = target,
        super(
          input, output, diagnostics, options,
          makeBackend: (CustomCompiler compiler) {
            return new CustomBackend(compiler, target);
          },
          makeReporter: makeReporter);

  @override PatchParserTask createPatchParserTask() {
    if (target.patches == null) {
      return new PatchParserTask(this, parsing.parserOptions);
    } else {
      return new CustomPatchParserTask(this);
    }
  }

  @override MirrorUsageAnalyzerTask createMirrorUsageAnalyzerTask() {
    return new CustomMirrorUsageAnalyzerTask(this);
  }

  void developerMessage(Spannable spannable, [String text]) {
    reporter.reportErrorMessage(
        spannable, MessageKind.GENERIC, {'text': text ?? ""});
  }

  void printVerboseTimings(Duration setupDuration) {
    // TODO(ahe): Copied from package:compiler/src/apiimpl.dart. Remove this
    // copy when merged with SDK version that provides this as a public method.
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
          String running = task.getSubtaskIsRunning(subtask) ? "*" : "";
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
    log("$timings");
  }

  void recoverFromCrash() {
    if (reporter is CompilerDiagnosticReporter) {
      CompilerDiagnosticReporter reporter = this.reporter;
      reporter.hasCrashed = false;
    }
    if (handler is FormattingDiagnosticHandler) {
      FormattingDiagnosticHandler handler = this.handler;
      handler.isAborting = false;
    }
    enqueuer.resolution.deferredTaskQueue.clear();
  }

  bool get isInternalStateConsistent {
    if (reporter is CompilerDiagnosticReporter) {
      CompilerDiagnosticReporter reporter = this.reporter;
      if (reporter.hasCrashed) {
        print("Reporter hasCrashed");
        return false;
      }
    }
    if (handler is FormattingDiagnosticHandler) {
      FormattingDiagnosticHandler handler = this.handler;
      if (handler.isAborting) {
        print("Reporter isAborting");
        return false;
      }
    }
    if (enqueuer.resolution.deferredTaskQueue.isNotEmpty) {
      print("Resolution deferredTaskQueue isn't empty");
      return false;
    }
    return true;
  }
}

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
}

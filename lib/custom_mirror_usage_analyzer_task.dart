// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_mirror_usage_analyzer_task;

import 'package:compiler/src/mirrors_used.dart' show
    MirrorUsageAnalyzer,
    MirrorUsageAnalyzerTask;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:compiler/src/elements/elements.dart' show
    Element,
    LibraryElement;

import 'package:compiler/src/tree/tree.dart' show
    NewExpression;

import 'package:compiler/src/resolution/tree_elements.dart' show
    TreeElements;

import 'custom_compiler.dart' show
    CustomCompiler;

/// Disables analysis of MirrorsUsed and thus disables warnings related to
/// MirrorsUsed.
class CustomMirrorUsageAnalyzerTask extends CompilerTask
    implements MirrorUsageAnalyzerTask {

  Set<LibraryElement> librariesWithUsage;

  MirrorUsageAnalyzer analyzer;

  CustomMirrorUsageAnalyzerTask(CustomCompiler compiler)
      : super(compiler);

  String get name => "custom mirror usage analyzer";

  void analyzeUsage(LibraryElement mainApp) {
  }

  bool hasMirrorUsage(Element element) => true;

  void validate(NewExpression node, TreeElements mapping) {
  }
}

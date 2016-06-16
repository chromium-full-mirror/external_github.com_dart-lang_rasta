// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.run_single;

import 'dart:async' show
    Future;

import 'package:kernel/ast.dart' as ir;

import '../custom_compiler.dart' show
    CustomCompiler;

import 'options.dart' show
    Options;

import 'rastask.dart' show
    Rastask;

class RunSingle extends Rastask {
  RunSingle(CustomCompiler compiler, Stopwatch wallClock, Options options)
      : super(compiler, wallClock, options);

  Future<ir.TreeNode> run() async {
    await setup(globalOptions.input);
    return runOne(globalOptions);
  }
}

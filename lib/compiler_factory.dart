// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.compiler_factory;

import 'dart:async' show
    Future;

import 'package:compiler/compiler_new.dart' show
    CompilerDiagnostics,
    CompilerInput,
    CompilerOutput;

import 'package:compiler/src/options.dart' show
    CompilerOptions;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'target_specification.dart' show
    TargetSpecification;

abstract class CompilerFactory {
  final Uri targetSpecificationLocation;
  final List<String> arguments;
  final Map<String, dynamic> environment;
  final Uri base;

  CompilerFactory(
      this.targetSpecificationLocation,
      this.arguments,
      this.environment,
      Uri base)
      : base = base ?? Uri.base;

  Future<CompilerInput> get input;

  Future<CompilerOutput> get output;

  Future<CompilerDiagnostics> get diagnostics;

  Future<TargetSpecification> get target;

  Future<CompilerOptions> get options;

  Future<CustomCompiler> get compiler;
}

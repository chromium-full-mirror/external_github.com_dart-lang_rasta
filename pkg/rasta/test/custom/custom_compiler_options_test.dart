// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_compiler_options_test;

import 'dart:async' show
    Future;

import 'package:expect/expect.dart' show
    Expect;

import 'package:rasta/custom_compiler_options.dart' show
    CustomCompilerOptions;

import 'package:rasta/target_specification.dart' show
    TargetSpecification;

import 'target_specification_test.dart' show
    getTestTargetSpecification;

Future<Null> main() async {
  TargetSpecification target = await getTestTargetSpecification();
  CustomCompilerOptions options = await getTestOptions(target: target);
  Expect.equals(target.libraryRoot, options.libraryRoot);
  Expect.equals(target.packageConfig, options.packageConfig);
  Expect.isTrue(options.verbose);
}

Future<CustomCompilerOptions> getTestOptions(
    {TargetSpecification target}) async {
  if (target == null) {
    target = await getTestTargetSpecification();
  }
  return CustomCompilerOptions.parse(
      <String>["--verbose"], base: Uri.base, targetSpecification: target,
      environment: <String, dynamic>{});
}

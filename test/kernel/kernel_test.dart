// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.test.kernel.kernel_test;

import 'dart:async' show
    Future;

import 'package:kernel/testing/kernel_chain.dart' show
    MatchExpectation,
    Print,
    SanityCheck;

import 'package:rasta/src/rastask.dart' show
    Rastask;

import 'package:rasta/testing/rasta_chain.dart' show
    RastaContext,
    RastaStep,
    createTask;

import 'package:testing/testing.dart' show
    Chain,
    Step,
    runMe;

class KernelContext extends RastaContext {
  final Rastask task;

  final Uri temp = Uri.base.resolve("tmp/");

  final List<Step> steps = const <Step>[
      const RastaStep("kernel"),
      const Print(),
      const SanityCheck(),
      const MatchExpectation(".txt"),
  ];

  KernelContext(this.task);
}

Future<KernelContext> createContext(Chain suite) async {
  return new KernelContext(await createTask());
}

main(List<String> arguments) => runMe(arguments, createContext);

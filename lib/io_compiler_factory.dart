// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.io_compiler_factory;

import 'dart:async' show
    EventSink,
    Future;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'package:compiler/compiler_new.dart' show
    CompilerInput,
    CompilerOutput;

import 'compiler_factory.dart' show
    CompilerFactory;

import 'target_specification.dart' show
    TargetSpecification,
    readStringFromUri;

import 'custom_compiler_options.dart' show
    CustomCompilerOptions;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'src/unimplemented.dart' show
    unimplemented;

abstract class IoCompilerFactoryMixin implements CompilerFactory {
  Future<TargetSpecification> targetFuture;

  Future<CustomCompilerOptions> optionsFuture;

  final Future<IoCompilerOutput> output =
      new Future<IoCompilerOutput>.value(new IoCompilerOutput());

  final Future<FormattingDiagnosticHandler> diagnostics =
      new Future<FormattingDiagnosticHandler>.value(
          new FormattingDiagnosticHandler()..verbose = true);

  Future<CompilerInput> get input async => (await diagnostics).provider;

  Future<TargetSpecification> get target {
    if (targetFuture != null) return targetFuture;
    return targetFuture = new Future<TargetSpecification>(() async {
      CompilerInput input = await this.input;
      String json = await readStringFromUri(
          input, targetSpecificationLocation);
      TargetSpecification target =
          TargetSpecification.decode(json, targetSpecificationLocation);
      await target.validate(input);
      return target;
    });
  }

  Future<CustomCompilerOptions> get options {
    if (optionsFuture != null) return optionsFuture;
    return new Future<CustomCompilerOptions>(() async {
      return CustomCompilerOptions.parse(
          arguments, base: base, targetSpecification: await target,
          environment: environment);
    });
  }

  Future<CustomCompiler> get compiler async {
    return new CustomCompiler(
        await input, await output, await diagnostics, await options,
       await target);
  }
}

class IoCompilerFactory extends CompilerFactory with IoCompilerFactoryMixin {
  IoCompilerFactory(
      Uri targetSpecificationLocation,
      List<String> arguments,
      Map<String, dynamic> environment,
      {Uri base})
      : super(targetSpecificationLocation, arguments, environment, base);
}

class IoCompilerOutput implements CompilerOutput {
  EventSink<String> createEventSink(String name, String extension) {
    return unimplemented;
  }
}

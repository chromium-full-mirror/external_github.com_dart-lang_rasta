// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastak;

import 'dart:io' show
    File,
    IOSink;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/binary/ast_to_binary.dart' show
    BinaryPrinter;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'package:rasta/custom_compiler.dart' show
    CustomCompiler;

import 'package:rasta/kernel.dart' show
    Kernel;

main(List<String> arguments, isolateArgument) async {
  Uri input = Uri.base.resolve(arguments[0]);
  Uri output = Uri.base.resolve(arguments[1]);
  IoCompilerFactory factory = new IoCompilerFactory(
      Uri.base.resolve("dart_vm_standalone.json"), <String>['--verbose'],
      <String, dynamic>{});
  CustomCompiler compiler = await factory.compiler;
  await compiler.setupSdk();

  await compiler.setupPackages(input);

  Kernel kernel = new Kernel(compiler);
  ir.Library library = await kernel.loadLibrary(input);
  kernel.processWorkQueue();

  IOSink sink = new File.fromUri(output).openWrite();
  try {
    new BinaryPrinter(sink).writeLibraryFile(library);
  } finally {
    await sink.close();
  }
  print("Wrote $output");
}

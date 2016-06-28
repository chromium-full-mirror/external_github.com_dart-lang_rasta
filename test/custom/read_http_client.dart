// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Helper program to test hangs when reading a file over HTTP using dart2js'
/// [CompilerInput].
library rasta.read_http_client;

import 'dart:async' show
    Future;

import 'package:compiler/compiler_new.dart' show
    CompilerInput;

import 'package:rasta/io_compiler_factory.dart' show
    IoCompilerFactory;

import 'target_specification_test.dart' show
    targetSpecificationUri;

Future<Null> main(List<String> arguments) async {
  IoCompilerFactory factory = new IoCompilerFactory(
      targetSpecificationUri, <String>[], <String, dynamic>{});
  CompilerInput input = await factory.input;

  Uri uri = Uri.parse(arguments.single);
  bool threw = true;
  try {
    await input.readFromUri(uri);
    threw = false;
  } catch (e) {
    print(e);
  }
  if (!threw) {
    throw "No exception from reading $uri";
  }
}

// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.target_specification_test;

import 'dart:async' show
    Future;

import 'package:compiler/src/source_file_provider.dart' show
    FormattingDiagnosticHandler;

import 'package:rasta/target_specification.dart';

const String targetSpecificationLocation =
    "pkg/rasta/test/custom/target_specification_test_data.json";

Uri get targetSpecificationUri => Uri.base.resolve(targetSpecificationLocation);

Future<Null> main() async {
  print(await getTestTargetSpecification());
}

Future<TargetSpecification> getTestTargetSpecification() async {
  FormattingDiagnosticHandler diagnosticHandler =
      new FormattingDiagnosticHandler();
  String json = await readStringFromUri(
      diagnosticHandler.provider, targetSpecificationUri);

  TargetSpecification target =
      TargetSpecification.decode(json, targetSpecificationUri);

  await target.validate(diagnosticHandler.provider);

  return target;
}

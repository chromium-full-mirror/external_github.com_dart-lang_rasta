// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library dart.core_patch;

import 'dart:_patch' show
    patch;

import 'dart:typed_data' show
    Uint16List,
    Uint32List;

import 'dart:_internal' as internal;

import 'dart:convert' show JSON;

import 'dart:async';

import 'dart:isolate';

part "../third_party/dart-sdk/runtime/lib/core_patch.dart";
part "../third_party/dart-sdk/runtime/lib/array_patch.dart";
part "../third_party/dart-sdk/runtime/lib/bool_patch.dart";
part "../third_party/dart-sdk/runtime/lib/date_patch.dart";
part "../third_party/dart-sdk/runtime/lib/double_patch.dart";
part "../third_party/dart-sdk/runtime/lib/errors_patch.dart";
part "../third_party/dart-sdk/runtime/lib/expando_patch.dart";
part "../third_party/dart-sdk/runtime/lib/function_patch.dart";
part "../third_party/dart-sdk/runtime/lib/identical_patch.dart";
part "../third_party/dart-sdk/runtime/lib/integers_patch.dart";
part "../third_party/dart-sdk/runtime/lib/invocation_mirror_patch.dart";
part "../third_party/dart-sdk/runtime/lib/map_patch.dart";
part "../third_party/dart-sdk/runtime/lib/null_patch.dart";
part "../third_party/dart-sdk/runtime/lib/object_patch.dart";
part "../third_party/dart-sdk/runtime/lib/regexp_patch.dart";
part "../third_party/dart-sdk/runtime/lib/resource_patch.dart";
part "../third_party/dart-sdk/runtime/lib/stopwatch_patch.dart";
part "../third_party/dart-sdk/runtime/lib/string_buffer_patch.dart";
part "../third_party/dart-sdk/runtime/lib/string_patch.dart";
part "../third_party/dart-sdk/runtime/lib/type_patch.dart";
part "../third_party/dart-sdk/runtime/lib/uri_patch.dart";
part "../third_party/dart-sdk/runtime/lib/array.dart";
part "../third_party/dart-sdk/runtime/lib/bigint.dart";
part "../third_party/dart-sdk/runtime/lib/double.dart";
part "../third_party/dart-sdk/runtime/lib/function.dart";
part "../third_party/dart-sdk/runtime/lib/growable_array.dart";
part "../third_party/dart-sdk/runtime/lib/immutable_map.dart";
part "../third_party/dart-sdk/runtime/lib/integers.dart";
part "../third_party/dart-sdk/runtime/lib/lib_prefix.dart";
part "../third_party/dart-sdk/runtime/lib/stacktrace.dart";
part "../third_party/dart-sdk/runtime/lib/weak_property.dart";

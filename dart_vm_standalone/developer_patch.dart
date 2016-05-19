// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library dart.developer_patch;

import 'dart:_patch' show
    patch;

import 'dart:isolate' show
    SendPort;

part '../third_party/dart-sdk/runtime/lib/developer.dart';
part '../third_party/dart-sdk/runtime/lib/profiler.dart';
part '../third_party/dart-sdk/runtime/lib/timeline.dart';

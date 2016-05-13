// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library dart.async_patch;

import 'dart:_patch' show
    patch;

import 'dart:_internal' show
    VMLibraryHooks;

part '../third_party/dart-sdk/runtime/lib/async_patch.dart';
part '../third_party/dart-sdk/runtime/lib/deferred_load_patch.dart';
part '../third_party/dart-sdk/runtime/lib/schedule_microtask_patch.dart';
part '../third_party/dart-sdk/runtime/lib/timer_patch.dart';

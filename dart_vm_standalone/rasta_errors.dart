// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.
library dart.core._rasta_errors;

// RastaK generates calls to these methods -- all backends must provide them
// in their patch for "dart:core".
//
// In the future, we could have a single `rasta_errors.dart` for all backends to
// ensure consistent error messages across all backends.
//
// But for now, we just want errors that are consistent with the VM, so these
// methods just reuse what is in the VM.

_unresolvedConstructorError(
    Object typeLiteral,
    String fullConstructorName,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      typeLiteral,
      fullConstructorName,
      _InvocationMirror._CONSTRUCTOR << _InvocationMirror._CALL_SHIFT,
      arguments,
      namedArguments,
      existingArgumentNames);
}

_malformedTypeError(String errorMessage) {
  return new _TypeError._create(null, null, null, errorMessage);
}

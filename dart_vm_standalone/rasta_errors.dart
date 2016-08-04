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
    Symbol fullConstructorName,
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

_unresolvedStaticGetterError(
    Object typeLiteral,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      typeLiteral,
      name,
      (_InvocationMirror._GETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._STATIC << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedStaticSetterError(
    Object typeLiteral,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      typeLiteral,
      name,
      (_InvocationMirror._SETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._STATIC << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedStaticMethodError(
    Object typeLiteral,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      typeLiteral,
      name,
      (_InvocationMirror._METHOD << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._STATIC << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedTopLevelGetterError(
    Object unused,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      unused,
      name,
      (_InvocationMirror._GETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._TOP_LEVEL << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedTopLevelSetterError(
    Object unused,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      unused,
      name,
      (_InvocationMirror._SETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._TOP_LEVEL << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedTopLevelMethodError(
    Object unused,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      unused,
      name,
      (_InvocationMirror._METHOD << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._TOP_LEVEL << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedSuperGetterError(
    Object receiver,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      receiver,
      name,
      (_InvocationMirror._GETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._SUPER << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedSuperSetterError(
    Object receiver,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      receiver,
      name,
      (_InvocationMirror._SETTER << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._SUPER << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_unresolvedSuperMethodError(
    Object receiver,
    Symbol name,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError._withType(
      receiver,
      name,
      (_InvocationMirror._METHOD << _InvocationMirror._TYPE_SHIFT) +
          (_InvocationMirror._SUPER << _InvocationMirror._CALL_SHIFT),
      arguments,
      namedArguments,
      existingArgumentNames);
}

_genericNoSuchMethod(
    Object receiver,
    Symbol methodName,
    List arguments,
    Map<Symbol, dynamic> namedArguments,
    List existingArgumentNames) {
  return new NoSuchMethodError(receiver, methodName, arguments, namedArguments,
      existingArgumentNames);
}

_malformedTypeError(String errorMessage) {
  return new _TypeError._create(null, null, null, errorMessage);
}

_fallThroughError() {
  return new FallThroughError();
}

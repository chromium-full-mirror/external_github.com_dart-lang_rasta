// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.error;

import "package:compiler/src/resolution/operators.dart" show
    AssignmentOperator,
    BinaryOperator,
    IncDecOperator,
    UnaryOperator;

import "package:compiler/src/universe/call_structure.dart" show
    CallStructure;

import "package:compiler/src/elements/elements.dart" show
    Element,
    ErroneousElement;

import "package:compiler/src/dart_types.dart" show
    DartType;

import "package:compiler/src/tree/tree.dart" show
    NewExpression,
    Node,
    NodeList,
    Operator,
    Send,
    SendSet;

import "package:compiler/src/universe/selector.dart" show
    Selector;

abstract class RastaError {
  void handleError(Node node);

  void errorInvalidBinary(
      Send node,
      ErroneousElement error,
      BinaryOperator operator,
      Node right,
      _) {
    return handleError(node);
  }

  void errorInvalidCompound(
      Send node,
      ErroneousElement error,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleError(node);
  }

  void errorInvalidCompoundIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleError(node);
  }

  void errorInvalidEquals(
      Send node,
      ErroneousElement error,
      Node right,
      _) {
    return handleError(node);
  }

  void errorInvalidGet(
      Send node,
      ErroneousElement error,
      _) {
    return handleError(node);
  }

  void errorInvalidIndex(
      Send node,
      ErroneousElement error,
      Node index,
      _) {
    return handleError(node);
  }

  void errorInvalidIndexPostfix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  void errorInvalidIndexPrefix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  void errorInvalidIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      Node rhs,
      _) {
    return handleError(node);
  }

  void errorInvalidInvoke(
      Send node,
      ErroneousElement error,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  void errorInvalidNotEquals(
      Send node,
      ErroneousElement error,
      Node right,
      _) {
    return handleError(node);
  }

  void errorInvalidPostfix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  void errorInvalidPrefix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  void errorInvalidSet(
      Send node,
      ErroneousElement error,
      Node rhs,
      _) {
    return handleError(node);
  }

  void errorInvalidSetIfNull(
      Send node,
      ErroneousElement error,
      Node rhs,
      _) {
    return handleError(node);
  }

  void errorInvalidUnary(
      Send node,
      UnaryOperator operator,
      ErroneousElement error,
      _) {
    return handleError(node);
  }

  void errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      DartType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleError(node);
  }

  void errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      _) {
    return handleError(node);
  }

  void errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      _) {
    return handleError(node);
  }

  void errorUnresolvedFieldInitializer(
      SendSet node,
      Element element,
      Node initializer,
      _) {
    return handleError(node);
  }

  void errorUnresolvedSuperConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  void errorUnresolvedThisConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  void errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, _) {
    return handleError(node);
  }
}

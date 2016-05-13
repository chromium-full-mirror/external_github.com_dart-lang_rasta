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

import 'package:kernel/ast.dart' as ir;

abstract class RastaError {
  ir.Throw handleError(Node node);

  ir.Throw errorInvalidBinary(
      Send node,
      ErroneousElement error,
      BinaryOperator operator,
      Node right,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidCompound(
      Send node,
      ErroneousElement error,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidCompoundIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidEquals(
      Send node,
      ErroneousElement error,
      Node right,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidGet(
      Send node,
      ErroneousElement error,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidIndex(
      Send node,
      ErroneousElement error,
      Node index,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidIndexPostfix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidIndexPrefix(
      Send node,
      ErroneousElement error,
      Node index,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidIndexSet(
      Send node,
      ErroneousElement error,
      Node index,
      Node rhs,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidInvoke(
      Send node,
      ErroneousElement error,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidNotEquals(
      Send node,
      ErroneousElement error,
      Node right,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidPostfix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidPrefix(
      Send node,
      ErroneousElement error,
      IncDecOperator operator,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidSet(
      Send node,
      ErroneousElement error,
      Node rhs,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidSetIfNull(
      Send node,
      ErroneousElement error,
      Node rhs,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidUnary(
      Send node,
      UnaryOperator operator,
      ErroneousElement error,
      _) {
    return handleError(node);
  }

  ir.Throw errorNonConstantConstructorInvoke(
      NewExpression node,
      Element element,
      DartType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleError(node);
  }

  ir.Throw errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      _) {
    return handleError(node);
  }

  ir.Throw errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      _) {
    return handleError(node);
  }

  ir.Throw errorUnresolvedFieldInitializer(
      SendSet node,
      Element element,
      Node initializer,
      _) {
    return handleError(node);
  }

  ir.Throw errorUnresolvedSuperConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  ir.Throw errorUnresolvedThisConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleError(node);
  }

  ir.Throw errorInvalidIndexSetIfNull(
      SendSet node, ErroneousElement error, Node index, Node rhs, _) {
    return handleError(node);
  }
}

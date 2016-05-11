// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.unresolved;

import 'package:kernel/ast.dart' as ir;

import "package:compiler/src/resolution/operators.dart" show
    AssignmentOperator,
    BinaryOperator,
    IncDecOperator,
    UnaryOperator;

import "package:compiler/src/universe/call_structure.dart" show
    CallStructure;

import "package:compiler/src/elements/elements.dart" show
    ConstructorElement,
    Element,
    MethodElement;

import "package:compiler/src/dart_types.dart" show
    DartType,
    InterfaceType;

import "package:compiler/src/tree/tree.dart" show
    NewExpression,
    Node,
    NodeList,
    Send;

import "package:compiler/src/universe/selector.dart" show
    Selector;

abstract class RastaUnresolved {
  ir.InvalidExpression handleUnresolved(Node node);

  ir.InvalidExpression visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element element,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedStaticSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterIndexPostfix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterIndexPrefix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperIndex(
      Send node,
      Element element,
      Node index,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperIndexPostfix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperIndexPrefix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperIndexSet(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterCompoundIndexSet(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterIndexPostfix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterIndexPrefix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedTopLevelSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperGetterIndexSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSetterIndexSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperIndexSetIfNull(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.InvalidExpression visitUnresolvedSuperSet(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }
}

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
  ir.Expression handleUnresolved(Node node);

  ir.Expression visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element element,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedStaticSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterIndexPostfix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterIndexPrefix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperIndex(
      Send node,
      Element element,
      Node index,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperIndexPostfix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperIndexPrefix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperIndexSet(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterCompoundIndexSet(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterIndexPostfix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterIndexPrefix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedTopLevelSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperGetterIndexSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSetterIndexSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperIndexSetIfNull(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  ir.Expression visitUnresolvedSuperSet(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }
}

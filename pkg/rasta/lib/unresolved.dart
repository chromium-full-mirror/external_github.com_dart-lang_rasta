// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.unresolved;

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
  void handleUnresolved(Node node);

  void visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element element,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedStaticSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGet(
      Send node,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterIndexPostfix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterIndexPrefix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperIndex(
      Send node,
      Element element,
      Node index,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperIndexPostfix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperIndexPrefix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperIndexSet(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetIfNull(
      Send node,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterCompoundIndexSet(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterIndexPostfix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterIndexPrefix(
      Send node,
      MethodElement indexFunction,
      Element element,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelGetterSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedTopLevelSetterSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperGetterIndexSetIfNull(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSetterIndexSetIfNull(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperIndexSetIfNull(
      Send node,
      Element element,
      Node index,
      Node rhs,
      _) {
    return handleUnresolved(node);
  }

  void visitUnresolvedSuperSet(Send node, Element element, Node rhs, _) {
    return handleUnresolved(node);
  }
}

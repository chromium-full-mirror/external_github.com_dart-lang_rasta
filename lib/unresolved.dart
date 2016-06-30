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
    AstElement,
    ConstructorElement,
    Element,
    ErroneousElement,
    FunctionElement,
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

import "kernel.dart" show
    Kernel;

ir.Arguments buildStringArgument(String argument) {
  return new ir.Arguments(<ir.Expression>[new ir.StringLiteral(argument)]);
}

ir.Arguments buildIntArgument(int argument) {
  return new ir.Arguments(<ir.Expression>[new ir.IntLiteral(argument)]);
}

abstract class RastaUnresolved {
  Kernel get kernel;

  // Implemented in KernelVisitor
  AstElement get currentElement;
  ir.Arguments buildArguments(NodeList arguments);

  // TODO(ahe): Delete this method.
  ir.InvalidExpression handleUnresolved(Node node);

  /// Throws a [NoSuchMethodError] corresponding to a call to
  /// [receiver].[memberName] with the arguments [callArguments].
  ///
  /// The exception object is built by calling [exceptionBuilder]. This should
  /// take the same arguments as the default constructor to [NoSuchMethodError],
  /// but the method itself may encode additional details about the call than
  /// is possible through the public interface of NoSuchMethodError.
  ///
  /// Note that [callArguments] are the arguments as they occur in the attempted
  /// call in user code -- they are not the arguments to [exceptionBuilder].
  ///
  /// If [candidateTarget] is given, it will provide the expected parameter
  /// names.
  ir.Expression buildThrowNoSuchMethodError(
      ir.Procedure exceptionBuilder,
      ir.Expression receiver,
      String memberName,
      ir.Arguments callArguments,
      [Element candidateTarget]) {
    ir.Expression memberNameArg = new ir.SymbolLiteral(memberName);
    ir.Expression positional = new ir.ListLiteral(callArguments.positional);
    ir.Expression named = new ir.MapLiteral(callArguments.named.map((e) {
      return new ir.MapEntry(new ir.SymbolLiteral(e.name), e.value);
    }).toList());
    ir.Expression existingArguments;
    if (candidateTarget is FunctionElement && !candidateTarget.isError) {
      List<ir.Expression> existingArgumentsList = <ir.Expression>[];
      candidateTarget.functionSignature.forEachParameter((param) {
        existingArgumentsList.add(new ir.StringLiteral(param.name));
      });
      existingArguments = new ir.ListLiteral(existingArgumentsList);
    } else {
      existingArguments = new ir.NullLiteral();
    }
    return new ir.Throw(new ir.StaticInvocation(
        exceptionBuilder,
        new ir.Arguments(<ir.Expression>[
          receiver,
          memberNameArg,
          positional,
          named,
          existingArguments
        ])));
  }

  ir.Expression buildThrowSingleArgumentError(
      ir.Procedure exceptionBuilder, String errorMessage) {
    return new ir.Throw(new ir.StaticInvocation(exceptionBuilder,
        new ir.Arguments(<ir.Expression>[new ir.StringLiteral(errorMessage)])));
  }

  ir.Expression visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      ErroneousElement element,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    // TODO(asgerf): The VM includes source information as part of the error
    //   message.  We could do the same when we add source maps.
    return buildThrowSingleArgumentError(kernel.getMalformedTypeErrorBuilder(),
        element.message);
  }

  ir.Expression visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      _) {
    ir.Expression receiver = new ir.TypeLiteral(kernel.interfaceTypeToIr(type));
    String methodName = node.send.selector != null
        ? '${node.send.selector}'
        : type.name;
    return buildThrowNoSuchMethodError(
        kernel.getUnresolvedConstructorBuilder(),
        receiver,
        methodName,
        buildArguments(arguments),
        constructor);
  }

  ir.InvalidExpression visitUnresolvedCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
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

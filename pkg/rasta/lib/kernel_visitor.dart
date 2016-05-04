// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.kernel_visitor;

import 'package:kernel/ast.dart' as ir;

import 'package:compiler/src/resolution/semantic_visitor.dart' show
    SemanticDeclarationResolvedMixin,
    SemanticDeclarationVisitor,
    SemanticSendResolvedMixin,
    SemanticSendVisitor,
    SemanticVisitor;

import 'package:compiler/src/resolution/send_resolver.dart' show
    DeclarationResolverMixin;

import 'package:compiler/src/elements/elements.dart' show
    ConstructorElement,
    Element,
    ErroneousElement,
    FieldElement,
    FunctionElement,
    InitializingFormalElement,
    LocalFunctionElement,
    LocalVariableElement,
    MethodElement,
    Name,
    ParameterElement,
    PrefixElement,
    TypeVariableElement;

import 'package:compiler/src/tree/tree.dart' show
    Assert,
    AsyncForIn,
    Await,
    Block,
    BreakStatement,
    Cascade,
    CascadeReceiver,
    CaseMatch,
    CatchBlock,
    Conditional,
    ConditionalUri,
    ContinueStatement,
    DoWhile,
    DottedName,
    EmptyStatement,
    Enum,
    Expression,
    ExpressionStatement,
    For,
    ForIn,
    FunctionDeclaration,
    FunctionExpression,
    Identifier,
    If,
    Label,
    LabeledStatement,
    Literal,
    LiteralBool,
    LiteralDouble,
    LiteralInt,
    LiteralList,
    LiteralMap,
    LiteralMapEntry,
    LiteralNull,
    LiteralString,
    LiteralSymbol,
    Metadata,
    NamedArgument,
    NewExpression,
    Node,
    NodeList,
    Operator,
    ParenthesizedExpression,
    RedirectingFactoryBody,
    Rethrow,
    Return,
    Send,
    SendSet,
    Statement,
    StringInterpolation,
    StringJuxtaposition,
    SwitchCase,
    SwitchStatement,
    SyncForIn,
    Throw,
    TryStatement,
    TypeAnnotation,
    TypeVariable,
    Typedef,
    VariableDefinitions,
    While,
    Yield;

import 'package:compiler/src/resolution/tree_elements.dart' show
    TreeElements;

import 'package:compiler/src/constants/expressions.dart' show
    BoolFromEnvironmentConstantExpression,
    ConstantExpression,
    ConstructedConstantExpression,
    IntFromEnvironmentConstantExpression,
    StringFromEnvironmentConstantExpression;

import 'package:compiler/src/dart_types.dart' show
    DartType,
    InterfaceType;

import 'package:compiler/src/universe/call_structure.dart' show
    CallStructure;

import 'package:compiler/src/universe/selector.dart' show
    Selector;

import 'package:compiler/src/resolution/operators.dart' show
    AssignmentOperator,
    BinaryOperator,
    IncDecOperator,
    UnaryOperator;

import 'package:compiler/src/diagnostics/spannable.dart' show
    Spannable;

import 'unsupported.dart' show
    Unsupported;

import 'unavailable.dart' show
    RastaUnavailable;

import 'unresolved.dart' show
    RastaUnresolved;

import 'error.dart' show
    RastaError;

class KernelVisitor extends Object
    with
        SemanticSendResolvedMixin,
        SemanticDeclarationResolvedMixin,
        DeclarationResolverMixin,
        RastaUnavailable,
        RastaUnresolved,
        RastaError
    implements
        SemanticVisitor, SemanticSendVisitor, SemanticDeclarationVisitor {
  TreeElements elements;
  final FunctionElement function;

  KernelVisitor(this.function, this.elements);

  KernelVisitor get sendVisitor => this;

  KernelVisitor get declVisitor => this;

  void handleUnresolved(Node node) {
    throw new Unsupported("Unresolved node: $node");
  }

  void handleError(Node node) {
    throw new Unsupported("Error node: $node");
  }

  void apply(Node node, _) {
    throw new Unsupported("Not implemented yet.");
  }

  void previsitDeferredAccess(Send node, PrefixElement prefix, _) {
    throw new Unsupported("Not implemented yet.");
  }

  internalError(Spannable spannable, String message) {
    throw new Unsupported("Not implemented yet.");
  }

  applyParameters(NodeList parameters, _) {
    throw new Unsupported("Not implemented yet.");
  }

  applyInitializers(FunctionExpression constructor, _) {
    throw new Unsupported("Not implemented yet.");
  }

  ir.TreeNode visitAssert(Assert node) {
    return handleUnsupported(node, "Assert");
  }

  ir.TreeNode visitAsyncForIn(AsyncForIn node) {
    return handleUnsupported(node, "AsyncForIn");
  }

  ir.TreeNode visitAwait(Await node) {
    return handleUnsupported(node, "Await");
  }

  ir.TreeNode visitBlock(Block node) {
    return handleUnsupported(node, "Block");
  }

  ir.TreeNode visitBreakStatement(BreakStatement node) {
    return handleUnsupported(node, "BreakStatement");
  }

  ir.TreeNode visitCascade(Cascade node) {
    return handleUnsupported(node, "Cascade");
  }

  ir.TreeNode visitCascadeReceiver(CascadeReceiver node) {
    return handleUnsupported(node, "CascadeReceiver");
  }

  ir.TreeNode visitCaseMatch(CaseMatch node) {
    return handleUnsupported(node, "CaseMatch");
  }

  ir.TreeNode visitCatchBlock(CatchBlock node) {
    return handleUnsupported(node, "CatchBlock");
  }

  ir.TreeNode visitConditional(Conditional node) {
    return handleUnsupported(node, "Conditional");
  }

  ir.TreeNode visitContinueStatement(ContinueStatement node) {
    return handleUnsupported(node, "ContinueStatement");
  }

  ir.TreeNode visitDoWhile(DoWhile node) {
    return handleUnsupported(node, "DoWhile");
  }

  ir.TreeNode visitEmptyStatement(EmptyStatement node) {
    return handleUnsupported(node, "EmptyStatement");
  }

  ir.TreeNode visitEnum(Enum node) {
    return handleUnsupported(node, "Enum");
  }

  ir.TreeNode visitExpressionStatement(ExpressionStatement node) {
    return handleUnsupported(node, "ExpressionStatement");
  }

  ir.TreeNode visitFor(For node) {
    return handleUnsupported(node, "For");
  }

  ir.TreeNode visitFunctionDeclaration(FunctionDeclaration node) {
    return handleUnsupported(node, "FunctionDeclaration");
  }

  ir.TreeNode visitIf(If node) {
    return handleUnsupported(node, "If");
  }

  ir.TreeNode visitLabel(Label node) {
    return handleUnsupported(node, "Label");
  }

  ir.TreeNode visitLabeledStatement(LabeledStatement node) {
    return handleUnsupported(node, "LabeledStatement");
  }

  ir.TreeNode visitLiteralBool(LiteralBool node) {
    return handleUnsupported(node, "LiteralBool");
  }

  ir.TreeNode visitLiteralDouble(LiteralDouble node) {
    return handleUnsupported(node, "LiteralDouble");
  }

  ir.TreeNode visitLiteralInt(LiteralInt node) {
    return handleUnsupported(node, "LiteralInt");
  }

  ir.TreeNode visitLiteralList(LiteralList node) {
    return handleUnsupported(node, "LiteralList");
  }

  ir.TreeNode visitLiteralMap(LiteralMap node) {
    return handleUnsupported(node, "LiteralMap");
  }

  ir.TreeNode visitLiteralMapEntry(LiteralMapEntry node) {
    return handleUnsupported(node, "LiteralMapEntry");
  }

  ir.TreeNode visitLiteralNull(LiteralNull node) {
    return handleUnsupported(node, "LiteralNull");
  }

  ir.TreeNode visitLiteralString(LiteralString node) {
    return handleUnsupported(node, "LiteralString");
  }

  ir.TreeNode visitLiteralSymbol(LiteralSymbol node) {
    return handleUnsupported(node, "LiteralSymbol");
  }

  ir.TreeNode visitMetadata(Metadata node) {
    return handleUnsupported(node, "Metadata");
  }

  ir.TreeNode visitNamedArgument(NamedArgument node) {
    return handleUnsupported(node, "NamedArgument");
  }

  ir.TreeNode visitOperator(Operator node) {
    return handleUnsupported(node, "Operator");
  }

  ir.TreeNode visitParenthesizedExpression(ParenthesizedExpression node) {
    // TODO(ahe): Do we need to emit the parentheses?
    node.expression.accept(this);
  }

  ir.TreeNode visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    return handleUnsupported(node, "RedirectingFactoryBody");
  }

  ir.TreeNode visitRethrow(Rethrow node) {
    return handleUnsupported(node, "Rethrow");
  }

  ir.TreeNode visitReturn(Return node) {
    return handleUnsupported(node, "Return");
  }

  ir.TreeNode visitStringInterpolation(StringInterpolation node) {
    return handleUnsupported(node, "StringInterpolation");
  }

  ir.TreeNode visitStringJuxtaposition(StringJuxtaposition node) {
    return handleUnsupported(node, "StringJuxtaposition");
  }

  ir.TreeNode visitSwitchCase(SwitchCase node) {
    return handleUnsupported(node, "SwitchCase");
  }

  ir.TreeNode visitSwitchStatement(SwitchStatement node) {
    return handleUnsupported(node, "SwitchStatement");
  }

  ir.TreeNode visitSyncForIn(SyncForIn node) {
    return handleUnsupported(node, "SyncForIn");
  }

  ir.TreeNode visitThrow(Throw node) {
    return handleUnsupported(node, "Throw");
  }

  ir.TreeNode visitTryStatement(TryStatement node) {
    return handleUnsupported(node, "TryStatement");
  }

  ir.TreeNode visitTypeAnnotation(TypeAnnotation node) {
    return handleUnsupported(node, "TypeAnnotation");
  }

  ir.TreeNode visitTypeVariable(TypeVariable node) {
    return handleUnsupported(node, "TypeVariable");
  }

  ir.TreeNode visitWhile(While node) {
    return handleUnsupported(node, "While");
  }

  ir.TreeNode visitYield(Yield node) {
    return handleUnsupported(node, "Yield");
  }

  ir.TreeNode visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "AbstractClassConstructorInvoke");
  }

  ir.TreeNode visitAbstractGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      _) {
    return handleUnsupported(node, "AbstractGetterDeclaration");
  }

  ir.TreeNode visitAbstractMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      _) {
    return handleUnsupported(node, "AbstractMethodDeclaration");
  }

  ir.TreeNode visitAbstractSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      _) {
    return handleUnsupported(node, "AbstractSetterDeclaration");
  }

  ir.TreeNode visitAs(Send node, Node expression, DartType type, _) {
    return handleUnsupported(node, "As");
  }

  ir.TreeNode visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return handleUnsupported(node, "Binary");
  }

  ir.TreeNode visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node,
      BoolFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "BoolFromEnvironmentConstructorInvoke");
  }

  ir.TreeNode visitClassTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralCompound");
  }

  ir.TreeNode visitClassTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ClassTypeLiteralGet");
  }

  ir.TreeNode visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralInvoke");
  }

  ir.TreeNode visitClassTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralPostfix");
  }

  ir.TreeNode visitClassTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralPrefix");
  }

  ir.TreeNode visitClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSet");
  }

  ir.TreeNode visitClassTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSetIfNull");
  }

  ir.TreeNode visitClosureDeclaration(
      FunctionExpression node,
      LocalFunctionElement closure,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "ClosureDeclaration");
  }

  ir.TreeNode visitCompoundIndexSet(
      SendSet node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "CompoundIndexSet");
  }

  ir.TreeNode visitConstConstructorInvoke(
      NewExpression node,
      ConstructedConstantExpression constant,
      _) {
    return handleUnsupported(node, "ConstConstructorInvoke");
  }

  ir.TreeNode visitConstantGet(Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ConstantGet");
  }

  ir.TreeNode visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstantInvoke");
  }

  ir.TreeNode visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstructorIncompatibleInvoke");
  }

  ir.TreeNode visitDynamicPropertyCompound(
      Send node,
      Node receiver,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertyCompound");
  }

  ir.TreeNode visitDynamicPropertyGet(Send node, Node receiver, Name name, _) {
    return handleUnsupported(node, "DynamicPropertyGet");
  }

  ir.TreeNode visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnsupported(node, "DynamicPropertyInvoke");
  }

  ir.TreeNode visitDynamicPropertyPostfix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicPropertyPostfix");
  }

  ir.TreeNode visitDynamicPropertyPrefix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicPropertyPrefix");
  }

  ir.TreeNode visitDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertySet");
  }

  ir.TreeNode visitDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertySetIfNull");
  }

  ir.TreeNode visitDynamicTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralCompound");
  }

  ir.TreeNode visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "DynamicTypeLiteralGet");
  }

  ir.TreeNode visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralInvoke");
  }

  ir.TreeNode visitDynamicTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralPostfix");
  }

  ir.TreeNode visitDynamicTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralPrefix");
  }

  ir.TreeNode visitDynamicTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralSet");
  }

  ir.TreeNode visitDynamicTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralSetIfNull");
  }

  ir.TreeNode visitEquals(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "Equals");
  }

  ir.TreeNode visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ExpressionInvoke");
  }

  ir.TreeNode visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "FactoryConstructorDeclaration");
  }

  ir.TreeNode visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "FactoryConstructorInvoke");
  }

  ir.TreeNode visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "FieldInitializer");
  }

  ir.TreeNode visitFinalLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableCompound");
  }

  ir.TreeNode visitFinalLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalLocalVariablePostfix");
  }

  ir.TreeNode visitFinalLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalLocalVariablePrefix");
  }

  ir.TreeNode visitFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableSet");
  }

  ir.TreeNode visitFinalLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableSetIfNull");
  }

  ir.TreeNode visitFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterCompound");
  }

  ir.TreeNode visitFinalParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalParameterPostfix");
  }

  ir.TreeNode visitFinalParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalParameterPrefix");
  }

  ir.TreeNode visitFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterSet");
  }

  ir.TreeNode visitFinalParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterSetIfNull");
  }

  ir.TreeNode visitFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalStaticFieldCompound");
  }

  ir.TreeNode visitFinalStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalStaticFieldPostfix");
  }

  ir.TreeNode visitFinalStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalStaticFieldPrefix");
  }

  ir.TreeNode visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "FinalStaticFieldSet");
  }

  ir.TreeNode visitFinalStaticFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalStaticFieldSetIfNull");
  }

  ir.TreeNode visitFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalSuperFieldCompound");
  }

  ir.TreeNode visitFinalSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalSuperFieldPostfix");
  }

  ir.TreeNode visitFinalSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalSuperFieldPrefix");
  }

  ir.TreeNode visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "FinalSuperFieldSet");
  }

  ir.TreeNode visitFinalSuperFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalSuperFieldSetIfNull");
  }

  ir.TreeNode visitFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldCompound");
  }

  ir.TreeNode visitFinalTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldPostfix");
  }

  ir.TreeNode visitFinalTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldPrefix");
  }

  ir.TreeNode visitFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldSet");
  }

  ir.TreeNode visitFinalTopLevelFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldSetIfNull");
  }

  ir.TreeNode visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    return handleUnsupported(node, "GenerativeConstructorDeclaration");
  }

  ir.TreeNode visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "GenerativeConstructorInvoke");
  }

  ir.TreeNode visitIfNotNullDynamicPropertyCompound(
      Send node,
      Node receiver,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyCompound");
  }

  ir.TreeNode visitIfNotNullDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyGet");
  }

  ir.TreeNode visitIfNotNullDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyInvoke");
  }

  ir.TreeNode visitIfNotNullDynamicPropertyPostfix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyPostfix");
  }

  ir.TreeNode visitIfNotNullDynamicPropertyPrefix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyPrefix");
  }

  ir.TreeNode visitIfNotNullDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySet");
  }

  ir.TreeNode visitIfNotNullDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySetIfNull");
  }

  ir.TreeNode visitIfNull(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "IfNull");
  }

  ir.TreeNode visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      InterfaceType type,
      _) {
    return handleUnsupported(node, "ImplicitSuperConstructorInvoke");
  }

  ir.TreeNode visitIndex(Send node, Node receiver, Node index, _) {
    return handleUnsupported(node, "Index");
  }

  ir.TreeNode visitIndexPostfix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPostfix");
  }

  ir.TreeNode visitIndexPrefix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPrefix");
  }

  ir.TreeNode visitIndexSet(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return handleUnsupported(node, "IndexSet");
  }

  ir.TreeNode visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "InitializingFormalDeclaration");
  }

  ir.TreeNode visitInstanceFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "InstanceFieldDeclaration");
  }

  ir.TreeNode visitInstanceGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceGetterDeclaration");
  }

  ir.TreeNode visitInstanceMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceMethodDeclaration");
  }

  ir.TreeNode visitInstanceSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceSetterDeclaration");
  }

  ir.TreeNode visitIntFromEnvironmentConstructorInvoke(
      NewExpression node,
      IntFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "IntFromEnvironmentConstructorInvoke");
  }

  ir.TreeNode visitIs(Send node, Node expression, DartType type, _) {
    return handleUnsupported(node, "Is");
  }

  ir.TreeNode visitIsNot(Send node, Node expression, DartType type, _) {
    return handleUnsupported(node, "IsNot");
  }

  ir.TreeNode visitLocalConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "LocalConstantDeclaration");
  }

  ir.TreeNode visitLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionCompound");
  }

  ir.TreeNode visitLocalFunctionDeclaration(
      FunctionExpression node,
      LocalFunctionElement function,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "LocalFunctionDeclaration");
  }

  ir.TreeNode visitLocalFunctionGet(
      Send node, LocalFunctionElement function, _) {
    return handleUnsupported(node, "LocalFunctionGet");
  }

  ir.TreeNode visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionIncompatibleInvoke");
  }

  ir.TreeNode visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionInvoke");
  }

  ir.TreeNode visitLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalFunctionPostfix");
  }

  ir.TreeNode visitLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalFunctionPrefix");
  }

  ir.TreeNode visitLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSet");
  }

  ir.TreeNode visitLocalFunctionSetIfNull(
      Send node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSetIfNull");
  }

  ir.TreeNode visitLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableCompound");
  }

  ir.TreeNode visitLocalVariableDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      Node initializer,
      _) {
    return handleUnsupported(node, "LocalVariableDeclaration");
  }

  ir.TreeNode visitLocalVariableGet(
      Send node, LocalVariableElement variable, _) {
    return handleUnsupported(node, "LocalVariableGet");
  }

  ir.TreeNode visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalVariableInvoke");
  }

  ir.TreeNode visitLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalVariablePostfix");
  }

  ir.TreeNode visitLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalVariablePrefix");
  }

  ir.TreeNode visitLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableSet");
  }

  ir.TreeNode visitLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableSetIfNull");
  }

  ir.TreeNode visitLogicalAnd(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "LogicalAnd");
  }

  ir.TreeNode visitLogicalOr(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "LogicalOr");
  }

  ir.TreeNode visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedInitializingFormalDeclaration");
  }

  ir.TreeNode visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedParameterDeclaration");
  }

  ir.TreeNode visitNot(Send node, Node expression, _) {
    return handleUnsupported(node, "Not");
  }

  ir.TreeNode visitNotEquals(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "NotEquals");
  }

  ir.TreeNode visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalInitializingFormalDeclaration");
  }

  ir.TreeNode visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalParameterDeclaration");
  }

  ir.TreeNode visitParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterCompound");
  }

  ir.TreeNode visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "ParameterDeclaration");
  }

  ir.TreeNode visitParameterGet(Send node, ParameterElement parameter, _) {
    return handleUnsupported(node, "ParameterGet");
  }

  ir.TreeNode visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ParameterInvoke");
  }

  ir.TreeNode visitParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ParameterPostfix");
  }

  ir.TreeNode visitParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ParameterPrefix");
  }

  ir.TreeNode visitParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterSet");
  }

  ir.TreeNode visitParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterSetIfNull");
  }

  ir.TreeNode visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      InterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      _) {
    return handleUnsupported(node, "RedirectingFactoryConstructorDeclaration");
  }

  ir.TreeNode visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      ConstructorElement effectiveTarget,
      InterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "RedirectingFactoryConstructorInvoke");
  }

  ir.TreeNode visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    return handleUnsupported(
        node, "RedirectingGenerativeConstructorDeclaration");
  }

  ir.TreeNode visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "RedirectingGenerativeConstructorInvoke");
  }

  ir.TreeNode visitStaticConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "StaticConstantDeclaration");
  }

  ir.TreeNode visitStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticFieldCompound");
  }

  ir.TreeNode visitStaticFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "StaticFieldDeclaration");
  }

  ir.TreeNode visitStaticFieldGet(Send node, FieldElement field, _) {
    return handleUnsupported(node, "StaticFieldGet");
  }

  ir.TreeNode visitStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFieldInvoke");
  }

  ir.TreeNode visitStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticFieldPostfix");
  }

  ir.TreeNode visitStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticFieldPrefix");
  }

  ir.TreeNode visitStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "StaticFieldSet");
  }

  ir.TreeNode visitStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "StaticFieldSetIfNull");
  }

  ir.TreeNode visitStaticFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "StaticFunctionDeclaration");
  }

  ir.TreeNode visitStaticFunctionGet(Send node, MethodElement function, _) {
    return handleUnsupported(node, "StaticFunctionGet");
  }

  ir.TreeNode visitStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFunctionIncompatibleInvoke");
  }

  ir.TreeNode visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFunctionInvoke");
  }

  ir.TreeNode visitStaticFunctionSet(
      Send node, MethodElement function, Node rhs, _) {
    return handleUnsupported(node, "StaticFunctionSet");
  }

  ir.TreeNode visitStaticGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "StaticGetterDeclaration");
  }

  ir.TreeNode visitStaticGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "StaticGetterGet");
  }

  ir.TreeNode visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticGetterInvoke");
  }

  ir.TreeNode visitStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "StaticGetterSet");
  }

  ir.TreeNode visitStaticGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticGetterSetterCompound");
  }

  ir.TreeNode visitStaticGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticGetterSetterPostfix");
  }

  ir.TreeNode visitStaticGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticGetterSetterPrefix");
  }

  ir.TreeNode visitStaticGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticGetterSetterSetIfNull");
  }

  ir.TreeNode visitStaticMethodCompound(
      Send node,
      MethodElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodCompound");
  }

  ir.TreeNode visitStaticMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodPostfix");
  }

  ir.TreeNode visitStaticMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodPrefix");
  }

  ir.TreeNode visitStaticMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetIfNull");
  }

  ir.TreeNode visitStaticMethodSetterCompound(
      Send node,
      MethodElement method,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetterCompound");
  }

  ir.TreeNode visitStaticMethodSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodSetterPostfix");
  }

  ir.TreeNode visitStaticMethodSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodSetterPrefix");
  }

  ir.TreeNode visitStaticMethodSetterSetIfNull(
      Send node,
      MethodElement method,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetterSetIfNull");
  }

  ir.TreeNode visitStaticSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "StaticSetterDeclaration");
  }

  ir.TreeNode visitStaticSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "StaticSetterGet");
  }

  ir.TreeNode visitStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticSetterInvoke");
  }

  ir.TreeNode visitStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "StaticSetterSet");
  }

  ir.TreeNode visitStringFromEnvironmentConstructorInvoke(
      NewExpression node,
      StringFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "StringFromEnvironmentConstructorInvoke");
  }

  ir.TreeNode visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperBinary");
  }

  ir.TreeNode visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperCompoundIndexSet");
  }

  ir.TreeNode visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperConstructorInvoke");
  }

  ir.TreeNode visitSuperEquals(
      Send node, FunctionElement function, Node argument, _) {
    return handleUnsupported(node, "SuperEquals");
  }

  ir.TreeNode visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldCompound");
  }

  ir.TreeNode visitSuperFieldFieldCompound(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldFieldCompound");
  }

  ir.TreeNode visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldFieldPostfix");
  }

  ir.TreeNode visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldFieldPrefix");
  }

  ir.TreeNode visitSuperFieldFieldSetIfNull(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldFieldSetIfNull");
  }

  ir.TreeNode visitSuperFieldGet(Send node, FieldElement field, _) {
    return handleUnsupported(node, "SuperFieldGet");
  }

  ir.TreeNode visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperFieldInvoke");
  }

  ir.TreeNode visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldPostfix");
  }

  ir.TreeNode visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldPrefix");
  }

  ir.TreeNode visitSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSet");
  }

  ir.TreeNode visitSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSetIfNull");
  }

  ir.TreeNode visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldSetterCompound");
  }

  ir.TreeNode visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldSetterPostfix");
  }

  ir.TreeNode visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldSetterPrefix");
  }

  ir.TreeNode visitSuperFieldSetterSetIfNull(
      Send node,
      FieldElement field,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldSetterSetIfNull");
  }

  ir.TreeNode visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterFieldCompound");
  }

  ir.TreeNode visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterFieldPostfix");
  }

  ir.TreeNode visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterFieldPrefix");
  }

  ir.TreeNode visitSuperGetterFieldSetIfNull(
      Send node,
      FunctionElement getter,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterFieldSetIfNull");
  }

  ir.TreeNode visitSuperGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "SuperGetterGet");
  }

  ir.TreeNode visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperGetterInvoke");
  }

  ir.TreeNode visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "SuperGetterSet");
  }

  ir.TreeNode visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterSetterCompound");
  }

  ir.TreeNode visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterSetterPostfix");
  }

  ir.TreeNode visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterSetterPrefix");
  }

  ir.TreeNode visitSuperGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterSetterSetIfNull");
  }

  ir.TreeNode visitSuperIndex(
      Send node, FunctionElement function, Node index, _) {
    return handleUnsupported(node, "SuperIndex");
  }

  ir.TreeNode visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPostfix");
  }

  ir.TreeNode visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPrefix");
  }

  ir.TreeNode visitSuperIndexSet(
      SendSet node,
      FunctionElement function,
      Node index,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperIndexSet");
  }

  ir.TreeNode visitSuperMethodCompound(
      Send node,
      FunctionElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodCompound");
  }

  ir.TreeNode visitSuperMethodGet(Send node, MethodElement method, _) {
    return handleUnsupported(node, "SuperMethodGet");
  }

  ir.TreeNode visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodIncompatibleInvoke");
  }

  ir.TreeNode visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodInvoke");
  }

  ir.TreeNode visitSuperMethodPostfix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodPostfix");
  }

  ir.TreeNode visitSuperMethodPrefix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodPrefix");
  }

  ir.TreeNode visitSuperMethodSet(
      Send node, MethodElement method, Node rhs, _) {
    return handleUnsupported(node, "SuperMethodSet");
  }

  ir.TreeNode visitSuperMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetIfNull");
  }

  ir.TreeNode visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetterCompound");
  }

  ir.TreeNode visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodSetterPostfix");
  }

  ir.TreeNode visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodSetterPrefix");
  }

  ir.TreeNode visitSuperMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetterSetIfNull");
  }

  ir.TreeNode visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperNotEquals");
  }

  ir.TreeNode visitSuperSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "SuperSetterGet");
  }

  ir.TreeNode visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperSetterInvoke");
  }

  ir.TreeNode visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "SuperSetterSet");
  }

  ir.TreeNode visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      _) {
    return handleUnsupported(node, "SuperUnary");
  }

  ir.TreeNode visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisConstructorInvoke");
  }

  ir.TreeNode visitThisGet(Identifier node, _) {
    return handleUnsupported(node, "ThisGet");
  }

  ir.TreeNode visitThisInvoke(
      Send node,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisInvoke");
  }

  ir.TreeNode visitThisPropertyCompound(
      Send node,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ThisPropertyCompound");
  }

  ir.TreeNode visitThisPropertyGet(Send node, Name name, _) {
    return handleUnsupported(node, "ThisPropertyGet");
  }

  ir.TreeNode visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnsupported(node, "ThisPropertyInvoke");
  }

  ir.TreeNode visitThisPropertyPostfix(
      Send node,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ThisPropertyPostfix");
  }

  ir.TreeNode visitThisPropertyPrefix(
      Send node,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ThisPropertyPrefix");
  }

  ir.TreeNode visitThisPropertySet(SendSet node, Name name, Node rhs, _) {
    return handleUnsupported(node, "ThisPropertySet");
  }

  ir.TreeNode visitThisPropertySetIfNull(Send node, Name name, Node rhs, _) {
    return handleUnsupported(node, "ThisPropertySetIfNull");
  }

  ir.TreeNode visitTopLevelConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "TopLevelConstantDeclaration");
  }

  ir.TreeNode visitTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelFieldCompound");
  }

  ir.TreeNode visitTopLevelFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "TopLevelFieldDeclaration");
  }

  ir.TreeNode visitTopLevelFieldGet(Send node, FieldElement field, _) {
    return handleUnsupported(node, "TopLevelFieldGet");
  }

  ir.TreeNode visitTopLevelFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelFieldInvoke");
  }

  ir.TreeNode visitTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelFieldPostfix");
  }

  ir.TreeNode visitTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelFieldPrefix");
  }

  ir.TreeNode visitTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "TopLevelFieldSet");
  }

  ir.TreeNode visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "TopLevelFieldSetIfNull");
  }

  ir.TreeNode visitTopLevelFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelFunctionDeclaration");
  }

  ir.TreeNode visitTopLevelFunctionGet(Send node, MethodElement function, _) {
    return handleUnsupported(node, "TopLevelFunctionGet");
  }

  ir.TreeNode visitTopLevelFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelFunctionIncompatibleInvoke");
  }

  ir.TreeNode visitTopLevelFunctionInvoke(
      Send node, MethodElement function, NodeList arguments,
      CallStructure callStructure, _) {
    return handleUnsupported(node, "TopLevelFunctionInvoke");
  }

  ir.TreeNode visitTopLevelFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelFunctionSet");
  }

  ir.TreeNode visitTopLevelGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelGetterDeclaration");
  }

  ir.TreeNode visitTopLevelGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "TopLevelGetterGet");
  }

  ir.TreeNode visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelGetterInvoke");
  }

  ir.TreeNode visitTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSet");
  }

  ir.TreeNode visitTopLevelGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterCompound");
  }

  ir.TreeNode visitTopLevelGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterPostfix");
  }

  ir.TreeNode visitTopLevelGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterPrefix");
  }

  ir.TreeNode visitTopLevelGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterSetIfNull");
  }

  ir.TreeNode visitTopLevelMethodCompound(
      Send node,
      FunctionElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodCompound");
  }

  ir.TreeNode visitTopLevelMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodPostfix");
  }

  ir.TreeNode visitTopLevelMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodPrefix");
  }

  ir.TreeNode visitTopLevelMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetIfNull");
  }

  ir.TreeNode visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterCompound");
  }

  ir.TreeNode visitTopLevelMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterPostfix");
  }

  ir.TreeNode visitTopLevelMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterPrefix");
  }

  ir.TreeNode visitTopLevelMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterSetIfNull");
  }

  ir.TreeNode visitTopLevelSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelSetterDeclaration");
  }

  ir.TreeNode visitTopLevelSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "TopLevelSetterGet");
  }

  ir.TreeNode visitTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelSetterInvoke");
  }

  ir.TreeNode visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelSetterSet");
  }

  ir.TreeNode visitTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralCompound");
  }

  ir.TreeNode visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralGet");
  }

  ir.TreeNode visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralInvoke");
  }

  ir.TreeNode visitTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralPostfix");
  }

  ir.TreeNode visitTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralPrefix");
  }

  ir.TreeNode visitTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSet");
  }

  ir.TreeNode visitTypeVariableTypeLiteralSetIfNull(
      Send node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSetIfNull");
  }

  ir.TreeNode visitTypedefTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralCompound");
  }

  ir.TreeNode visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "TypedefTypeLiteralGet");
  }

  ir.TreeNode visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralInvoke");
  }

  ir.TreeNode visitTypedefTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralPostfix");
  }

  ir.TreeNode visitTypedefTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralPrefix");
  }

  ir.TreeNode visitTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSet");
  }

  ir.TreeNode visitTypedefTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSetIfNull");
  }

  ir.TreeNode visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return handleUnsupported(node, "Unary");
  }

  ir.TreeNode visitConditionalUri(ConditionalUri node) {
    return handleUnsupported(node, "ConditionalUri");
  }

  ir.TreeNode visitDottedName(DottedName node) {
    return handleUnsupported(node, "DottedName");
  }

  ir.TreeNode visitForIn(ForIn node) {
    return handleUnsupported(node, "ForIn");
  }

  ir.TreeNode visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return handleUnsupported(node, "IndexSetIfNull");
  }

  ir.TreeNode visitSuperIndexSetIfNull(
      SendSet node, MethodElement getter, MethodElement setter, Node index,
      Node rhs, _) {
    return handleUnsupported(node, "SuperIndexSetIfNull");
  }

  ir.TreeNode handleUnsupported(Node node, String name) {
    // TODO(ahe): Do this:
    // throw new Unsupported("Kernel IR not yet implemented for '$name'.");
    return new ir.Throw(
        new ir.StringLiteral("Kernel IR not yet implemented for '$name'."));
  }
}

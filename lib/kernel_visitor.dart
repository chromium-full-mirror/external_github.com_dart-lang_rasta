// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.kernel_visitor;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/accessors.dart' show
    Accessor,
    PropertyAccessor,
    VariableAccessor;

import 'package:compiler/src/resolution/semantic_visitor.dart' show
    BaseImplementationOfCompoundsMixin,
    BaseImplementationOfLocalsMixin,
    BaseImplementationOfStaticsMixin,
    CompoundGetter,
    CompoundSetter,
    CompoundKind,
    CompoundRhs,
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
    FieldElement,
    FunctionElement,
    FunctionSignature,
    InitializingFormalElement,
    JumpTarget,
    LocalElement,
    LocalFunctionElement,
    LocalParameterElement,
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
    StringInterpolationPart,
    StringJuxtaposition,
    SwitchCase,
    SwitchStatement,
    SyncForIn,
    Throw,
    TryStatement,
    TypeAnnotation,
    TypeVariable,
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

import 'kernel.dart' show
    Kernel;

class KernelVisitor extends Object
    with
        SemanticSendResolvedMixin,
        BaseImplementationOfStaticsMixin,
        BaseImplementationOfLocalsMixin,
        BaseImplementationOfCompoundsMixin,
        SemanticDeclarationResolvedMixin,
        DeclarationResolverMixin,
        RastaUnavailable,
        RastaUnresolved,
        RastaError
    implements
        SemanticVisitor, SemanticSendVisitor, SemanticDeclarationVisitor {
  TreeElements elements;
  final FunctionElement function;
  final Kernel kernel;
  List<ir.Statement> currentStatements;

  final Map<JumpTarget, ir.LabeledStatement> continueTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<JumpTarget, ir.LabeledStatement> breakTargets =
      <JumpTarget, ir.LabeledStatement>{};

  KernelVisitor(this.function, this.elements, this.kernel);

  KernelVisitor get sendVisitor => this;

  KernelVisitor get declVisitor => this;

  @override
  ir.InvalidExpression handleUnresolved(Node node) {
    return new ir.InvalidExpression();
  }

  @override
  void handleError(Node node) {
    throw new Unsupported("Error node: $node");
  }

  @override
  void apply(Node node, _) {
    throw new Unsupported("Not implemented yet.");
  }

  @override
  void previsitDeferredAccess(Send node, PrefixElement prefix, _) {
    throw new Unsupported("Not implemented yet.");
  }

  @override
  internalError(Spannable spannable, String message) {
    throw new Unsupported(message);
  }

  @override
  applyParameters(NodeList parameters, _) {
    throw new Unsupported("Not implemented yet.");
  }

  @override
  applyInitializers(FunctionExpression constructor, _) {
    throw new Unsupported("Not implemented yet.");
  }

  @override
  ir.AssertStatement visitAssert(Assert node) {
    return new ir.AssertStatement(
        node.condition.accept(this),
        node.message?.accept(this));
  }

  @override
  ir.Throw visitAsyncForIn(AsyncForIn node) {
    return handleUnsupported(node, "AsyncForIn");
  }

  @override
  ir.Throw visitAwait(Await node) {
    return handleUnsupported(node, "Await");
  }

  @override
  ir.Block visitBlock(Block node) {
    return generateStatementInBlock(node);
  }

  ir.Block generateStatementInBlock(Statement node) {
    if (node == null) return null;
    List<ir.Statement> oldStatements = currentStatements;
    currentStatements = <ir.Statement>[];
    try {
      if (node is Block) {
        for (Node statement in node.statements.nodes) {
          ir.Statement irNode = statement.accept(this);
          if (irNode != null) {
            currentStatements.add(irNode);
          }
        }
      } else {
        ir.Statement irNode = node.accept(this);
        if (irNode != null) {
          currentStatements.add(irNode);
        }
      }
      return new ir.Block(currentStatements);
    } finally {
      currentStatements = oldStatements;
    }
  }

  @override
  ir.BreakStatement visitBreakStatement(BreakStatement node) {
    return new ir.BreakStatement(getBreakTarget(elements.getTargetOf(node)));
  }

  @override
  ir.Throw visitCascade(Cascade node) {
    return handleUnsupported(node, "Cascade");
  }

  @override
  ir.Throw visitCascadeReceiver(CascadeReceiver node) {
    return handleUnsupported(node, "CascadeReceiver");
  }

  @override
  ir.Throw visitCaseMatch(CaseMatch node) {
    return handleUnsupported(node, "CaseMatch");
  }

  @override
  ir.Throw visitCatchBlock(CatchBlock node) {
    return handleUnsupported(node, "CatchBlock");
  }

  @override
  ir.ConditionalExpression visitConditional(Conditional node) {
    return new ir.ConditionalExpression(
        node.condition.accept(this),
        node.thenExpression.accept(this),
        node.elseExpression.accept(this));
  }

  @override
  ir.BreakStatement visitContinueStatement(ContinueStatement node) {
    return new ir.BreakStatement(getContinueTarget(elements.getTargetOf(node)));
  }

  @override
  ir.Statement visitDoWhile(DoWhile node) {
    ir.Statement body = generateStatementInBlock(node.body);
    ir.Expression condition = node.condition?.accept(this);

    // TODO(ahe): Unify jump target handling between For, While, and Do.
    JumpTarget jumpTarget = elements.getTargetDefinition(node);

    if (jumpTarget != null && jumpTarget.isContinueTarget) {
      ir.LabeledStatement continueTarget = getContinueTarget(jumpTarget);
      continueTarget.body = body;
      body.parent = continueTarget;
      body = continueTarget;
    }

    ir.Statement result = new ir.DoStatement(body, condition);

    if (jumpTarget != null && jumpTarget.isBreakTarget) {
      ir.LabeledStatement breakTarget = getBreakTarget(jumpTarget);
      breakTarget.body = result;
      result.parent = breakTarget;
      result = breakTarget;
    }

    return result;
  }

  @override
  ir.EmptyStatement visitEmptyStatement(EmptyStatement node) {
    return new ir.EmptyStatement();
  }

  @override
  ir.Throw visitEnum(Enum node) {
    return handleUnsupported(node, "Enum");
  }

  @override
  ir.ExpressionStatement visitExpressionStatement(ExpressionStatement node) {
    return new ir.ExpressionStatement(node.expression.accept(this));
  }

  ir.LabeledStatement getBreakTarget(JumpTarget target) {
    return breakTargets.putIfAbsent(
        target, () => new ir.LabeledStatement(null));
  }

  ir.LabeledStatement getContinueTarget(JumpTarget target) {
    return continueTargets.putIfAbsent(
        target, () => new ir.LabeledStatement(null));
  }

  @override
  ir.Statement visitFor(For node) {
    VariableDefinitions initializers =
        node.initializer?.asVariableDefinitions();
    ir.Expression initializer;
    List<ir.VariableDeclaration> variables;
    if (initializers != null) {
      ir.Block block = generateStatementInBlock(initializers);
      variables = new List<ir.VariableDeclaration>.from(block.statements);
    } else {
      if (node.initializer != null) {
        initializer = node.initializer.accept(this);
      }
      variables = const <ir.VariableDeclaration>[];
    }
    ir.Expression condition = node.condition?.accept(this);
    List<ir.Expression> updates = <ir.Expression>[];
    for (Expression update in node.update) {
      updates.add(update.accept(this));
    }
    ir.Statement body = generateStatementInBlock(node.body);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);

    if (jumpTarget != null && jumpTarget.isContinueTarget) {
      ir.LabeledStatement continueTarget = getContinueTarget(jumpTarget);
      continueTarget.body = body;
      body.parent = continueTarget;
      body = continueTarget;
    }
    ir.ForStatement forStatement = new ir.ForStatement(
        variables, condition, updates, body);
    ir.Statement result = forStatement;
    if (jumpTarget != null && jumpTarget.isBreakTarget) {
      ir.LabeledStatement breakTarget = getBreakTarget(jumpTarget);
      breakTarget.body = result;
      result.parent = breakTarget;
      result = breakTarget;
    }
    if (initializer != null) {
      result = new ir.Block(<ir.Statement>[
          new ir.ExpressionStatement(initializer), result]);
    }
    return result;
  }

  @override
  ir.ExpressionStatement visitFunctionDeclaration(FunctionDeclaration node) {
    return handleUnsupportedStatement(node, "FunctionDeclaration");
  }

  @override
  ir.IfStatement visitIf(If node) {
    return new ir.IfStatement(
        node.condition.accept(this),
        generateStatementInBlock(node.thenPart),
        generateStatementInBlock(node.elsePart));
  }

  @override
  ir.Throw visitLabel(Label node) {
    return handleUnsupported(node, "Label");
  }

  @override
  ir.LabeledStatement visitLabeledStatement(LabeledStatement node) {
    ir.LabeledStatement result = new ir.LabeledStatement(null);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    if (jumpTarget != null) {
      assert(breakTargets[jumpTarget] == null);
      breakTargets[jumpTarget] = result;
      assert(continueTargets[jumpTarget] == null);
      continueTargets[jumpTarget] = result;
    }

    ir.Statement body = generateStatementInBlock(node.statement);

    result.body = body;
    body.parent = result;
    return result;
  }

  @override
  ir.BoolLiteral visitLiteralBool(LiteralBool node) {
    return new ir.BoolLiteral(node.value);
  }

  @override
  ir.DoubleLiteral visitLiteralDouble(LiteralDouble node) {
    return new ir.DoubleLiteral(node.value);
  }

  @override
  ir.IntLiteral visitLiteralInt(LiteralInt node) {
    return new ir.IntLiteral(node.value);
  }

  @override
  ir.ListLiteral visitLiteralList(LiteralList node) {
    // TODO(ahe): Type arguments.
    List<ir.Expression> elements = <ir.Expression>[];
    for (Expression element in node.elements.nodes) {
      elements.add(element.accept(this));
    }
    return new ir.ListLiteral(elements)
        // TODO(ahe): Constness should be validated.
        ..isConst = node.isConst;
  }

  @override
  ir.MapLiteral visitLiteralMap(LiteralMap node) {
    // TODO(ahe): Type arguments.
    List<ir.MapEntry> entries = <ir.MapEntry>[];
    for (LiteralMapEntry entry in node.entries.nodes) {
      entries.add(
          new ir.MapEntry(entry.key.accept(this), entry.value.accept(this)));
    }
    return new ir.MapLiteral(entries)
        // TODO(ahe): Constness should be validated.
        ..isConst = node.isConst;
  }

  @override
  ir.Throw visitLiteralMapEntry(LiteralMapEntry node) {
    return handleUnsupported(node, "LiteralMapEntry");
  }

  @override
  ir.NullLiteral visitLiteralNull(LiteralNull node) {
    return new ir.NullLiteral();
  }

  @override
  ir.StringLiteral visitLiteralString(LiteralString node) {
    return new ir.StringLiteral(node.dartString.slowToString());
  }

  @override
  ir.Throw visitLiteralSymbol(LiteralSymbol node) {
    return handleUnsupported(node, "LiteralSymbol");
  }

  @override
  ir.Throw visitMetadata(Metadata node) {
    return handleUnsupported(node, "Metadata");
  }

  @override
  ir.Throw visitNamedArgument(NamedArgument node) {
    return handleUnsupported(node, "NamedArgument");
  }

  @override
  ir.Throw visitOperator(Operator node) {
    return handleUnsupported(node, "Operator");
  }

  @override
  ir.Expression visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  ir.Throw visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    return handleUnsupported(node, "RedirectingFactoryBody");
  }

  @override
  ir.Throw visitRethrow(Rethrow node) {
    return handleUnsupported(node, "Rethrow");
  }

  @override
  ir.ReturnStatement visitReturn(Return node) {
    return new ir.ReturnStatement(node.expression?.accept(this));
  }

  @override
  ir.StringConcatenation visitStringInterpolation(StringInterpolation node) {
    List<ir.Expression> expressions = <ir.Expression>[];
    expressions.add(node.string.accept(this));
    for (StringInterpolationPart part in node.parts) {
      expressions.add(part.expression.accept(this));
      expressions.add(part.string.accept(this));
    }
    return new ir.StringConcatenation(expressions);
  }

  @override
  ir.StringConcatenation visitStringJuxtaposition(StringJuxtaposition node) {
    return new ir.StringConcatenation(
        <ir.Expression>[node.first.accept(this), node.second.accept(this)]);
  }

  @override
  ir.Throw visitSwitchCase(SwitchCase node) {
    return handleUnsupported(node, "SwitchCase");
  }

  @override
  ir.ExpressionStatement visitSwitchStatement(SwitchStatement node) {
    return handleUnsupportedStatement(node, "SwitchStatement");
  }

  @override
  ir.ExpressionStatement visitSyncForIn(SyncForIn node) {
    return handleUnsupportedStatement(node, "SyncForIn");
  }

  @override
  ir.Throw visitThrow(Throw node) {
    return new ir.Throw(node?.expression?.accept(this));
  }

  @override
  ir.ExpressionStatement visitTryStatement(TryStatement node) {
    return handleUnsupportedStatement(node, "TryStatement");
  }

  @override
  ir.Throw visitTypeAnnotation(TypeAnnotation node) {
    return handleUnsupported(node, "TypeAnnotation");
  }

  @override
  ir.Throw visitTypeVariable(TypeVariable node) {
    return handleUnsupported(node, "TypeVariable");
  }

  @override
  ir.Statement visitWhile(While node) {
    ir.Expression condition = node.condition?.accept(this);

    ir.Statement body = generateStatementInBlock(node.body);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);

    if (jumpTarget != null && jumpTarget.isContinueTarget) {
      ir.LabeledStatement continueTarget = getContinueTarget(jumpTarget);
      continueTarget.body = body;
      body.parent = continueTarget;
      body = continueTarget;
    }

    ir.Statement result = new ir.WhileStatement(condition, body);

    if (jumpTarget != null && jumpTarget.isBreakTarget) {
      ir.LabeledStatement breakTarget = getBreakTarget(jumpTarget);
      breakTarget.body = result;
      result.parent = breakTarget;
      result = breakTarget;
    }

    return result;
  }

  @override
  ir.ExpressionStatement visitYield(Yield node) {
    return handleUnsupportedStatement(node, "Yield");
  }

  @override
  ir.Throw visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "AbstractClassConstructorInvoke");
  }

  @override
  ir.Throw visitAbstractGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      _) {
    return handleUnsupported(node, "AbstractGetterDeclaration");
  }

  @override
  ir.Throw visitAbstractSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      _) {
    return handleUnsupported(node, "AbstractSetterDeclaration");
  }

  @override
  ir.Throw visitAs(Send node, Node expression, DartType type, _) {
    return handleUnsupported(node, "As");
  }

  @override
  ir.MethodInvocation visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return generateBinaryOperator(left, operator.name, right);
  }

  @override
  ir.Throw visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node,
      BoolFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "BoolFromEnvironmentConstructorInvoke");
  }

  @override
  ir.Throw visitClassTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ClassTypeLiteralGet");
  }

  @override
  ir.Throw visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralInvoke");
  }

  @override
  ir.Throw visitClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSet");
  }

  @override
  ir.Throw visitClassTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSetIfNull");
  }

  @override
  ir.Throw visitClosureDeclaration(
      FunctionExpression node,
      LocalFunctionElement closure,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "ClosureDeclaration");
  }

  @override
  ir.Throw visitCompoundIndexSet(
      SendSet node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "CompoundIndexSet");
  }

  @override
  ir.Throw visitConstConstructorInvoke(
      NewExpression node,
      ConstructedConstantExpression constant,
      _) {
    return handleUnsupported(node, "ConstConstructorInvoke");
  }

  @override
  ir.Throw visitConstantGet(Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ConstantGet");
  }

  @override
  ir.Throw visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstantInvoke");
  }

  @override
  ir.Throw visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstructorIncompatibleInvoke");
  }

  @override
  ir.PropertyGet visitDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return new ir.PropertyGet(receiver.accept(this), kernel.nameToIrName(name));
  }

  @override
  ir.MethodInvocation visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      _) {
    // TODO(ahe): Where's the call structure?
    ir.Arguments argumentsNode = generateArguments(arguments, null);
    return new ir.MethodInvocation(
        receiver.accept(this), kernel.nameToIrName(selector.memberName),
        argumentsNode);
  }

  @override
  ir.Expression handleDynamicCompounds(
      Send node,
      Node receiver,
      Name name,
      CompoundRhs rhs,
      _) {
    ir.Expression receiverNode = receiver == null
        ? new ir.ThisExpression() : receiver.accept(this);
    return generateCompound(
        PropertyAccessor.make(receiverNode, kernel.nameToIrName(name)), rhs);
  }

  @override
  ir.PropertySet visitDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    ir.Expression value = rhs.accept(this);
    return new ir.PropertySet(
        receiver.accept(this), kernel.nameToIrName(name), value);
  }

  @override
  ir.Throw visitDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertySetIfNull");
  }

  @override
  ir.Throw visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "DynamicTypeLiteralGet");
  }

  @override
  ir.Throw visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralInvoke");
  }

  @override
  ir.Throw visitDynamicTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralSet");
  }

  @override
  ir.Throw visitDynamicTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralSetIfNull");
  }

  ir.MethodInvocation generateBinaryOperator(
      Node left,
      String operator,
      Node right) {
    ir.Arguments arguments =
        new ir.Arguments(<ir.Expression>[right.accept(this)]);
    return new ir.MethodInvocation(
        left.accept(this), kernel.irName(operator, function), arguments);
  }

  @override
  ir.MethodInvocation visitEquals(Send node, Node left, Node right, _) {
    return generateBinaryOperator(left, '==', right);
  }

  @override
  ir.Throw visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ExpressionInvoke");
  }

  @override
  ir.Throw visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "FactoryConstructorDeclaration");
  }

  @override
  ir.Throw visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "FactoryConstructorInvoke");
  }

  @override
  ir.Throw visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "FieldInitializer");
  }

  @override
  ir.Throw visitFinalLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableSetIfNull");
  }

  @override
  ir.Throw visitFinalParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterSetIfNull");
  }

  @override
  ir.StaticSet handleFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleStaticFieldSet(node, field, rhs, _);
  }

  @override
  ir.Throw visitFinalStaticFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalStaticFieldSetIfNull");
  }

  @override
  ir.Throw visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "FinalSuperFieldSet");
  }

  @override
  ir.Throw visitFinalSuperFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalSuperFieldSetIfNull");
  }

  @override
  ir.Throw visitFinalTopLevelFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldSetIfNull");
  }

  @override
  ir.Throw visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    return handleUnsupported(node, "GenerativeConstructorDeclaration");
  }

  @override
  ir.Throw visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "GenerativeConstructorInvoke");
  }

  @override
  ir.Throw visitIfNotNullDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyGet");
  }

  @override
  ir.Throw visitIfNotNullDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyInvoke");
  }

  @override
  ir.Throw visitIfNotNullDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySet");
  }

  @override
  ir.Throw visitIfNotNullDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySetIfNull");
  }

  @override
  ir.Throw visitIfNull(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "IfNull");
  }

  @override
  ir.Throw visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      InterfaceType type,
      _) {
    return handleUnsupported(node, "ImplicitSuperConstructorInvoke");
  }

  @override
  ir.MethodInvocation visitIndex(Send node, Node receiver, Node index, _) {
    ir.Arguments arguments = new ir.Arguments(
        <ir.Expression>[index.accept(this)]);
    return new ir.MethodInvocation(
        receiver.accept(this), kernel.irName("[]", function), arguments);
  }

  @override
  ir.Throw visitIndexPostfix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPostfix");
  }

  @override
  ir.Throw visitIndexPrefix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPrefix");
  }

  @override
  ir.MethodInvocation visitIndexSet(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    ir.Arguments arguments = new ir.Arguments(
        <ir.Expression>[index.accept(this), rhs.accept(this)]);
    return new ir.MethodInvocation(
        receiver.accept(this), kernel.irName("[]=", function), arguments);
  }

  @override
  ir.Throw visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "InitializingFormalDeclaration");
  }

  @override
  ir.Throw visitInstanceFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "InstanceFieldDeclaration");
  }

  @override
  ir.Throw visitInstanceGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceGetterDeclaration");
  }

  @override
  ir.Throw visitInstanceSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceSetterDeclaration");
  }

  @override
  ir.Throw visitIntFromEnvironmentConstructorInvoke(
      NewExpression node,
      IntFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "IntFromEnvironmentConstructorInvoke");
  }

  ir.IsExpression generateIs(Node expression, DartType type) {
    return new ir.IsExpression(expression.accept(this), kernel.typeToIr(type));
  }

  @override
  ir.IsExpression visitIs(Send node, Node expression, DartType type, _) {
    return generateIs(expression, type);
  }

  @override
  ir.Not visitIsNot(Send node, Node expression, DartType type, _) {
    return new ir.Not(generateIs(expression, type));
  }

  ir.VariableDeclaration generateLocalVariableDeclaration(
      LocalVariableElement variable, Node initializer) {
    ir.Expression initializerNode = initializer?.accept(this);
    ir.VariableDeclaration local = getLocal(variable);
    if (initializer != null) {
      local.initializer = initializerNode;
      initializerNode.parent = local;
    }
    currentStatements.add(local);
    return local;
  }

  @override
  ir.VariableDeclaration visitLocalConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      ConstantExpression constant,
      _) {
    // TODO(ahe): Use [constant]?
    return generateLocalVariableDeclaration(variable, variable.initializer)
        ..isConst = true;
  }

  @override
  ir.FunctionNode visitLocalFunctionDeclaration(
      FunctionExpression node,
      LocalFunctionElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  @override
  ir.StaticGet visitLocalFunctionGet(
      Send node,
      LocalFunctionElement function,
      _) {
    return new ir.StaticGet(kernel.functionToIr(function));
  }

  @override
  ir.Throw visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionIncompatibleInvoke");
  }

  @override
  ir.Throw visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionInvoke");
  }

  @override
  ir.Throw visitLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSet");
  }

  @override
  ir.Throw visitLocalFunctionSetIfNull(
      Send node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSetIfNull");
  }

  @override
  ir.VariableDeclaration visitLocalVariableDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      Node initializer,
      _) {
    return generateLocalVariableDeclaration(variable, initializer);
  }

  ir.VariableGet generateLocalGet(LocalVariableElement local) {
    return new ir.VariableGet(getLocal(local));
  }

  @override
  ir.VariableGet handleLocalGet(Send node, LocalElement element, _) {
    return generateLocalGet(element);
  }

  ir.Expression generateCompound(Accessor accessor, CompoundRhs rhs) {
    ir.Name name = kernel.irName(rhs.operator.name, function);
    switch (rhs.kind) {
      case CompoundKind.POSTFIX:
        return accessor.buildPostfixIncrement(name);

      case CompoundKind.PREFIX:
        return accessor.buildPrefixIncrement(name);

      case CompoundKind.ASSIGNMENT:
        return accessor.buildCompoundAssignment(name, rhs.rhs.accept(this));
    }
  }

  @override
  ir.Expression handleLocalCompounds(
      SendSet node,
      LocalElement local,
      CompoundRhs rhs,
      _,
      {bool isSetterValid}) {
    return generateCompound(new VariableAccessor(getLocal(local)), rhs);
  }

  @override
  ir.VariableSet handleLocalSet(
      SendSet node,
      LocalElement element,
      Node rhs,
      _) {
    return new ir.VariableSet(getLocal(element), rhs.accept(this));
  }

  @override
  ir.VariableSet handleImmutableLocalSet(
      SendSet node,
      LocalElement element,
      Node rhs,
      _) {
    // TODO(ahe): Generate invalid?
    return handleLocalSet(node, element, rhs, _);
  }

  @override
  ir.Throw visitLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableSetIfNull");
  }

  @override
  ir.LogicalExpression visitLogicalAnd(Send node, Node left, Node right, _) {
    return new ir.LogicalExpression(
        left.accept(this), '&&', right.accept(this));
  }

  @override
  ir.LogicalExpression visitLogicalOr(Send node, Node left, Node right, _) {
    return new ir.LogicalExpression(
        left.accept(this), '||', right.accept(this));
  }

  @override
  ir.Throw visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedInitializingFormalDeclaration");
  }

  @override
  ir.Throw visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedParameterDeclaration");
  }

  @override
  ir.Not visitNot(Send node, Node expression, _) {
    return new ir.Not(expression.accept(this));
  }

  @override
  ir.Not visitNotEquals(Send node, Node left, Node right, _) {
    return new ir.Not(generateBinaryOperator(left, '==', right));
  }

  @override
  ir.Throw visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalInitializingFormalDeclaration");
  }

  @override
  ir.Throw visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalParameterDeclaration");
  }

  @override
  ir.Throw visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "ParameterDeclaration");
  }

  @override
  ir.MethodInvocation handleLocalInvoke(
      Send node,
      LocalElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Arguments argumentsNode = generateArguments(arguments, callStructure);
    return new ir.MethodInvocation(
        generateLocalGet(element),
        kernel.nameToIrName(callStructure.callSelector.memberName),
        argumentsNode);
  }

  @override
  ir.Throw visitParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterSetIfNull");
  }

  @override
  ir.Throw visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      InterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      _) {
    return handleUnsupported(node, "RedirectingFactoryConstructorDeclaration");
  }

  @override
  ir.Throw visitRedirectingFactoryConstructorInvoke(
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

  @override
  ir.Throw visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    return handleUnsupported(
        node, "RedirectingGenerativeConstructorDeclaration");
  }

  @override
  ir.Throw visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "RedirectingGenerativeConstructorInvoke");
  }

  @override
  ir.Throw visitStaticConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "StaticConstantDeclaration");
  }

  @override
  ir.Throw visitStaticFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "StaticFieldDeclaration");
  }

  @override
  ir.StaticGet handleStaticFieldGet(Send node, FieldElement field, _) {
    return new ir.StaticGet(kernel.fieldToIr(field));
  }

  @override
  ir.Throw handleStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFieldInvoke");
  }

  @override
  ir.StaticSet handleStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return new ir.StaticSet(kernel.fieldToIr(field), rhs.accept(this));
  }

  @override
  ir.Throw visitStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "StaticFieldSetIfNull");
  }

  ir.VariableDeclaration getLocal(LocalVariableElement local) {
    return kernel.locals.putIfAbsent(
        local, () => new ir.VariableDeclaration(local.name));
  }

  ir.FunctionNode generateFunctionNode(
      FunctionExpression node,
      FunctionElement function,
      NodeList parameters,
      Node bodyNode) {
    ir.TreeNode body;
    if (bodyNode != null) {
      body = bodyNode.accept(this);
      {
        // TODO(ahe): What goes on in this block is temporary as we complete
        // KernelVisitor.
        if (body is! ir.Statement) {
          body = new ir.ExpressionStatement(body);
        }
      }
      if (body is! ir.Block) {
        // TODO(ahe): Always normalize methods to have a block?
        body = new ir.Block(<ir.Statement>[body]);
      }
    }
    FunctionSignature signature = function.functionSignature;
    List<ir.VariableDeclaration> positionalParameters =
        <ir.VariableDeclaration>[];
    List<ir.VariableDeclaration> namedParameters = <ir.VariableDeclaration>[];
    int requiredParameterCount = signature.requiredParameterCount;
    signature.forEachParameter((LocalParameterElement parameter) {
      ir.VariableDeclaration variable = getLocal(parameter);
      if (parameter.isNamed) {
        namedParameters.add(variable);
      } else {
        positionalParameters.add(variable);
      }
    });
    signature.forEachParameter((LocalParameterElement parameter) {
      ir.Expression initializer = parameter.initializer?.accept(this);
      ir.VariableDeclaration variable = getLocal(parameter);
      if (initializer != null) {
        variable.initializer = initializer;
        initializer.parent = variable;
      }
    });
    return new ir.FunctionNode(body, positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  @override
  ir.FunctionNode visitStaticFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  @override
  ir.FunctionNode visitInstanceMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  @override
  ir.FunctionNode visitAbstractMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      _) {
    return generateFunctionNode(node, function, parameters, null);
  }

  @override
  ir.StaticGet handleStaticFunctionGet(Send node, MethodElement function, _) {
    return new ir.StaticGet(kernel.functionToIr(function));
  }

  @override
  ir.Throw handleStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFunctionIncompatibleInvoke");
  }

  @override
  ir.StaticInvocation handleStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Arguments argumentsNode = generateArguments(arguments, callStructure);
    return new ir.StaticInvocation(
        kernel.functionToIr(function), argumentsNode);
  }

  @override
  ir.Throw handleStaticFunctionSet(
      Send node, MethodElement function, Node rhs, _) {
    return handleUnsupported(node, "StaticFunctionSet");
  }

  @override
  ir.Throw visitStaticGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "StaticGetterDeclaration");
  }

  @override
  ir.Throw handleStaticGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "StaticGetterGet");
  }

  @override
  ir.Throw handleStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticGetterInvoke");
  }

  @override
  ir.Throw handleStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "StaticGetterSet");
  }

  @override
  ir.Throw visitStaticGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticGetterSetterSetIfNull");
  }

  @override
  ir.Throw visitStaticMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetIfNull");
  }

  @override
  ir.Throw visitStaticMethodSetterSetIfNull(
      Send node,
      MethodElement method,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetterSetIfNull");
  }

  @override
  ir.Throw visitStaticSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "StaticSetterDeclaration");
  }

  @override
  ir.Throw handleStaticSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "StaticSetterGet");
  }

  @override
  ir.Throw handleStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticSetterInvoke");
  }

  @override
  ir.Throw handleStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "StaticSetterSet");
  }

  @override
  ir.Throw visitStringFromEnvironmentConstructorInvoke(
      NewExpression node,
      StringFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "StringFromEnvironmentConstructorInvoke");
  }

  @override
  ir.Throw visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperBinary");
  }

  @override
  ir.Throw visitSuperCompoundIndexSet(
      SendSet node,
      MethodElement getter,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperCompoundIndexSet");
  }

  @override
  ir.Throw visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperConstructorInvoke");
  }

  @override
  ir.Throw visitSuperEquals(
      Send node, FunctionElement function, Node argument, _) {
    return handleUnsupported(node, "SuperEquals");
  }

  @override
  ir.Throw handleSuperCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    return handleUnsupported(node, "SuperCompounds ${rhs.kind}");
  }

  @override
  ir.Throw handleStaticCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    return handleUnsupported(node, "StaticCompounds ${rhs.kind}");
  }

  @override
  ir.Throw handleTypeLiteralConstantCompounds(
      SendSet node,
      ConstantExpression constant,
      CompoundRhs rhs,
      _) {
    return handleUnsupported(node, "TypeLiteralConstantCompounds ${rhs.kind}");
  }

  @override
  ir.Throw handleTypeVariableTypeLiteralCompounds(
      SendSet node,
      TypeVariableElement typeVariable,
      CompoundRhs rhs,
      _) {
    return handleUnsupported(
        node, "TypeVariableTypeLiteralCompounds ${rhs.kind}");
  }

  @override
  ir.Throw visitSuperFieldFieldSetIfNull(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldFieldSetIfNull");
  }

  @override
  ir.Throw visitSuperFieldGet(Send node, FieldElement field, _) {
    return handleUnsupported(node, "SuperFieldGet");
  }

  @override
  ir.Throw visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperFieldInvoke");
  }

  @override
  ir.Throw visitSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSet");
  }

  @override
  ir.Throw visitSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSetIfNull");
  }

  @override
  ir.Throw visitSuperFieldSetterSetIfNull(
      Send node,
      FieldElement field,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldSetterSetIfNull");
  }

  @override
  ir.Throw visitSuperGetterFieldSetIfNull(
      Send node,
      FunctionElement getter,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterFieldSetIfNull");
  }

  @override
  ir.Throw visitSuperGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "SuperGetterGet");
  }

  @override
  ir.Throw visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperGetterInvoke");
  }

  @override
  ir.Throw visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "SuperGetterSet");
  }

  @override
  ir.Throw visitSuperGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterSetterSetIfNull");
  }

  @override
  ir.Throw visitSuperIndex(
      Send node, FunctionElement function, Node index, _) {
    return handleUnsupported(node, "SuperIndex");
  }

  @override
  ir.Throw visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPostfix");
  }

  @override
  ir.Throw visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPrefix");
  }

  @override
  ir.Throw visitSuperIndexSet(
      SendSet node,
      FunctionElement function,
      Node index,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperIndexSet");
  }

  @override
  ir.Throw visitSuperMethodGet(Send node, MethodElement method, _) {
    return handleUnsupported(node, "SuperMethodGet");
  }

  @override
  ir.Throw visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodIncompatibleInvoke");
  }

  @override
  ir.Throw visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodInvoke");
  }

  @override
  ir.Throw visitSuperMethodSet(
      Send node, MethodElement method, Node rhs, _) {
    return handleUnsupported(node, "SuperMethodSet");
  }

  @override
  ir.Throw visitSuperMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetIfNull");
  }


  @override
  ir.Throw visitSuperMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetterSetIfNull");
  }

  @override
  ir.Throw visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperNotEquals");
  }

  @override
  ir.Throw visitSuperSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "SuperSetterGet");
  }

  @override
  ir.Throw visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperSetterInvoke");
  }

  @override
  ir.Throw visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "SuperSetterSet");
  }

  @override
  ir.Throw visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      _) {
    return handleUnsupported(node, "SuperUnary");
  }

  @override
  ir.Throw visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisConstructorInvoke");
  }

  @override
  ir.ThisExpression visitThisGet(Identifier node, _) {
    return new ir.ThisExpression();
  }

  @override
  ir.Throw visitThisInvoke(
      Send node,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisInvoke");
  }

  @override
  ir.PropertyGet visitThisPropertyGet(Send node, Name name, _) {
    return new ir.PropertyGet(
        new ir.ThisExpression(), kernel.nameToIrName(name));
  }

  @override
  ir.MethodInvocation visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      _) {
    // TODO(ahe): Where's the call structure?
    ir.Arguments argumentsNode = generateArguments(arguments, null);
    return new ir.MethodInvocation(
        new ir.ThisExpression(), kernel.nameToIrName(selector.memberName),
        argumentsNode);
  }

  @override
  ir.PropertySet visitThisPropertySet(SendSet node, Name name, Node rhs, _) {
    return new ir.PropertySet(
        new ir.ThisExpression(), kernel.nameToIrName(name), rhs.accept(this));
  }

  @override
  ir.Throw visitThisPropertySetIfNull(Send node, Name name, Node rhs, _) {
    return handleUnsupported(node, "ThisPropertySetIfNull");
  }

  @override
  ir.Throw visitTopLevelConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "TopLevelConstantDeclaration");
  }

  @override
  ir.Throw visitTopLevelFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "TopLevelFieldDeclaration");
  }

  @override
  ir.Throw visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "TopLevelFieldSetIfNull");
  }

  @override
  ir.FunctionNode visitTopLevelFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  ir.Arguments generateArguments(
      NodeList arguments, CallStructure callStructure) {
    List<ir.Expression> argumentNodes = <ir.Expression>[];
    for (Expression expression in arguments.nodes) {
      argumentNodes.add(expression.accept(this));
    }
    return new ir.Arguments(argumentNodes);
  }

  @override
  ir.Throw visitTopLevelGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelGetterDeclaration");
  }

  @override
  ir.Throw visitTopLevelGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterSetIfNull");
  }

  @override
  ir.Throw visitTopLevelMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetIfNull");
  }

  @override
  ir.Throw visitTopLevelMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterSetIfNull");
  }

  @override
  ir.Throw visitTopLevelSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelSetterDeclaration");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralGet");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralInvoke");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSet");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralSetIfNull(
      Send node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSetIfNull");
  }

  @override
  ir.Throw visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "TypedefTypeLiteralGet");
  }

  @override
  ir.Throw visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralInvoke");
  }

  @override
  ir.Throw visitTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSet");
  }

  @override
  ir.Throw visitTypedefTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSetIfNull");
  }

  @override
  ir.MethodInvocation visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return new ir.MethodInvocation(
        expression.accept(this), kernel.irName(operator.name, function),
        new ir.Arguments(<ir.Expression>[]));
  }

  @override
  ir.Throw visitConditionalUri(ConditionalUri node) {
    return handleUnsupported(node, "ConditionalUri");
  }

  @override
  ir.Throw visitDottedName(DottedName node) {
    return handleUnsupported(node, "DottedName");
  }

  @override
  ir.Throw visitForIn(ForIn node) {
    return handleUnsupported(node, "ForIn");
  }

  @override
  ir.Throw visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return handleUnsupported(node, "IndexSetIfNull");
  }

  @override
  ir.Throw visitSuperIndexSetIfNull(
      SendSet node, MethodElement getter, MethodElement setter, Node index,
      Node rhs, _) {
    return handleUnsupported(node, "SuperIndexSetIfNull");
  }

  ir.Throw handleUnsupported(Node node, String name) {
    // TODO(ahe): Do this:
    // throw new Unsupported("Kernel IR not yet implemented for '$name'.");
    if (const bool.fromEnvironment("verbose")) {
      print("Kernel IR not yet implemented for '$name'.");
    }
    return new ir.Throw(
        new ir.StringLiteral("Kernel IR not yet implemented for '$name'."));
  }

  ir.ExpressionStatement handleUnsupportedStatement(
      Statement node, String name) {
    return new ir.ExpressionStatement(handleUnsupported(node, name));
  }
}

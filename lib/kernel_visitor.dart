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
    FunctionSignature,
    InitializingFormalElement,
    JumpTarget,
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
    StringInterpolationPart,
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

import 'kernel.dart' show
    Kernel;

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
  final Kernel kernel;
  List<ir.Statement> currentStatements;

  final Map<JumpTarget, ir.LabeledStatement> continueTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<JumpTarget, ir.LabeledStatement> breakTargets =
      <JumpTarget, ir.LabeledStatement>{};

  KernelVisitor(this.function, this.elements, this.kernel);

  KernelVisitor get sendVisitor => this;

  KernelVisitor get declVisitor => this;

  ir.Expression handleUnresolved(Node node) {
    return handleUnsupported(node, "Unresolved node: $node");
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
    throw new Unsupported(message);
  }

  applyParameters(NodeList parameters, _) {
    throw new Unsupported("Not implemented yet.");
  }

  applyInitializers(FunctionExpression constructor, _) {
    throw new Unsupported("Not implemented yet.");
  }

  ir.AssertStatement visitAssert(Assert node) {
    return new ir.AssertStatement(
        node.condition.accept(this),
        node.message?.accept(this));
  }

  ir.Throw visitAsyncForIn(AsyncForIn node) {
    return handleUnsupported(node, "AsyncForIn");
  }

  ir.Throw visitAwait(Await node) {
    return handleUnsupported(node, "Await");
  }

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

  ir.BreakStatement visitBreakStatement(BreakStatement node) {
    return new ir.BreakStatement(getBreakTarget(elements.getTargetOf(node)));
  }

  ir.Throw visitCascade(Cascade node) {
    return handleUnsupported(node, "Cascade");
  }

  ir.Throw visitCascadeReceiver(CascadeReceiver node) {
    return handleUnsupported(node, "CascadeReceiver");
  }

  ir.Throw visitCaseMatch(CaseMatch node) {
    return handleUnsupported(node, "CaseMatch");
  }

  ir.Throw visitCatchBlock(CatchBlock node) {
    return handleUnsupported(node, "CatchBlock");
  }

  ir.ConditionalExpression visitConditional(Conditional node) {
    return new ir.ConditionalExpression(
        node.condition.accept(this),
        node.thenExpression.accept(this),
        node.elseExpression.accept(this));
  }

  ir.BreakStatement visitContinueStatement(ContinueStatement node) {
    return new ir.BreakStatement(getContinueTarget(elements.getTargetOf(node)));
  }

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

  ir.EmptyStatement visitEmptyStatement(EmptyStatement node) {
    return new ir.EmptyStatement();
  }

  ir.Throw visitEnum(Enum node) {
    return handleUnsupported(node, "Enum");
  }

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

  ir.ExpressionStatement visitFunctionDeclaration(FunctionDeclaration node) {
    return handleUnsupportedStatement(node, "FunctionDeclaration");
  }

  ir.IfStatement visitIf(If node) {
    return new ir.IfStatement(
        node.condition.accept(this),
        generateStatementInBlock(node.thenPart),
        generateStatementInBlock(node.elsePart));
  }

  ir.Throw visitLabel(Label node) {
    return handleUnsupported(node, "Label");
  }

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

  ir.BoolLiteral visitLiteralBool(LiteralBool node) {
    return new ir.BoolLiteral(node.value);
  }

  ir.DoubleLiteral visitLiteralDouble(LiteralDouble node) {
    return new ir.DoubleLiteral(node.value);
  }

  ir.IntLiteral visitLiteralInt(LiteralInt node) {
    return new ir.IntLiteral(node.value);
  }

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

  ir.Throw visitLiteralMapEntry(LiteralMapEntry node) {
    return handleUnsupported(node, "LiteralMapEntry");
  }

  ir.NullLiteral visitLiteralNull(LiteralNull node) {
    return new ir.NullLiteral();
  }

  ir.StringLiteral visitLiteralString(LiteralString node) {
    return new ir.StringLiteral(node.dartString.slowToString());
  }

  ir.Throw visitLiteralSymbol(LiteralSymbol node) {
    return handleUnsupported(node, "LiteralSymbol");
  }

  ir.Throw visitMetadata(Metadata node) {
    return handleUnsupported(node, "Metadata");
  }

  ir.Throw visitNamedArgument(NamedArgument node) {
    return handleUnsupported(node, "NamedArgument");
  }

  ir.Throw visitOperator(Operator node) {
    return handleUnsupported(node, "Operator");
  }

  ir.Expression visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  ir.Throw visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    return handleUnsupported(node, "RedirectingFactoryBody");
  }

  ir.Throw visitRethrow(Rethrow node) {
    return handleUnsupported(node, "Rethrow");
  }

  ir.ReturnStatement visitReturn(Return node) {
    return new ir.ReturnStatement(node.expression?.accept(this));
  }

  ir.StringConcatenation visitStringInterpolation(StringInterpolation node) {
    List<ir.Expression> expressions = <ir.Expression>[];
    expressions.add(node.string.accept(this));
    for (StringInterpolationPart part in node.parts) {
      expressions.add(part.expression.accept(this));
      expressions.add(part.string.accept(this));
    }
    return new ir.StringConcatenation(expressions);
  }

  ir.StringConcatenation visitStringJuxtaposition(StringJuxtaposition node) {
    return new ir.StringConcatenation(
        <ir.Expression>[node.first.accept(this), node.second.accept(this)]);
  }

  ir.Throw visitSwitchCase(SwitchCase node) {
    return handleUnsupported(node, "SwitchCase");
  }

  ir.ExpressionStatement visitSwitchStatement(SwitchStatement node) {
    return handleUnsupportedStatement(node, "SwitchStatement");
  }

  ir.ExpressionStatement visitSyncForIn(SyncForIn node) {
    return handleUnsupportedStatement(node, "SyncForIn");
  }

  ir.Throw visitThrow(Throw node) {
    return new ir.Throw(node?.expression.accept(this));
  }

  ir.ExpressionStatement visitTryStatement(TryStatement node) {
    return handleUnsupportedStatement(node, "TryStatement");
  }

  ir.Throw visitTypeAnnotation(TypeAnnotation node) {
    return handleUnsupported(node, "TypeAnnotation");
  }

  ir.Throw visitTypeVariable(TypeVariable node) {
    return handleUnsupported(node, "TypeVariable");
  }

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

  ir.ExpressionStatement visitYield(Yield node) {
    return handleUnsupportedStatement(node, "Yield");
  }

  ir.Throw visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "AbstractClassConstructorInvoke");
  }

  ir.Throw visitAbstractGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      _) {
    return handleUnsupported(node, "AbstractGetterDeclaration");
  }

  ir.Throw visitAbstractSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      _) {
    return handleUnsupported(node, "AbstractSetterDeclaration");
  }

  ir.Throw visitAs(Send node, Node expression, DartType type, _) {
    return handleUnsupported(node, "As");
  }

  ir.MethodInvocation visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return generateBinaryOperator(left, operator.name, right);
  }

  ir.Throw visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node,
      BoolFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "BoolFromEnvironmentConstructorInvoke");
  }

  ir.Throw visitClassTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralCompound");
  }

  ir.Throw visitClassTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ClassTypeLiteralGet");
  }

  ir.Throw visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralInvoke");
  }

  ir.Throw visitClassTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralPostfix");
  }

  ir.Throw visitClassTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralPrefix");
  }

  ir.Throw visitClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSet");
  }

  ir.Throw visitClassTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "ClassTypeLiteralSetIfNull");
  }

  ir.Throw visitClosureDeclaration(
      FunctionExpression node,
      LocalFunctionElement closure,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "ClosureDeclaration");
  }

  ir.Throw visitCompoundIndexSet(
      SendSet node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "CompoundIndexSet");
  }

  ir.Throw visitConstConstructorInvoke(
      NewExpression node,
      ConstructedConstantExpression constant,
      _) {
    return handleUnsupported(node, "ConstConstructorInvoke");
  }

  ir.Throw visitConstantGet(Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "ConstantGet");
  }

  ir.Throw visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstantInvoke");
  }

  ir.Throw visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ConstructorIncompatibleInvoke");
  }

  ir.Throw visitDynamicPropertyCompound(
      Send node,
      Node receiver,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertyCompound");
  }

  ir.PropertyGet visitDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return new ir.PropertyGet(receiver.accept(this), kernel.nameToIrName(name));
  }

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

  ir.Throw visitDynamicPropertyPostfix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicPropertyPostfix");
  }

  ir.Throw visitDynamicPropertyPrefix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicPropertyPrefix");
  }

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

  ir.Throw visitDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicPropertySetIfNull");
  }

  ir.Throw visitDynamicTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralCompound");
  }

  ir.Throw visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "DynamicTypeLiteralGet");
  }

  ir.Throw visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralInvoke");
  }

  ir.Throw visitDynamicTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralPostfix");
  }

  ir.Throw visitDynamicTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralPrefix");
  }

  ir.Throw visitDynamicTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "DynamicTypeLiteralSet");
  }

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

  ir.MethodInvocation visitEquals(Send node, Node left, Node right, _) {
    return generateBinaryOperator(left, '==', right);
  }

  ir.Throw visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ExpressionInvoke");
  }

  ir.Throw visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "FactoryConstructorDeclaration");
  }

  ir.Throw visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "FactoryConstructorInvoke");
  }

  ir.Throw visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "FieldInitializer");
  }

  ir.Throw visitFinalLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableCompound");
  }

  ir.Throw visitFinalLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalLocalVariablePostfix");
  }

  ir.Throw visitFinalLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalLocalVariablePrefix");
  }

  ir.Throw visitFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableSet");
  }

  ir.Throw visitFinalLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalLocalVariableSetIfNull");
  }

  ir.Throw visitFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterCompound");
  }

  ir.Throw visitFinalParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalParameterPostfix");
  }

  ir.Throw visitFinalParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalParameterPrefix");
  }

  ir.Throw visitFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterSet");
  }

  ir.Throw visitFinalParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalParameterSetIfNull");
  }

  ir.Throw visitFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalStaticFieldCompound");
  }

  ir.Throw visitFinalStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalStaticFieldPostfix");
  }

  ir.Throw visitFinalStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalStaticFieldPrefix");
  }

  ir.StaticSet visitFinalStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return visitStaticFieldSet(node, field, rhs, _);
  }

  ir.Throw visitFinalStaticFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalStaticFieldSetIfNull");
  }

  ir.Throw visitFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalSuperFieldCompound");
  }

  ir.Throw visitFinalSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalSuperFieldPostfix");
  }

  ir.Throw visitFinalSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalSuperFieldPrefix");
  }

  ir.Throw visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "FinalSuperFieldSet");
  }

  ir.Throw visitFinalSuperFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalSuperFieldSetIfNull");
  }

  ir.Throw visitFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldCompound");
  }

  ir.Throw visitFinalTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldPostfix");
  }

  ir.Throw visitFinalTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldPrefix");
  }

  ir.Throw visitFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldSet");
  }

  ir.Throw visitFinalTopLevelFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "FinalTopLevelFieldSetIfNull");
  }

  ir.Throw visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    return handleUnsupported(node, "GenerativeConstructorDeclaration");
  }

  ir.Throw visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "GenerativeConstructorInvoke");
  }

  ir.Throw visitIfNotNullDynamicPropertyCompound(
      Send node,
      Node receiver,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyCompound");
  }

  ir.Throw visitIfNotNullDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyGet");
  }

  ir.Throw visitIfNotNullDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyInvoke");
  }

  ir.Throw visitIfNotNullDynamicPropertyPostfix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyPostfix");
  }

  ir.Throw visitIfNotNullDynamicPropertyPrefix(
      Send node,
      Node receiver,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertyPrefix");
  }

  ir.Throw visitIfNotNullDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySet");
  }

  ir.Throw visitIfNotNullDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return handleUnsupported(node, "IfNotNullDynamicPropertySetIfNull");
  }

  ir.Throw visitIfNull(Send node, Node left, Node right, _) {
    return handleUnsupported(node, "IfNull");
  }

  ir.Throw visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      InterfaceType type,
      _) {
    return handleUnsupported(node, "ImplicitSuperConstructorInvoke");
  }

  ir.MethodInvocation visitIndex(Send node, Node receiver, Node index, _) {
    ir.Arguments arguments = new ir.Arguments(
        <ir.Expression>[index.accept(this)]);
    return new ir.MethodInvocation(
        receiver.accept(this), kernel.irName("[]", function), arguments);
  }

  ir.Throw visitIndexPostfix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPostfix");
  }

  ir.Throw visitIndexPrefix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "IndexPrefix");
  }

  ir.MethodInvocation visitIndexSet(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    ir.Arguments arguments = new ir.Arguments(
        <ir.Expression>[index.accept(this), rhs.accept(this)]);
    return new ir.MethodInvocation(
        receiver.accept(this), kernel.irName("[]=", function), arguments);
  }

  ir.Throw visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "InitializingFormalDeclaration");
  }

  ir.Throw visitInstanceFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "InstanceFieldDeclaration");
  }

  ir.Throw visitInstanceGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceGetterDeclaration");
  }

  ir.Throw visitInstanceSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "InstanceSetterDeclaration");
  }

  ir.Throw visitIntFromEnvironmentConstructorInvoke(
      NewExpression node,
      IntFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "IntFromEnvironmentConstructorInvoke");
  }

  ir.IsExpression generateIs(Node expression, DartType type) {
    return new ir.IsExpression(expression.accept(this), kernel.typeToIr(type));
  }

  ir.IsExpression visitIs(Send node, Node expression, DartType type, _) {
    return generateIs(expression, type);
  }

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

  ir.Throw visitLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionCompound");
  }

  ir.FunctionNode visitLocalFunctionDeclaration(
      FunctionExpression node,
      LocalFunctionElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  ir.StaticGet visitLocalFunctionGet(
      Send node, LocalFunctionElement function, _) {
    return new ir.StaticGet(kernel.functionToIr(function));
  }

  ir.Throw visitLocalFunctionIncompatibleInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionIncompatibleInvoke");
  }

  ir.Throw visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalFunctionInvoke");
  }

  ir.Throw visitLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalFunctionPostfix");
  }

  ir.Throw visitLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "LocalFunctionPrefix");
  }

  ir.Throw visitLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSet");
  }

  ir.Throw visitLocalFunctionSetIfNull(
      Send node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalFunctionSetIfNull");
  }

  ir.Throw visitLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableCompound");
  }

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

  ir.VariableGet visitLocalVariableGet(
      Send node, LocalVariableElement variable, _) {
    return generateLocalGet(variable);
  }

  ir.Throw visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "LocalVariableInvoke");
  }

  ir.Let visitLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    // Build this let expression:
    //
    //     let val = variable in let dummy = (variable = val + 1) in val
    //
    // The variable `dummy` is needed as we don't have a way to sequence
    // expressions.
    ir.Name name = kernel.irName(operator.binaryOperator.name, function);
    ir.VariableDeclaration local = getLocal(variable);
    ir.VariableDeclaration val = new ir.VariableDeclaration(
        "val", initializer: new ir.VariableGet(local));
    ir.Arguments one = new ir.Arguments(<ir.Expression>[new ir.IntLiteral(1)]);
    ir.MethodInvocation update =
        new ir.MethodInvocation(new ir.VariableGet(val), name, one);
    ir.VariableDeclaration dummy = new ir.VariableDeclaration(
        "dummy", initializer: new ir.VariableSet(local, update));

    return new ir.Let(val, new ir.Let(dummy, new ir.VariableGet(val)));
  }

  ir.MethodInvocation generateLocalPrefix(
      LocalVariableElement variable,
      IncDecOperator operator) {
    ir.Name name = kernel.irName(operator.binaryOperator.name, function);
    ir.Arguments one = new ir.Arguments(<ir.Expression>[new ir.IntLiteral(1)]);
    return new ir.MethodInvocation(generateLocalGet(variable), name, one);
  }

  ir.MethodInvocation visitLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      _) {
    return generateLocalPrefix(variable, operator);
  }

  ir.VariableSet generateLocalSet(LocalVariableElement variable, Node rhs) {
    return new ir.VariableSet(getLocal(variable), rhs.accept(this));
  }

  ir.VariableSet visitLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return generateLocalSet(variable, rhs);
  }

  ir.Throw visitLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return handleUnsupported(node, "LocalVariableSetIfNull");
  }

  ir.LogicalExpression visitLogicalAnd(Send node, Node left, Node right, _) {
    return new ir.LogicalExpression(
        left.accept(this), '&&', right.accept(this));
  }

  ir.LogicalExpression visitLogicalOr(Send node, Node left, Node right, _) {
    return new ir.LogicalExpression(
        left.accept(this), '||', right.accept(this));
  }

  ir.Throw visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedInitializingFormalDeclaration");
  }

  ir.Throw visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      _) {
    return handleUnsupported(node, "NamedParameterDeclaration");
  }

  ir.Not visitNot(Send node, Node expression, _) {
    return new ir.Not(expression.accept(this));
  }

  ir.Not visitNotEquals(Send node, Node left, Node right, _) {
    return new ir.Not(generateBinaryOperator(left, '==', right));
  }

  ir.Throw visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalInitializingFormalDeclaration");
  }

  ir.Throw visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return handleUnsupported(node, "OptionalParameterDeclaration");
  }

  ir.Throw visitParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterCompound");
  }

  ir.Throw visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      _) {
    return handleUnsupported(node, "ParameterDeclaration");
  }

  ir.VariableGet visitParameterGet(Send node, ParameterElement parameter, _) {
    return generateLocalGet(parameter);
  }

  ir.MethodInvocation visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    ir.Arguments argumentsNode = generateArguments(arguments, callStructure);
    return new ir.MethodInvocation(
        generateLocalGet(parameter),
        kernel.nameToIrName(callStructure.callSelector.memberName),
        argumentsNode);
  }

  ir.Throw visitParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ParameterPostfix");
  }

  ir.MethodInvocation visitParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      _) {
    return generateLocalPrefix(parameter, operator);
  }

  ir.VariableSet visitParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return generateLocalSet(parameter, rhs);
  }

  ir.Throw visitParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return handleUnsupported(node, "ParameterSetIfNull");
  }

  ir.Throw visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      InterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      _) {
    return handleUnsupported(node, "RedirectingFactoryConstructorDeclaration");
  }

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

  ir.Throw visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    return handleUnsupported(
        node, "RedirectingGenerativeConstructorDeclaration");
  }

  ir.Throw visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "RedirectingGenerativeConstructorInvoke");
  }

  ir.Throw visitStaticConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "StaticConstantDeclaration");
  }

  ir.Throw visitStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticFieldCompound");
  }

  ir.Throw visitStaticFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "StaticFieldDeclaration");
  }

  ir.StaticGet generateStaticGet(FieldElement field) {
    return new ir.StaticGet(kernel.fieldToIr(field));
  }

  ir.StaticGet visitStaticFieldGet(Send node, FieldElement field, _) {
    return generateStaticGet(field);
  }

  ir.Throw visitStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFieldInvoke");
  }

  ir.Throw visitStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticFieldPostfix");
  }

  ir.Throw visitStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticFieldPrefix");
  }

  ir.StaticSet visitStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return new ir.StaticSet(kernel.fieldToIr(field), rhs.accept(this));
  }

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
        namedParameters: namedParameters);
  }

  ir.FunctionNode visitStaticFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  ir.FunctionNode visitInstanceMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  ir.FunctionNode visitAbstractMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      _) {
    return generateFunctionNode(node, function, parameters, null);
  }

  ir.StaticGet visitStaticFunctionGet(Send node, MethodElement function, _) {
    return new ir.StaticGet(kernel.functionToIr(function));
  }

  ir.Throw visitStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticFunctionIncompatibleInvoke");
  }

  ir.StaticInvocation visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return generateStaticInvocation(function, arguments, callStructure);
  }

  ir.Throw visitStaticFunctionSet(
      Send node, MethodElement function, Node rhs, _) {
    return handleUnsupported(node, "StaticFunctionSet");
  }

  ir.Throw visitStaticGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "StaticGetterDeclaration");
  }

  ir.Throw visitStaticGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "StaticGetterGet");
  }

  ir.Throw visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticGetterInvoke");
  }

  ir.Throw visitStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "StaticGetterSet");
  }

  ir.Throw visitStaticGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticGetterSetterCompound");
  }

  ir.Throw visitStaticGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticGetterSetterPostfix");
  }

  ir.Throw visitStaticGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticGetterSetterPrefix");
  }

  ir.Throw visitStaticGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticGetterSetterSetIfNull");
  }

  ir.Throw visitStaticMethodCompound(
      Send node,
      MethodElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodCompound");
  }

  ir.Throw visitStaticMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodPostfix");
  }

  ir.Throw visitStaticMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodPrefix");
  }

  ir.Throw visitStaticMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetIfNull");
  }

  ir.Throw visitStaticMethodSetterCompound(
      Send node,
      MethodElement method,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetterCompound");
  }

  ir.Throw visitStaticMethodSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodSetterPostfix");
  }

  ir.Throw visitStaticMethodSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "StaticMethodSetterPrefix");
  }

  ir.Throw visitStaticMethodSetterSetIfNull(
      Send node,
      MethodElement method,
      MethodElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "StaticMethodSetterSetIfNull");
  }

  ir.Throw visitStaticSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "StaticSetterDeclaration");
  }

  ir.Throw visitStaticSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "StaticSetterGet");
  }

  ir.Throw visitStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "StaticSetterInvoke");
  }

  ir.Throw visitStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "StaticSetterSet");
  }

  ir.Throw visitStringFromEnvironmentConstructorInvoke(
      NewExpression node,
      StringFromEnvironmentConstantExpression constant,
      _) {
    return handleUnsupported(node, "StringFromEnvironmentConstructorInvoke");
  }

  ir.Throw visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperBinary");
  }

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

  ir.Throw visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperConstructorInvoke");
  }

  ir.Throw visitSuperEquals(
      Send node, FunctionElement function, Node argument, _) {
    return handleUnsupported(node, "SuperEquals");
  }

  ir.Throw visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldCompound");
  }

  ir.Throw visitSuperFieldFieldCompound(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldFieldCompound");
  }

  ir.Throw visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldFieldPostfix");
  }

  ir.Throw visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldFieldPrefix");
  }

  ir.Throw visitSuperFieldFieldSetIfNull(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldFieldSetIfNull");
  }

  ir.Throw visitSuperFieldGet(Send node, FieldElement field, _) {
    return handleUnsupported(node, "SuperFieldGet");
  }

  ir.Throw visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperFieldInvoke");
  }

  ir.Throw visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldPostfix");
  }

  ir.Throw visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldPrefix");
  }

  ir.Throw visitSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSet");
  }

  ir.Throw visitSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "SuperFieldSetIfNull");
  }

  ir.Throw visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldSetterCompound");
  }

  ir.Throw visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldSetterPostfix");
  }

  ir.Throw visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperFieldSetterPrefix");
  }

  ir.Throw visitSuperFieldSetterSetIfNull(
      Send node,
      FieldElement field,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperFieldSetterSetIfNull");
  }

  ir.Throw visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterFieldCompound");
  }

  ir.Throw visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterFieldPostfix");
  }

  ir.Throw visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterFieldPrefix");
  }

  ir.Throw visitSuperGetterFieldSetIfNull(
      Send node,
      FunctionElement getter,
      FieldElement field,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterFieldSetIfNull");
  }

  ir.Throw visitSuperGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "SuperGetterGet");
  }

  ir.Throw visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperGetterInvoke");
  }

  ir.Throw visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return handleUnsupported(node, "SuperGetterSet");
  }

  ir.Throw visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterSetterCompound");
  }

  ir.Throw visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterSetterPostfix");
  }

  ir.Throw visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperGetterSetterPrefix");
  }

  ir.Throw visitSuperGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperGetterSetterSetIfNull");
  }

  ir.Throw visitSuperIndex(
      Send node, FunctionElement function, Node index, _) {
    return handleUnsupported(node, "SuperIndex");
  }

  ir.Throw visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPostfix");
  }

  ir.Throw visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperIndexPrefix");
  }

  ir.Throw visitSuperIndexSet(
      SendSet node,
      FunctionElement function,
      Node index,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperIndexSet");
  }

  ir.Throw visitSuperMethodCompound(
      Send node,
      FunctionElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodCompound");
  }

  ir.Throw visitSuperMethodGet(Send node, MethodElement method, _) {
    return handleUnsupported(node, "SuperMethodGet");
  }

  ir.Throw visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodIncompatibleInvoke");
  }

  ir.Throw visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperMethodInvoke");
  }

  ir.Throw visitSuperMethodPostfix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodPostfix");
  }

  ir.Throw visitSuperMethodPrefix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodPrefix");
  }

  ir.Throw visitSuperMethodSet(
      Send node, MethodElement method, Node rhs, _) {
    return handleUnsupported(node, "SuperMethodSet");
  }

  ir.Throw visitSuperMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetIfNull");
  }

  ir.Throw visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetterCompound");
  }

  ir.Throw visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodSetterPostfix");
  }

  ir.Throw visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "SuperMethodSetterPrefix");
  }

  ir.Throw visitSuperMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "SuperMethodSetterSetIfNull");
  }

  ir.Throw visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      _) {
    return handleUnsupported(node, "SuperNotEquals");
  }

  ir.Throw visitSuperSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "SuperSetterGet");
  }

  ir.Throw visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "SuperSetterInvoke");
  }

  ir.Throw visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return handleUnsupported(node, "SuperSetterSet");
  }

  ir.Throw visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      _) {
    return handleUnsupported(node, "SuperUnary");
  }

  ir.Throw visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisConstructorInvoke");
  }

  ir.ThisExpression visitThisGet(Identifier node, _) {
    return new ir.ThisExpression();
  }

  ir.Throw visitThisInvoke(
      Send node,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "ThisInvoke");
  }

  ir.Throw visitThisPropertyCompound(
      Send node,
      Name name,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "ThisPropertyCompound");
  }

  ir.PropertyGet visitThisPropertyGet(Send node, Name name, _) {
    return new ir.PropertyGet(
        new ir.ThisExpression(), kernel.nameToIrName(name));
  }

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

  ir.Throw visitThisPropertyPostfix(
      Send node,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ThisPropertyPostfix");
  }

  ir.Throw visitThisPropertyPrefix(
      Send node,
      Name name,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "ThisPropertyPrefix");
  }

  ir.PropertySet visitThisPropertySet(SendSet node, Name name, Node rhs, _) {
    return new ir.PropertySet(
        new ir.ThisExpression(), kernel.nameToIrName(name), rhs.accept(this));
  }

  ir.Throw visitThisPropertySetIfNull(Send node, Name name, Node rhs, _) {
    return handleUnsupported(node, "ThisPropertySetIfNull");
  }

  ir.Throw visitTopLevelConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return handleUnsupported(node, "TopLevelConstantDeclaration");
  }

  ir.Throw visitTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelFieldCompound");
  }

  ir.Throw visitTopLevelFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return handleUnsupported(node, "TopLevelFieldDeclaration");
  }

  ir.StaticGet visitTopLevelFieldGet(Send node, FieldElement field, _) {
    return generateStaticGet(field);
  }

  ir.Throw visitTopLevelFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelFieldInvoke");
  }

  ir.Throw visitTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelFieldPostfix");
  }

  ir.Throw visitTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelFieldPrefix");
  }

  ir.Throw visitTopLevelFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "TopLevelFieldSet");
  }

  ir.Throw visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return handleUnsupported(node, "TopLevelFieldSetIfNull");
  }

  ir.FunctionNode visitTopLevelFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return generateFunctionNode(node, function, parameters, body);
  }

  ir.Throw visitTopLevelFunctionGet(Send node, MethodElement function, _) {
    return handleUnsupported(node, "TopLevelFunctionGet");
  }

  ir.Throw visitTopLevelFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelFunctionIncompatibleInvoke");
  }

  ir.Arguments generateArguments(
      NodeList arguments, CallStructure callStructure) {
    List<ir.Expression> argumentNodes = <ir.Expression>[];
    for (Expression expression in arguments.nodes) {
      argumentNodes.add(expression.accept(this));
    }
    return new ir.Arguments(argumentNodes);
  }

  ir.StaticInvocation generateStaticInvocation(MethodElement function,
      NodeList arguments, CallStructure callStructure) {
    ir.Arguments argumentsNode = generateArguments(arguments, callStructure);
    return new ir.StaticInvocation(
        kernel.functionToIr(function), argumentsNode);
  }

  ir.StaticInvocation visitTopLevelFunctionInvoke(
      Send node, MethodElement function, NodeList arguments,
      CallStructure callStructure, _) {
    return generateStaticInvocation(function, arguments, callStructure);
  }

  ir.Throw visitTopLevelFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelFunctionSet");
  }

  ir.Throw visitTopLevelGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelGetterDeclaration");
  }

  ir.Throw visitTopLevelGetterGet(Send node, FunctionElement getter, _) {
    return handleUnsupported(node, "TopLevelGetterGet");
  }

  ir.Throw visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelGetterInvoke");
  }

  ir.Throw visitTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSet");
  }

  ir.Throw visitTopLevelGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterCompound");
  }

  ir.Throw visitTopLevelGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterPostfix");
  }

  ir.Throw visitTopLevelGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterPrefix");
  }

  ir.Throw visitTopLevelGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelGetterSetterSetIfNull");
  }

  ir.Throw visitTopLevelMethodCompound(
      Send node,
      FunctionElement method,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodCompound");
  }

  ir.Throw visitTopLevelMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodPostfix");
  }

  ir.Throw visitTopLevelMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodPrefix");
  }

  ir.Throw visitTopLevelMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetIfNull");
  }

  ir.Throw visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterCompound");
  }

  ir.Throw visitTopLevelMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterPostfix");
  }

  ir.Throw visitTopLevelMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterPrefix");
  }

  ir.Throw visitTopLevelMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelMethodSetterSetIfNull");
  }

  ir.Throw visitTopLevelSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return handleUnsupported(node, "TopLevelSetterDeclaration");
  }

  ir.Throw visitTopLevelSetterGet(Send node, FunctionElement setter, _) {
    return handleUnsupported(node, "TopLevelSetterGet");
  }

  ir.Throw visitTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TopLevelSetterInvoke");
  }

  ir.Throw visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      _) {
    return handleUnsupported(node, "TopLevelSetterSet");
  }

  ir.Throw visitTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralCompound");
  }

  ir.Throw visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralGet");
  }

  ir.Throw visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralInvoke");
  }

  ir.Throw visitTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralPostfix");
  }

  ir.Throw visitTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralPrefix");
  }

  ir.Throw visitTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSet");
  }

  ir.Throw visitTypeVariableTypeLiteralSetIfNull(
      Send node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypeVariableTypeLiteralSetIfNull");
  }

  ir.Throw visitTypedefTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralCompound");
  }

  ir.Throw visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return handleUnsupported(node, "TypedefTypeLiteralGet");
  }

  ir.Throw visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralInvoke");
  }

  ir.Throw visitTypedefTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralPostfix");
  }

  ir.Throw visitTypedefTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralPrefix");
  }

  ir.Throw visitTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSet");
  }

  ir.Throw visitTypedefTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return handleUnsupported(node, "TypedefTypeLiteralSetIfNull");
  }

  ir.MethodInvocation visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return new ir.MethodInvocation(
        expression.accept(this), kernel.irName(operator.name, function),
        new ir.Arguments(<ir.Expression>[]));
  }

  ir.Throw visitConditionalUri(ConditionalUri node) {
    return handleUnsupported(node, "ConditionalUri");
  }

  ir.Throw visitDottedName(DottedName node) {
    return handleUnsupported(node, "DottedName");
  }

  ir.Throw visitForIn(ForIn node) {
    return handleUnsupported(node, "ForIn");
  }

  ir.Throw visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return handleUnsupported(node, "IndexSetIfNull");
  }

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

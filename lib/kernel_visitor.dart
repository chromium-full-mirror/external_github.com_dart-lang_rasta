// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.kernel_visitor;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/accessors.dart' show
    Accessor,
    IndexAccessor,
    NullAwarePropertyAccessor,
    PropertyAccessor,
    StaticAccessor,
    SuperIndexAccessor,
    SuperPropertyAccessor,
    ThisPropertyAccessor,
    VariableAccessor,
    buildIsNull,
    makeBinary,
    makeLet,
    makeOrReuseVariable;

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

import 'package:compiler/src/resolution/send_structure.dart' show
    InitializerStructure,
    InitializersStructure,
    VariableStructure;

import 'package:compiler/src/resolution/send_resolver.dart' show
    DeclarationResolverMixin;

import 'package:compiler/src/elements/elements.dart' show
    AstElement,
    AsyncMarker,
    ClassElement,
    ConstructorElement,
    Element,
    Elements,
    FieldElement,
    FunctionElement,
    FunctionSignature,
    GetterElement,
    InitializingFormalElement,
    JumpTarget,
    LocalElement,
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

/// Translates dart2js AST nodes [Node] into Kernel IR [ir.TreeNode].
///
/// Most methods in this class have a prefix that follows these conventions:
///
///   * `visit` for overridden visitor methods.
///   * `handle` for methods that implement common behavior for several `visit`
///     methods. These methods are called by `visit` methods implemented by
///     various mixins below.
///   * `build` helper method that builds a new Kernel IR tree.
///   * `get` helper method that use a cache to build exactly one Kernel IR
///     tree for a given element.
///
/// We reserve the prefixes `visit` and `handle` for superclasses of this
/// class. So those methods should always have an @override annotation. Use
/// `build` instead of `handle` when adding a new helper method to this class.
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
  AstElement currentElement;
  final Kernel kernel;

  final Map<JumpTarget, ir.LabeledStatement> continueTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<JumpTarget, ir.SwitchCase> continueSwitchTargets =
      <JumpTarget, ir.SwitchCase>{};

  final Map<JumpTarget, ir.LabeledStatement> breakTargets =
      <JumpTarget, ir.LabeledStatement>{};

  final Map<LocalElement, ir.VariableDeclaration> locals =
      <LocalElement, ir.VariableDeclaration>{};

  final Map<CascadeReceiver, ir.VariableGet> cascadeReceivers =
      <CascadeReceiver, ir.VariableGet>{};

  KernelVisitor(this.currentElement, this.elements, this.kernel);

  KernelVisitor get sendVisitor => this;

  KernelVisitor get declVisitor => this;

  withCurrentElement(AstElement element, f()) {
    assert(element.library == kernel.compiler.currentElement.library);
    Element previousElement = currentElement;
    currentElement = element;
    try {
      return f();
    } finally {
      currentElement = previousElement;
    }
  }

  ir.DartType computeType(TypeAnnotation node) {
    if (node == null) return const ir.DynamicType();
    return kernel.typeToIr(elements.getType(node));
  }

  // This works around a bug in dart2js.
  // TODO(ahe): Fix the bug in dart2js and remove this function.
  ir.DartType typeToIrHack(DartType type) {
    if (currentElement.isSynthesized &&
        currentElement.enclosingClass.isMixinApplication) {
      // Dart2js doesn't compute the correct functionSignature for synthetic
      // constructors in mixin applications. So we compute the correct type:
      // First, find the first superclass that isn't a mixin.
      ClassElement superclass = currentElement.enclosingClass.superclass;
      while (superclass.isMixinApplication) {
        superclass = superclass.superclass;
      }
      // Then translate the "this type" of the mixin application to its
      // supertype with the correct type arguments.
      //
      // Consider this example:
      //
      //     class Super<S> {}
      //     class Sub<T> extends Object with Super<T> {}
      //
      // Here the problem is that dart2js has created a constructor that refers
      // to S (not T) in Sub (for example, the return type of the constructor
      // is Super<S> and it should be Sub<T>, but we settle for Super<T> for
      // now). So we need to translate Sub<T> to an instance of Super, which is
      // Super<T> (not Super<S>).
      InterfaceType supertype =
          currentElement.enclosingClass.asInstanceOf(superclass);
      // Once we have [supertype], we know how to substitute S with T: the type
      // arguments of [supertype] corresponds to T, and the type variables of
      // its element correspond to S.
      type = type.subst(
          supertype.typeArguments, supertype.element.typeVariables);
    }
    return kernel.typeToIr(type);
  }

  List<ir.DartType> computeTypesFromTypes(NodeList nodes, {int expected}) {
    if (expected == null) {
      throw "[expected] is null";
    }
    List<ir.DartType> types = new List<ir.DartType>(expected);
    Iterator<Node> iterator = nodes?.iterator;
    for (int i = 0; i < expected; i++) {
      TypeAnnotation type = null;
      if (iterator != null && iterator.moveNext()) {
        type = iterator.current;
      }
      types[i] = computeType(type);
    }
    if (iterator != null && iterator.moveNext()) {
      // Should already have been reported by resolution.
      // TODO(ahe): Delete this debug message.
      kernel.debugMessage(iterator.current, "Extra type arguments.");
    }
    return types;
  }

  ir.DartType computeTypeFromTypes(NodeList node) {
    return computeTypesFromTypes(node, expected: 1).single;
  }

  ir.MethodInvocation buildInvokeSelector(
      ir.Expression receiver,
      Selector selector,
      ir.Arguments arguments) {
    return new ir.MethodInvocation(
        receiver, kernel.nameToIrName(selector.memberName), arguments);
  }

  @override
  ir.InvalidExpression handleUnresolved(Node node) {
    return new ir.InvalidExpression();
  }

  @override
  ir.Throw handleError(Node node) {
    return buildUnsupported(node, "handleError");
  }

  @override
  void apply(Node node, _) {
    throw new Unsupported("Not implemented yet.");
  }

  @override
  void previsitDeferredAccess(Send node, PrefixElement prefix, _) {
  }

  @override
  internalError(Spannable spannable, String message) {
    kernel.internalError(spannable, message);
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

  ir.LabeledStatement getBreakTarget(JumpTarget target) {
    return breakTargets.putIfAbsent(
        target, () => new ir.LabeledStatement(null));
  }

  ir.LabeledStatement getContinueTarget(JumpTarget target) {
    return continueTargets.putIfAbsent(
        target, () => new ir.LabeledStatement(null));
  }

  ir.SwitchCase getContinueSwitchTarget(JumpTarget target) {
    return continueSwitchTargets[target];
  }

  ir.Statement buildBreakTarget(
      ir.Statement statement,
      Node node,
      JumpTarget jumpTarget) {
    assert(jumpTarget == elements.getTargetDefinition(node));
    if (jumpTarget != null && jumpTarget.isBreakTarget) {
      ir.LabeledStatement breakTarget = getBreakTarget(jumpTarget);
      breakTarget.body = statement;
      statement.parent = breakTarget;
      return breakTarget;
    } else {
      return statement;
    }
  }

  ir.Statement buildContinueTarget(
      ir.Statement statement,
      Node node,
      JumpTarget jumpTarget) {
    assert(jumpTarget == elements.getTargetDefinition(node));
    if (jumpTarget != null && jumpTarget.isContinueTarget) {
      ir.LabeledStatement continueTarget = getContinueTarget(jumpTarget);
      continueTarget.body = statement;
      statement.parent = continueTarget;
      return continueTarget;
    } else {
      return statement;
    }
  }

  ir.Statement buildForInCommon(
      ForIn node,
      ir.VariableDeclaration variable,
      ir.Statement body,
      {bool isAsync}) {
    ir.Expression iterable = node.expression.accept(this);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    body = buildContinueTarget(body, node, jumpTarget);
    return buildBreakTarget(
        new ir.ForInStatement(variable, iterable, body, isAsync: isAsync),
        node, jumpTarget);
  }

  /// Builds a for-in statement for this case:
  ///
  ///     for (constOrVarOrType loopVariable in expression) body
  ir.Statement buildForInWithDeclaration(
      ForIn node,
      VariableDefinitions declaration,
      {bool isAsync}) {
    ir.VariableDeclaration variable = buildStatementInBlock(declaration);
    return buildForInCommon(
        node, variable, buildStatementInBlock(node.body), isAsync: isAsync);
  }

  Accessor computeAccessor(ForIn node, Element element) {
    if (Elements.isError(element) || Elements.isMalformed(element)) {
      return new StaticAccessor(null, null);
    } else if (element.isGetter) {
      if (element.isInstanceMember) {
        return new ThisPropertyAccessor(kernel.irName(element.name, element));
      } else {
        GetterElement getter = element;
        Element setter = getter.setter;
        return new StaticAccessor(
            kernel.elementToIr(element),
            setter == null ? null : kernel.elementToIr(element));
      }
    } else if (element.isLocal) {
      return new VariableAccessor(getLocal(element));
    } else if (element.isField) {
      ir.Member member = kernel.elementToIr(element);
      return new StaticAccessor(
          member, (element.isFinal || element.isConst) ? null : member);
    } else {
      throw internalError(node, "Unhandled for-in variable: $element");
    }
  }

  /// Builds a for-in statement for this case:
  ///
  ///     for (element in expression) body
  ///
  /// This is normalized to:
  ///
  ///     for (final #t in expression) {
  ///       element = #t;
  ///       body;
  ///     }
  ir.Statement buildForInWithoutDeclaration(
      ForIn node,
      Element element,
      {bool isAsync}) {
    Accessor accessor = computeAccessor(node, elements.getForInVariable(node));
    // Since we've created [variable], we know it's only assigned to in the
    // loop header and can be final.
    ir.VariableDeclaration variable =
        new ir.VariableDeclaration.forValue(null, isFinal: true);
    ir.Statement assigment = new ir.ExpressionStatement(
        accessor.buildAssignment(
            new ir.VariableGet(variable), voidContext: true));
    ir.Block body = buildStatementInBlock(node.body, forceBlock: true);
    List<ir.Statement> statements = <ir.Statement>[assigment]
        ..addAll(body.statements);
    return buildForInCommon(
        node, variable, new ir.Block(statements), isAsync: isAsync);
  }

  ir.Statement buildForIn(ForIn node, {bool isAsync}) {
    VariableDefinitions declaration =
        node.declaredIdentifier.asVariableDefinitions();
    if (declaration != null) {
      return buildForInWithDeclaration(node, declaration, isAsync: isAsync);
    } else {
      Element element = elements.getForInVariable(node);
      return buildForInWithoutDeclaration(node, element, isAsync: isAsync);
    }
  }

  @override
  ir.Statement visitAsyncForIn(AsyncForIn node) {
    return buildForIn(node, isAsync: true);
  }

  @override
  ir.AwaitExpression visitAwait(Await node) {
    return new ir.AwaitExpression(node.expression.accept(this));
  }

  @override
  ir.Statement visitBlock(Block node) {
    return buildBreakTarget(
        buildStatementInBlock(node), node, elements.getTargetDefinition(node));
  }

  void buildStatement(Statement statement, List<ir.Statement> statements) {
    ir.Node irNode = statement.accept(this);
    if (irNode is VariableDeclarations) {
      statements.addAll(irNode.variables);
    } else {
      statements.add(irNode);
    }
  }

  ir.Statement buildStatementInBlock(
      Statement node,
      {bool forceBlock: false}) {
    if (node == null) return null;
    List<ir.Statement> statements = <ir.Statement>[];
    if (node is Block) {
      for (Node statement in node.statements.nodes) {
        buildStatement(statement, statements);
      }
    } else {
      buildStatement(node, statements);
      if (!forceBlock && statements.length == 1) {
        return statements.single;
      }
      // One VariableDefinitions statement node (dart2js AST) may generate
      // multiple statements in Kernel IR so we sometimes fall through here.
    }
    return new ir.Block(statements);
  }

  @override
  ir.BreakStatement visitBreakStatement(BreakStatement node) {
    return new ir.BreakStatement(getBreakTarget(elements.getTargetOf(node)));
  }

  CascadeReceiver computeCascadeReceiver(Cascade cascade) {
    CascadeReceiver receiver;
    Expression send = cascade.expression.asSend();
    while (send != null && (receiver = send.asCascadeReceiver()) == null) {
      Expression possibleReceiver = send.asSend()?.receiver;
      if (possibleReceiver != null) {
        send = possibleReceiver;
      } else {
        // Can happen in this case: `a..add(foo)('WHAT')`.
        send = send.asSend()?.selector;
      }
    }
    if (receiver == null) {
      internalError(cascade, "Can't find cascade receiver");
    }
    return receiver;
  }

  @override
  ir.Let visitCascade(Cascade node) {
    // Given this cascade expression `receiver..cascade1()..cascade2()`, the
    // parser has produced a tree like this:
    //     Cascade(Send(
    //         CascadeReceiver(Cascade(Send(
    //             CascadeRecevier(receiver), 'cascade1', []))),
    //         'cascade2', []))
    // If viewed as a tree, `CascadeReceiver(receiver)` is the left-most leaf
    // node.  Below, we create this:
    //     cascades = [
    //         Cascade(Send(CascadeReceiver(...), 'cascade2', [])),
    //         Cascade(Send(CascadeReceiver(...), 'cascade1', []))]
    // Notice that the cascades are in reverse order, which we use to build a
    // `let` expression bottom up.
    // First iteration of the loop produces:
    //     let dummy = rcv.cascade2() in
    //         rcv
    // Second iteration:
    //     let dummy = rcv.cascade1() in
    //         let dummy = rcv.cascade2() in
    //             rcv
    // Finally we return:
    //     let rcv = receiver in
    //         let dummy = rcv.cascade1() in
    //             let dummy = rcv.cascade2() in
    //                 rcv
    int startLength;
    assert((startLength = cascadeReceivers.length) >= 0);

    Cascade cascade = node;
    List<Cascade> cascades = <Cascade>[];
    CascadeReceiver receiver;
    ir.VariableDeclaration receiverVariable = makeOrReuseVariable(null);

    do {
      cascades.add(cascade);
      receiver = computeCascadeReceiver(cascade);
      cascadeReceivers[receiver] = new ir.VariableGet(receiverVariable);
      cascade = receiver.expression.asCascade();
    } while (cascade != null);
    // At this point, all nested [Cascades] targeting the same receiver have
    // been collected in [cascades] in reverse order. [receiver] is the
    // left-most receiver. [receiverVariable] will hold the value of evaluating
    // [receiver]. Each [CascadeReceiver] has a getter for [receiverVariable]
    // in [cascadeReceivers].

    receiverVariable.initializer = receiver.expression.accept(this);
    receiverVariable.initializer.parent = receiverVariable;

    ir.Expression result = new ir.VariableGet(receiverVariable); // rcv.
    for (Cascade cascade in cascades) {
      // When evaluating `cascade.expression`, we stop the recursion at
      // [visitCascadeReceiver] and instead returns an [ir.VariableGet].
      ir.Expression value = cascade.expression.accept(this);
      result = new ir.Let(makeOrReuseVariable(value), result);
    }

    assert(startLength == cascadeReceivers.length);
    return new ir.Let(receiverVariable, result);
  }

  @override
  ir.VariableGet visitCascadeReceiver(CascadeReceiver node) {
    return cascadeReceivers.remove(node);
  }

  @override
  ir.Throw visitCaseMatch(CaseMatch node) {
    return buildUnsupported(node, "CaseMatch");
  }

  @override
  ir.Catch visitCatchBlock(CatchBlock node) {
    ir.VariableDeclaration exception =
        (node.exception == null) ? null : getLocal(elements[node.exception]);
    ir.VariableDeclaration trace =
        (node.trace == null) ? null : getLocal(elements[node.trace]);
    ir.DartType guard = computeType(node.type);
    return new ir.Catch(
        exception, buildStatementInBlock(node.block), guard: guard,
        stackTrace: trace);
  }

  @override
  ir.ConditionalExpression visitConditional(Conditional node) {
    return new ir.ConditionalExpression(
        node.condition.accept(this),
        node.thenExpression.accept(this),
        node.elseExpression.accept(this));
  }

  @override
  ir.Statement visitContinueStatement(ContinueStatement node) {
    JumpTarget target = elements.getTargetOf(node);
    ir.SwitchCase switchCase = getContinueSwitchTarget(target);
    if (switchCase == null) {
      return new ir.BreakStatement(getContinueTarget(target));
    } else {
      return new ir.ContinueSwitchStatement(switchCase);
    }
  }

  @override
  ir.Statement visitDoWhile(DoWhile node) {
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body = buildContinueTarget(
        buildStatementInBlock(node.body), node, jumpTarget);
    ir.Expression condition = node.condition?.accept(this);
    return buildBreakTarget(
        new ir.DoStatement(body, condition), node, jumpTarget);
  }

  @override
  ir.EmptyStatement visitEmptyStatement(EmptyStatement node) {
    return new ir.EmptyStatement();
  }

  @override
  ir.Throw visitEnum(Enum node) {
    return buildUnsupported(node, "Enum");
  }

  @override
  ir.ExpressionStatement visitExpressionStatement(ExpressionStatement node) {
    return new ir.ExpressionStatement(node.expression.accept(this));
  }

  @override
  ir.Statement visitFor(For node) {
    VariableDefinitions initializers =
        node.initializer?.asVariableDefinitions();
    ir.Expression initializer;
    List<ir.VariableDeclaration> variables;
    if (initializers != null) {
      ir.Block block = buildStatementInBlock(initializers, forceBlock: true);
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

    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body = buildContinueTarget(
        buildStatementInBlock(node.body), node, jumpTarget);
    ir.ForStatement forStatement = new ir.ForStatement(
        variables, condition, updates, body);
    ir.Statement result = buildBreakTarget(forStatement, node, jumpTarget);
    if (initializer != null) {
      result = new ir.Block(<ir.Statement>[
          new ir.ExpressionStatement(initializer), result]);
    }
    return result;
  }

  @override
  ir.VariableDeclaration visitFunctionDeclaration(FunctionDeclaration node) {
    return node.function.accept(this);
  }

  @override
  ir.Statement visitIf(If node) {
    return buildBreakTarget(
        new ir.IfStatement(
            node.condition.accept(this),
            buildStatementInBlock(node.thenPart),
            buildStatementInBlock(node.elsePart)),
        node, elements.getTargetDefinition(node));
  }

  @override
  ir.Throw visitLabel(Label node) {
    return buildUnsupported(node, "Label");
  }

  @override
  ir.Statement visitLabeledStatement(LabeledStatement node) {
    Statement statement = node.statement;
    ir.Statement result = (statement is Block)
        // If [statement] is a Block, we need to ensure that we don't bypass
        // its visit method (so it can build break targets correctly).
        ? statement.accept(this)
        : buildStatementInBlock(statement);

    // A [LabeledStatement] isn't the actual jump target, instead, [statement]
    // is the target. This allows uniform handling of break and continue in
    // loops. The following code simply assert that [result] has been generated
    // correctly with respect to jump targets.
    JumpTarget jumpTarget = elements.getTargetDefinition(node.statement);
    if (jumpTarget != null) {
      if (jumpTarget.isBreakTarget) {
        ir.LabeledStatement target = getBreakTarget(jumpTarget);
        if (target != result && target.parent == null) {
          internalError(node, "no parent");
        }
      }
      if (jumpTarget.isContinueTarget) {
        ir.LabeledStatement target = getContinueTarget(jumpTarget);
        if (target != result && target.parent == null) {
          internalError(node, "no parent");
        }
      }
    }

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
    return new ir.ListLiteral(
        elements, typeArgument: computeTypeFromTypes(node.typeArguments),
        // TODO(ahe): Should constness be validated?
        isConst: node.isConst);
  }

  @override
  ir.MapLiteral visitLiteralMap(LiteralMap node) {
    // TODO(ahe): Type arguments.
    List<ir.MapEntry> entries = <ir.MapEntry>[];
    for (LiteralMapEntry entry in node.entries.nodes) {
      entries.add(
          new ir.MapEntry(entry.key.accept(this), entry.value.accept(this)));
    }
    List<ir.DartType> typeArguments =
        computeTypesFromTypes(node.typeArguments, expected: 2);
    return new ir.MapLiteral(
        entries, keyType: typeArguments.first, valueType: typeArguments.last,
        // TODO(ahe): Should Constness be validated?
        isConst: node.isConst);
  }

  @override
  ir.Throw visitLiteralMapEntry(LiteralMapEntry node) {
    return buildUnsupported(node, "LiteralMapEntry");
  }

  @override
  ir.NullLiteral visitLiteralNull(LiteralNull node) {
    return new ir.NullLiteral();
  }

  @override
  ir.Expression visitLiteralString(LiteralString node) {
    if (node.dartString == null) return new ir.InvalidExpression();
    return new ir.StringLiteral(node.dartString.slowToString());
  }

  @override
  ir.SymbolLiteral visitLiteralSymbol(LiteralSymbol node) {
    return new ir.SymbolLiteral(node.slowNameString);
  }

  @override
  ir.Throw visitMetadata(Metadata node) {
    return buildUnsupported(node, "Metadata");
  }

  @override
  ir.NamedExpression visitNamedArgument(NamedArgument node) {
    return new ir.NamedExpression(
        node.name.source, node.expression.accept(this));
  }

  @override
  ir.Throw visitOperator(Operator node) {
    return buildUnsupported(node, "Operator");
  }

  @override
  ir.Expression visitParenthesizedExpression(ParenthesizedExpression node) {
    return node.expression.accept(this);
  }

  @override
  ir.Throw visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    return buildUnsupported(node, "RedirectingFactoryBody");
  }

  @override
  ir.ExpressionStatement visitRethrow(Rethrow node) {
    return new ir.ExpressionStatement(new ir.Rethrow());
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
  ir.SwitchCase visitSwitchCase(SwitchCase node) {
    List<ir.Expression> expressions = <ir.Expression>[];
    for (var labelOrCase in node.labelsAndCases.nodes) {
      CaseMatch match = labelOrCase.asCaseMatch();
      if (match != null) {
        expressions.add(match.expression.accept(this));
      } else {
        // Assert that labelOrCase is one of two known types: [CaseMatch] or
        // [Label]. We ignore cases, as any users have been resolved to use the
        // case directly.
        assert(labelOrCase.asLabel() != null);
      }
    }
    // We ignore the node's statements here, they're generated below in
    // [visitSwitchStatement] once we've set up all the jump targets.
    return new ir.SwitchCase(expressions, null, isDefault: node.isDefaultCase);
  }

  @override
  ir.Statement visitSwitchStatement(SwitchStatement node) {
    ir.Expression expression = node.expression.accept(this);
    List<ir.SwitchCase> cases = <ir.SwitchCase>[];
    for (SwitchCase caseNode in node.cases.nodes) {
      cases.add(caseNode.accept(this));
      JumpTarget jumpTarget = elements.getTargetDefinition(caseNode);
      if (jumpTarget != null) {
        assert(jumpTarget.isContinueTarget);
        assert(!continueSwitchTargets.containsKey(jumpTarget));
        continueSwitchTargets[jumpTarget] = cases.last;
      }
    }

    Iterator<ir.SwitchCase> casesIterator = cases.iterator;
    for (SwitchCase caseNode in node.cases.nodes) {
      if (!casesIterator.moveNext()) {
        internalError(caseNode, "case node mismatch");
      }
      ir.SwitchCase irCase = casesIterator.current;
      List<ir.Statement> statements = <ir.Statement>[];
      for (Statement statement in caseNode.statements.nodes) {
        buildStatement(statement, statements);
      }
      ir.Statement body;
      if (statements.length == 1) {
        body = statements.single;
      } else {
        body = new ir.Block(statements);
      }
      irCase.body = body;
      body.parent = irCase;
    }
    assert(!casesIterator.moveNext());

    return buildBreakTarget(
        new ir.SwitchStatement(expression, cases),
        node, elements.getTargetDefinition(node));
  }

  @override
  ir.Statement visitSyncForIn(SyncForIn node) {
    return buildForIn(node, isAsync: false);
  }

  @override
  ir.Throw visitThrow(Throw node) {
    return new ir.Throw(node?.expression?.accept(this));
  }

  @override
  ir.Statement visitTryStatement(TryStatement node) {
    ir.Statement result = buildStatementInBlock(node.tryBlock);
    if (node.catchBlocks != null && !node.catchBlocks.isEmpty) {
      List<ir.Catch> catchBlocks = <ir.Catch>[];
      for (CatchBlock block in node.catchBlocks.nodes) {
        catchBlocks.add(block.accept(this));
      }
      result = new ir.TryCatch(result, catchBlocks);
    }
    if (node.finallyBlock != null) {
      result =
          new ir.TryFinally(result, buildStatementInBlock(node.finallyBlock));
    }
    return result;
  }

  @override
  ir.Throw visitTypeAnnotation(TypeAnnotation node) {
    return buildUnsupported(node, "TypeAnnotation");
  }

  @override
  ir.Throw visitTypeVariable(TypeVariable node) {
    return buildUnsupported(node, "TypeVariable");
  }

  @override
  ir.Statement visitWhile(While node) {
    ir.Expression condition = node.condition?.accept(this);
    JumpTarget jumpTarget = elements.getTargetDefinition(node);
    ir.Statement body = buildContinueTarget(
        buildStatementInBlock(node.body), node, jumpTarget);
    return buildBreakTarget(
        new ir.WhileStatement(condition, body), node, jumpTarget);
  }

  @override
  ir.YieldStatement visitYield(Yield node) {
    return new ir.YieldStatement(
        node.expression.accept(this), isYieldStar: node.hasStar);
  }

  @override
  ir.Throw visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement element,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "AbstractClassConstructorInvoke");
  }

  IrFunction buildIrFunction(
      ir.ProcedureKind kind,
      FunctionElement function,
      Node body) {
    return new IrFunction.procedure(kind, buildFunctionNode(function, body));
  }

  @override
  IrFunction visitAbstractGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, null);
  }

  @override
  IrFunction visitAbstractSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, null);
  }

  @override
  ir.AsExpression visitAs(Send node, Node expression, DartType type, _) {
    return new ir.AsExpression(expression.accept(this), kernel.typeToIr(type));
  }

  @override
  ir.MethodInvocation visitBinary(
      Send node, Node left, BinaryOperator operator, Node right, _) {
    return buildBinaryOperator(left, operator.name, right);
  }

  ir.Expression buildConstConstructorInvoke(NewExpression node) {
    // TODO(ahe): Should SemanticVisitor provide target and effectiveTarget?
    ConstructorElement target = elements[node.send];
    ConstructorElement effectiveTarget = target.effectiveTarget;
    NodeList arguments = node.send.argumentsNode;
    if (effectiveTarget.isGenerativeConstructor) {
      return buildGenerativeConstructorInvoke(
          effectiveTarget, arguments, isConst: true);
    } else {
      return buildStaticInvoke(effectiveTarget, arguments, isConst: true);
    }
  }

  @override
  ir.Expression visitBoolFromEnvironmentConstructorInvoke(
      NewExpression node,
      BoolFromEnvironmentConstantExpression constant,
      _) {
    return buildConstConstructorInvoke(node);
  }

  @override
  ir.TypeLiteral visitClassTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return new ir.TypeLiteral(kernel.typeLiteralToIr(constant));
  }

  @override
  ir.Throw visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "ClassTypeLiteralInvoke");
  }

  @override
  ir.Throw visitClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "ClassTypeLiteralSet");
  }

  @override
  ir.Throw visitClassTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "ClassTypeLiteralSetIfNull");
  }

  @override ir.FunctionExpression visitClosureDeclaration(
      FunctionExpression node,
      LocalFunctionElement closure,
      NodeList parameters,
      Node body,
      _) {
    return withCurrentElement(closure, () {
      return new ir.FunctionExpression(buildFunctionNode(closure, body));
    });
  }

  @override
  ir.Expression visitCompoundIndexSet(
      SendSet node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      _) {
    return buildIndexAccessor(receiver, index).buildCompoundAssignment(
        kernel.irName(operator.name, currentElement), rhs.accept(this));
  }

  @override
  ir.Expression visitConstConstructorInvoke(
      NewExpression node,
      ConstructedConstantExpression constant,
      _) {
    return buildConstConstructorInvoke(node);
  }

  @override
  ir.Throw visitConstantGet(Send node, ConstantExpression constant, _) {
    return buildUnsupported(node, "ConstantGet");
  }

  @override
  ir.Throw visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "ConstantInvoke");
  }

  @override
  ir.InvalidExpression visitConstructorIncompatibleInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.InvalidExpression();
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
    return buildInvokeSelector(
        receiver.accept(this), selector, buildArguments(arguments));
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
    return buildCompound(
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
  ir.Expression visitDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    ir.Name irName = kernel.nameToIrName(name);
    return PropertyAccessor.make(receiver.accept(this), irName)
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  ir.Throw visitDynamicTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return buildUnsupported(node, "DynamicTypeLiteralGet");
  }

  @override
  ir.Throw visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "DynamicTypeLiteralInvoke");
  }

  @override
  ir.Throw visitDynamicTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "DynamicTypeLiteralSet");
  }

  @override
  ir.Throw visitDynamicTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "DynamicTypeLiteralSetIfNull");
  }

  ir.MethodInvocation buildBinaryOperator(
      Node left,
      String operator,
      Node right) {
    ir.Name name = kernel.irName(operator, currentElement);
    return makeBinary(left.accept(this), name, right.accept(this));
  }

  @override
  ir.MethodInvocation visitEquals(Send node, Node left, Node right, _) {
    return buildBinaryOperator(left, '==', right);
  }

  @override
  ir.MethodInvocation visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildInvokeSelector(
        expression.accept(this), callStructure.callSelector,
        buildArguments(arguments));
  }

  @override
  IrFunction visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Factory, constructor, body);
  }

  @override
  ir.StaticInvocation visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildStaticInvoke(constructor, arguments, isConst: false);
  }

  @override
  ir.FieldInitializer visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node expression,
      _) {
    return new ir.FieldInitializer(
        kernel.fieldToIr(field), expression.accept(this));
  }

  @override
  ir.Throw visitFinalLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return buildUnsupported(node, "FinalLocalVariableSetIfNull");
  }

  @override
  ir.Throw visitFinalParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return buildUnsupported(node, "FinalParameterSetIfNull");
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
    return buildUnsupported(node, "FinalStaticFieldSetIfNull");
  }

  @override
  ir.Throw visitFinalSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildUnsupported(node, "FinalSuperFieldSet");
  }

  @override
  ir.Throw visitFinalSuperFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return buildUnsupported(node, "FinalSuperFieldSetIfNull");
  }

  @override
  ir.Throw visitFinalTopLevelFieldSetIfNull(
      Send node,
      FieldElement field,
      Node rhs,
      _) {
    return buildUnsupported(node, "FinalTopLevelFieldSetIfNull");
  }

  IrFunction buildGenerativeConstructor(
      ConstructorElement constructor,
      Node body) {
    List<ir.Initializer> constructorInitializers = <ir.Initializer>[];
    if (constructor.enclosingClass.hasIncompleteHierarchy) {
      constructorInitializers.add(new ir.InvalidInitializer());
    } else if (constructor.isSynthesized) {
      List<ir.Expression> arguments = const <ir.Expression>[];
      List<ir.NamedExpression> named = const <ir.NamedExpression>[];
      FunctionSignature signature = constructor.functionSignature;
      if (signature.parameterCount != 0) {
        // Mixin application implicit super call.
        arguments = <ir.Expression>[];
        named = <ir.NamedExpression>[];
        signature.orderedForEachParameter((ParameterElement parameter) {
          ir.VariableGet argument = buildLocalGet(parameter);
          if (parameter.isNamed) {
            named.add(new ir.NamedExpression(parameter.name, argument));
          } else {
            arguments.add(argument);
          }
        });
      }
      if (constructor.definingConstructor.isMalformed) {
        constructorInitializers.add(new ir.InvalidInitializer());
      } else {
        constructorInitializers.add(
            new ir.SuperInitializer(
                kernel.functionToIr(constructor.definingConstructor),
                new ir.Arguments(
                    arguments, named: named,
                    types: kernel.typeArgumentsNotImplemented())));
      }
    } else {
      // TODO(ahe): the following is a (modified) copy of
      // [SemanticDeclarationVisitor.visitInitializers].
      InitializersStructure initializers =
          computeInitializersStructure(constructor.node);
      for (InitializerStructure structure in initializers.initializers) {
        constructorInitializers.add(structure.dispatch(declVisitor, null));
      }
    }
    return new IrFunction.constructor(
        buildFunctionNode(constructor, body), constructorInitializers);
  }

  @override
  IrFunction visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      _) {
    return buildGenerativeConstructor(constructor, body);
  }

  ir.ConstructorInvocation buildGenerativeConstructorInvoke(
      ConstructorElement constructor,
      NodeList arguments,
      {bool isConst}) {
    if (const bool.fromEnvironment("require_kernel_arguments")) {
      // Check that all constructors from kernel/ast.dart (that are invoked
      // from this package) provide all arguments (including optional
      // arguments).
      // TODO(ahe): Remove this when the implementation has matured.
      if (("package:kernel/ast.dart" ==
           "${constructor.library.canonicalUri}") &&
          "${currentElement.library.canonicalUri}".startsWith(
              "package:rasta/")) {
        if (constructor.functionSignature.parameterCount !=
            arguments.slowLength()) {
          kernel.debugMessage(arguments, "Missing arguments");
          kernel.debugMessage(constructor, "When calling the constructor");
        }
      }
    }
    ir.Arguments argumentsNode = buildArguments(arguments);
    ir.Constructor target = kernel.functionToIr(constructor);
    return new ir.ConstructorInvocation(
        target, argumentsNode, isConst: isConst);
  }

  @override
  ir.ConstructorInvocation visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildGenerativeConstructorInvoke(
        constructor, arguments, isConst: false);
  }

  Accessor buildNullAwarePropertyAccessor(Node receiver, Name name) {
    return new NullAwarePropertyAccessor(
        receiver.accept(this), kernel.nameToIrName(name));
  }

  @override
  ir.Expression visitIfNotNullDynamicPropertyGet(
      Send node,
      Node receiver,
      Name name,
      _) {
    return buildNullAwarePropertyAccessor(receiver, name).buildSimpleRead();
  }

  @override
  ir.Let visitIfNotNullDynamicPropertyInvoke(
      Send node,
      Node receiverNode,
      NodeList arguments,
      Selector selector,
      _) {
    ir.VariableDeclaration receiver =
        makeOrReuseVariable(receiverNode.accept(this));
    return makeLet(
        receiver,
        new ir.ConditionalExpression(
            buildIsNull(new ir.VariableGet(receiver)),
            new ir.NullLiteral(),
            buildInvokeSelector(
                new ir.VariableGet(receiver), selector,
                buildArguments(arguments))));
  }

  @override
  ir.Expression visitIfNotNullDynamicPropertySet(
      SendSet node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return buildNullAwarePropertyAccessor(receiver, name).buildAssignment(
        rhs.accept(this));
  }

  @override
  ir.Throw visitIfNotNullDynamicPropertySetIfNull(
      Send node,
      Node receiver,
      Name name,
      Node rhs,
      _) {
    return buildNullAwarePropertyAccessor(receiver, name)
        .buildNullAwareAssignment(rhs.accept(this));
  }

  ir.LogicalExpression buildLogicalExpression(
      Node left,
      Operator operator,
      Node right) {
    return new ir.LogicalExpression(
        left.accept(this), operator.source, right.accept(this));
  }

  @override
  ir.LogicalExpression visitIfNull(Send node, Node left, Node right, _) {
    return buildLogicalExpression(left, node.selector, right);
  }

  @override
  ir.SuperInitializer visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      InterfaceType type,
      _) {
    return new ir.SuperInitializer(
        kernel.functionToIr(superConstructor),
        new ir.Arguments.empty());
  }

  Accessor buildIndexAccessor(Node receiver, Node index) {
    return IndexAccessor.make(receiver.accept(this), index.accept(this));
  }

  @override
  ir.Expression visitIndex(Send node, Node receiver, Node index, _) {
    return buildIndexAccessor(receiver, index).buildSimpleRead();
  }

  @override
  ir.Expression visitIndexPostfix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    Accessor accessor = buildIndexAccessor(receiver, index);
    ir.Name name = kernel.irName(operator.name, currentElement);
    return accessor.buildPostfixIncrement(name);
  }

  @override
  ir.Expression visitIndexPrefix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      _) {
    Accessor accessor = buildIndexAccessor(receiver, index);
    ir.Name name = kernel.irName(operator.name, currentElement);
    return accessor.buildPrefixIncrement(name);
  }

  @override
  ir.Expression visitIndexSet(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return buildIndexAccessor(receiver, index)
        .buildAssignment(rhs.accept(this));
  }

  @override
  ir.Throw visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      int index,
      _) {
    return buildUnsupported(node, "InitializingFormalDeclaration");
  }

  @override
  ir.Throw visitInstanceFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return buildUnsupported(node, "InstanceFieldDeclaration");
  }

  @override
  IrFunction visitInstanceGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  @override
  IrFunction visitInstanceSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  @override
  ir.Expression visitIntFromEnvironmentConstructorInvoke(
      NewExpression node,
      IntFromEnvironmentConstantExpression constant,
      _) {
    return buildConstConstructorInvoke(node);
  }

  ir.IsExpression buildIs(Node expression, DartType type) {
    return new ir.IsExpression(expression.accept(this), kernel.typeToIr(type));
  }

  @override
  ir.IsExpression visitIs(Send node, Node expression, DartType type, _) {
    return buildIs(expression, type);
  }

  @override
  ir.Not visitIsNot(Send node, Node expression, DartType type, _) {
    return new ir.Not(buildIs(expression, type));
  }

  ir.VariableDeclaration buildLocalVariableDeclaration(
      LocalVariableElement variable, Node initializer) {
    ir.Expression initializerNode = initializer?.accept(this);
    ir.VariableDeclaration local = getLocal(variable);
    if (initializer != null) {
      local.initializer = initializerNode;
      initializerNode.parent = local;
    }
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
    return buildLocalVariableDeclaration(variable, variable.initializer)
        ..isConst = true;
  }

  @override
  ir.VariableDeclaration visitLocalFunctionDeclaration(
      FunctionExpression node,
      LocalFunctionElement localFunction,
      NodeList parameters,
      Node body,
      _) {
    return withCurrentElement(localFunction, () {
      ir.VariableDeclaration local = getLocal(localFunction);
      ir.FunctionExpression expression =
          new ir.FunctionExpression(buildFunctionNode(localFunction, body));
      local.initializer = expression;
      expression.parent = local;
      return local;
    });
  }

  @override
  ir.Throw visitLocalFunctionSetIfNull(
      Send node,
      LocalFunctionElement function,
      Node rhs,
      _) {
    return buildUnsupported(node, "LocalFunctionSetIfNull");
  }

  @override
  ir.VariableDeclaration visitLocalVariableDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      Node initializer,
      _) {
    return buildLocalVariableDeclaration(variable, initializer);
  }

  ir.VariableGet buildLocalGet(LocalElement local) {
    return new ir.VariableGet(getLocal(local));
  }

  @override
  ir.VariableGet handleLocalGet(Send node, LocalElement element, _) {
    return buildLocalGet(element);
  }

  ir.Expression buildCompound(Accessor accessor, CompoundRhs rhs) {
    ir.Name name = kernel.irName(rhs.operator.name, currentElement);
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
    return buildCompound(new VariableAccessor(getLocal(local)), rhs);
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
    // TODO(ahe): Build invalid?
    return handleLocalSet(node, element, rhs, _);
  }

  @override
  ir.Expression visitLocalVariableSetIfNull(
      Send node,
      LocalVariableElement variable,
      Node rhs,
      _) {
    return new VariableAccessor(getLocal(variable))
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  ir.LogicalExpression visitLogicalAnd(Send node, Node left, Node right, _) {
    return buildLogicalExpression(left, node.selector, right);
  }

  @override
  ir.LogicalExpression visitLogicalOr(Send node, Node left, Node right, _) {
    return buildLogicalExpression(left, node.selector, right);
  }

  @override
  ir.Throw visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      _) {
    return buildUnsupported(node, "NamedInitializingFormalDeclaration");
  }

  @override
  ir.Throw visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      _) {
    return buildUnsupported(node, "NamedParameterDeclaration");
  }

  @override
  ir.Not visitNot(Send node, Node expression, _) {
    return new ir.Not(expression.accept(this));
  }

  @override
  ir.Not visitNotEquals(Send node, Node left, Node right, _) {
    return new ir.Not(buildBinaryOperator(left, '==', right));
  }

  @override
  ir.Throw visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return buildUnsupported(node, "OptionalInitializingFormalDeclaration");
  }

  @override
  ir.Throw visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      _) {
    return buildUnsupported(node, "OptionalParameterDeclaration");
  }

  @override
  ir.Throw visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      _) {
    return buildUnsupported(node, "ParameterDeclaration");
  }

  @override
  ir.MethodInvocation handleLocalInvoke(
      Send node,
      LocalElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildInvokeSelector(
        buildLocalGet(element), callStructure.callSelector,
        buildArguments(arguments));
  }

  @override
  ir.ConditionalExpression visitParameterSetIfNull(
      Send node,
      ParameterElement parameter,
      Node rhs,
      _) {
    return new VariableAccessor(getLocal(parameter))
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  IrFunction visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      DartType redirectionType, // TODO(ahe): Should be InterfaceType.
      ConstructorElement redirectionTarget,
      _) {
    if (!constructor.isFactoryConstructor) {
      // TODO(ahe): This seems like a bug in semantic visitor and how it
      // recovers from a bad constructor.
      return new IrFunction.constructor(
          buildFunctionNode(constructor, null),
          <ir.Initializer>[new ir.InvalidInitializer()]);
    }
    ir.Statement body = null;
    if (redirectionTarget.isMalformed) {
      body = new ir.InvalidStatement();
    } else {
      // TODO(ahe): This should be implemented, but doesn't matter much unless
      // we support reflection. At the call-site, we bypass this factory and
      // call its effective target directly. So this factory is only necessary
      // for reflection.
      body = buildUnsupportedStatement(
          node, "redirecting factory constructor body.");
    }
    IrFunction function =
        buildIrFunction(ir.ProcedureKind.Factory, constructor, null);
    function.node.body = body..parent = function.node;
    return function;
  }

  @override
  ir.Expression visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      ConstructorElement effectiveTarget,
      InterfaceType effectiveTargetType,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    if (effectiveTarget.isGenerativeConstructor) {
      return buildGenerativeConstructorInvoke(
          effectiveTarget, arguments, isConst: false);
    } else {
      return buildStaticInvoke(effectiveTarget, arguments, isConst: false);
    }
  }

  @override
  IrFunction
  visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      _) {
    return buildGenerativeConstructor(constructor, null);
  }

  @override
  ir.ConstructorInvocation visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildGenerativeConstructorInvoke(
        constructor, arguments, isConst: false);
  }

  @override
  ir.Throw visitStaticConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return buildUnsupported(node, "StaticConstantDeclaration");
  }

  @override
  ir.Throw visitStaticFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return buildUnsupported(node, "StaticFieldDeclaration");
  }

  ir.StaticGet buildStaticGet(Element element) {
    return new ir.StaticGet(kernel.elementToIr(element));
  }

  @override
  ir.StaticGet handleStaticFieldGet(Send node, FieldElement field, _) {
    return buildStaticGet(field);
  }

  @override
  ir.MethodInvocation handleStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildInvokeSelector(
        buildStaticGet(field), callStructure.callSelector,
        buildArguments(arguments));
  }

  @override
  ir.StaticSet handleStaticFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return new ir.StaticSet(kernel.fieldToIr(field), rhs.accept(this));
  }

  @override
  ir.Throw visitStaticFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return buildUnsupported(node, "StaticFieldSetIfNull");
  }

  ir.VariableDeclaration getLocal(LocalElement local) {
    return locals.putIfAbsent(local, () {
      return new ir.VariableDeclaration(
          local.name, initializer: null, type: typeToIrHack(local.type),
          isFinal: local.isFinal, isConst: local.isConst);
    });
  }

  ir.FunctionNode buildFunctionNode(FunctionElement function, Node bodyNode) {
    ir.Statement body = (bodyNode == null)
        ? null : buildStatementInBlock(bodyNode);
    List<ir.VariableDeclaration> positionalParameters =
        <ir.VariableDeclaration>[];
    List<ir.VariableDeclaration> namedParameters = <ir.VariableDeclaration>[];
    int requiredParameterCount = 0;
    ir.DartType returnType = null;
    if (function.hasFunctionSignature) {
      FunctionSignature signature = function.functionSignature;
      requiredParameterCount = signature.requiredParameterCount;
      signature.forEachParameter((ParameterElement parameter) {
        ir.VariableDeclaration variable = getLocal(parameter);
        if (parameter.isNamed) {
          namedParameters.add(variable);
        } else {
          positionalParameters.add(variable);
        }
      });
      signature.forEachParameter((ParameterElement parameter) {
        ir.Expression initializer = parameter.initializer?.accept(this);
        ir.VariableDeclaration variable = getLocal(parameter);
        if (initializer != null) {
          variable.initializer = initializer;
          initializer.parent = variable;
        }
      });
      returnType = typeToIrHack(signature.type.returnType);
    }
    ir.AsyncMarker asyncMarker = ir.AsyncMarker.Sync;
    if (!function.isMalformed) {
      switch (function.asyncMarker) {
        case AsyncMarker.SYNC:
          asyncMarker = ir.AsyncMarker.Sync;
          break;

        case AsyncMarker.SYNC_STAR:
          asyncMarker = ir.AsyncMarker.SyncStar;
          break;

        case AsyncMarker.ASYNC:
          asyncMarker = ir.AsyncMarker.Async;
          break;

        case AsyncMarker.ASYNC_STAR:
          asyncMarker = ir.AsyncMarker.AsyncStar;
          break;

        default:
          internalError(
              function, "Unknown async maker: ${function.asyncMarker}");
          break;
      }
    }
    return new ir.FunctionNode(
        body, asyncMarker: asyncMarker,
        returnType: returnType,
        typeParameters: kernel.typeParametersNotImplemented(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount);
  }

  @override
  IrFunction visitStaticFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Method, function, body);
  }

  ir.ProcedureKind computeInstanceMethodKind(MethodElement method) {
    assert(method.isFunction);
    if (method.isOperator) {
      if (method.name == '[]') {
        return ir.ProcedureKind.IndexGetter;
      } else if (method.name == '[]=') {
        return ir.ProcedureKind.IndexSetter;
      } else {
        return ir.ProcedureKind.Operator;
      }
    } else {
      return ir.ProcedureKind.Method;
    }
  }

  @override
  IrFunction visitInstanceMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(
        computeInstanceMethodKind(currentElement), currentElement, body);
  }

  @override
  IrFunction visitAbstractMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      _) {
    return buildIrFunction(
        computeInstanceMethodKind(currentElement), currentElement, null);
  }

  @override
  ir.StaticGet handleStaticFunctionGet(Send node, MethodElement function, _) {
    return buildStaticGet(function);
  }

  @override
  ir.StaticInvocation handleStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildStaticInvoke(function, arguments, isConst: false);
  }

  ir.StaticInvocation buildStaticInvoke(
      FunctionElement function,
      NodeList arguments,
      {bool isConst}) {
    ir.Arguments argumentsNode = buildArguments(arguments);
    return new ir.StaticInvocation(
        kernel.functionToIr(function), argumentsNode, isConst: isConst);
  }

  @override
  ir.StaticInvocation handleStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildStaticInvoke(function, arguments, isConst: false);
  }

  @override
  ir.Throw handleStaticFunctionSet(
      Send node, MethodElement function, Node rhs, _) {
    return buildUnsupported(node, "StaticFunctionSet");
  }

  @override
  IrFunction visitStaticGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  ir.StaticInvocation buildStaticGetterGet(FunctionElement getter) {
    return new ir.StaticInvocation(
        kernel.functionToIr(getter), new ir.Arguments.empty(), isConst: false);
  }

  @override
  ir.StaticInvocation handleStaticGetterGet(
      Send node,
      FunctionElement getter,
      _) {
    return buildStaticGetterGet(getter);
  }

  @override
  ir.MethodInvocation handleStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildInvokeSelector(
        buildStaticGetterGet(getter), callStructure.callSelector,
        buildArguments(arguments));
  }

  @override
  ir.Throw handleStaticGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return buildUnsupported(node, "StaticGetterSet");
  }

  @override
  ir.Throw visitStaticGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "StaticGetterSetterSetIfNull");
  }

  @override
  ir.Throw visitStaticMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return buildUnsupported(node, "StaticMethodSetIfNull");
  }

  @override
  ir.Throw visitStaticMethodSetterSetIfNull(
      Send node,
      MethodElement method,
      MethodElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "StaticMethodSetterSetIfNull");
  }

  @override
  IrFunction visitStaticSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  @override
  ir.Throw handleStaticSetterGet(Send node, FunctionElement setter, _) {
    return buildUnsupported(node, "StaticSetterGet");
  }

  @override
  ir.Throw handleStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "StaticSetterInvoke");
  }

  @override
  ir.StaticInvocation handleStaticSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return new ir.StaticInvocation(
        kernel.functionToIr(setter),
        new ir.Arguments(
            <ir.Expression>[rhs.accept(this)], types: null, named: null),
        isConst: false);
  }

  @override
  ir.Expression visitStringFromEnvironmentConstructorInvoke(
      NewExpression node,
      StringFromEnvironmentConstantExpression constant,
      _) {
    return buildConstConstructorInvoke(node);
  }

  @override
  ir.Throw visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      _) {
    return buildUnsupported(node, "SuperBinary");
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
    return buildUnsupported(node, "SuperCompoundIndexSet");
  }

  @override
  ir.SuperInitializer visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.SuperInitializer(
        kernel.functionToIr(superConstructor),
        buildArguments(arguments));
  }

  @override
  ir.StaticInvocation visitSuperEquals(
      Send node, FunctionElement function, Node argument, _) {
    return new ir.StaticInvocation(
        kernel.functionToIr(function),
        new ir.Arguments(
            <ir.Expression>[argument.accept(this)], types: null, named: null),
        isConst: false);
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
    return buildUnsupported(node, "SuperCompounds ${rhs.kind}");
  }

  @override
  ir.Expression handleStaticCompounds(
      SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    return buildCompound(
        new StaticAccessor(
            kernel.elementToIr(getter), kernel.elementToIr(setter)),
        rhs);
  }

  @override
  ir.Throw handleTypeLiteralConstantCompounds(
      SendSet node,
      ConstantExpression constant,
      CompoundRhs rhs,
      _) {
    return buildUnsupported(node, "TypeLiteralConstantCompounds ${rhs.kind}");
  }

  @override
  ir.Throw handleTypeVariableTypeLiteralCompounds(
      SendSet node,
      TypeVariableElement typeVariable,
      CompoundRhs rhs,
      _) {
    return buildUnsupported(
        node, "TypeVariableTypeLiteralCompounds ${rhs.kind}");
  }

  @override
  ir.Throw visitSuperFieldFieldSetIfNull(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperFieldFieldSetIfNull");
  }

  @override
  ir.SuperPropertyGet visitSuperFieldGet(Send node, FieldElement field, _) {
    return buildSuperPropertyAccessor(field).buildSimpleRead();
  }

  @override
  ir.MethodInvocation visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildInvokeSelector(
        buildSuperPropertyAccessor(field).buildSimpleRead(),
        callStructure.callSelector, buildArguments(arguments));
  }

  @override
  ir.Expression visitSuperFieldSet(
      SendSet node, FieldElement field, Node rhs, _) {
    return buildSuperPropertyAccessor(field).buildAssignment(rhs.accept(this));
  }

  @override
  ir.Expression visitSuperFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return buildSuperPropertyAccessor(field)
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  ir.Throw visitSuperFieldSetterSetIfNull(
      Send node,
      FieldElement field,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperFieldSetterSetIfNull");
  }

  @override
  ir.Throw visitSuperGetterFieldSetIfNull(
      Send node,
      FunctionElement getter,
      FieldElement field,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperGetterFieldSetIfNull");
  }

  Accessor buildSuperPropertyAccessor(Element getter, [Element setter]) {
    return new SuperPropertyAccessor(
        (getter == null) ? null : kernel.elementToIr(getter),
        (setter == null) ? null : kernel.elementToIr(setter));
  }

  Accessor buildSuperIndexAccessor(
      Expression index,
      Element read,
      [Element write]) {
    return new SuperIndexAccessor(
        index.accept(this),
        kernel.elementToIr(read),
        (write == null) ? null : kernel.elementToIr(write));
  }

  @override
  ir.SuperPropertyGet visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      _) {
    return buildSuperPropertyAccessor(getter).buildSimpleRead();
  }

  @override
  ir.Throw visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "SuperGetterInvoke");
  }

  @override
  ir.Throw visitSuperGetterSet(
      SendSet node, FunctionElement getter, Node rhs, _) {
    return buildUnsupported(node, "SuperGetterSet");
  }

  @override
  ir.Throw visitSuperGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperGetterSetterSetIfNull");
  }

  @override
  ir.SuperMethodInvocation visitSuperIndex(
      Send node, FunctionElement function, Node index, _) {
    return buildSuperIndexAccessor(index, function).buildSimpleRead();
  }

  @override
  ir.Throw visitSuperIndexPostfix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return buildUnsupported(node, "SuperIndexPostfix");
  }

  @override
  ir.Throw visitSuperIndexPrefix(
      Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      _) {
    return buildUnsupported(node, "SuperIndexPrefix");
  }

  @override
  ir.Throw visitSuperIndexSet(
      SendSet node,
      FunctionElement function,
      Node index,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperIndexSet");
  }

  @override
  ir.Throw visitSuperMethodGet(Send node, MethodElement method, _) {
    return buildUnsupported(node, "SuperMethodGet");
  }

  @override
  ir.Throw visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "SuperMethodIncompatibleInvoke");
  }

  @override
  ir.SuperMethodInvocation visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.SuperMethodInvocation(
        kernel.functionToIr(method), buildArguments(arguments));
  }

  @override
  ir.Throw visitSuperMethodSet(
      Send node, MethodElement method, Node rhs, _) {
    return buildUnsupported(node, "SuperMethodSet");
  }

  @override
  ir.Throw visitSuperMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperMethodSetIfNull");
  }


  @override
  ir.Throw visitSuperMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "SuperMethodSetterSetIfNull");
  }

  @override
  ir.Throw visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      _) {
    return buildUnsupported(node, "SuperNotEquals");
  }

  @override
  ir.Throw visitSuperSetterGet(Send node, FunctionElement setter, _) {
    return buildUnsupported(node, "SuperSetterGet");
  }

  @override
  ir.Throw visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "SuperSetterInvoke");
  }

  @override
  ir.Throw visitSuperSetterSet(
      SendSet node, FunctionElement setter, Node rhs, _) {
    return buildUnsupported(node, "SuperSetterSet");
  }

  @override
  ir.Throw visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      _) {
    return buildUnsupported(node, "SuperUnary");
  }

  @override
  ir.RedirectingInitializer visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return new ir.RedirectingInitializer(
        kernel.functionToIr(thisConstructor), buildArguments(arguments));
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
    return buildUnsupported(node, "ThisInvoke");
  }

  Accessor buildThisPropertyAccessor(Name name) {
    return new ThisPropertyAccessor(kernel.nameToIrName(name));
  }

  @override
  ir.Expression visitThisPropertyGet(Send node, Name name, _) {
    return buildThisPropertyAccessor(name).buildSimpleRead();
  }

  @override
  ir.MethodInvocation visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      _) {
    return buildInvokeSelector(
        new ir.ThisExpression(), selector, buildArguments(arguments));
  }

  @override
  ir.Expression visitThisPropertySet(SendSet node, Name name, Node rhs, _) {
    return buildThisPropertyAccessor(name).buildAssignment(rhs.accept(this));
  }

  @override
  ir.Expression visitThisPropertySetIfNull(Send node, Name name, Node rhs, _) {
    return buildThisPropertyAccessor(name)
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  ir.Throw visitTopLevelConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      _) {
    return buildUnsupported(node, "TopLevelConstantDeclaration");
  }

  @override
  ir.Throw visitTopLevelFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      _) {
    return buildUnsupported(node, "TopLevelFieldDeclaration");
  }

  @override
  ir.Throw visitTopLevelFieldSetIfNull(
      Send node, FieldElement field, Node rhs, _) {
    return buildUnsupported(node, "TopLevelFieldSetIfNull");
  }

  @override
  IrFunction visitTopLevelFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Method, function, body);
  }

  ir.Arguments buildArguments(NodeList arguments) {
    List<ir.Expression> positional = <ir.Expression>[];
    List<ir.NamedExpression> named = <ir.NamedExpression>[];
    for (Expression expression in arguments.nodes) {
      ir.TreeNode argument = expression.accept(this);
      if (argument is ir.NamedExpression) {
        named.add(argument);
      } else {
        positional.add(argument);
      }
    }
    return new ir.Arguments(
        positional, named: named, types: kernel.typeArgumentsNotImplemented());
  }

  @override
  IrFunction visitTopLevelGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Getter, getter, body);
  }

  @override
  ir.Throw visitTopLevelGetterSetterSetIfNull(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "TopLevelGetterSetterSetIfNull");
  }

  @override
  ir.Throw visitTopLevelMethodSetIfNull(
      Send node,
      FunctionElement method,
      Node rhs,
      _) {
    return buildUnsupported(node, "TopLevelMethodSetIfNull");
  }

  @override
  ir.Throw visitTopLevelMethodSetterSetIfNull(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      Node rhs,
      _) {
    return buildUnsupported(node, "TopLevelMethodSetterSetIfNull");
  }

  @override
  IrFunction visitTopLevelSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      _) {
    return buildIrFunction(ir.ProcedureKind.Setter, setter, body);
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      _) {
    return buildUnsupported(node, "TypeVariableTypeLiteralGet");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "TypeVariableTypeLiteralInvoke");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return buildUnsupported(node, "TypeVariableTypeLiteralSet");
  }

  @override
  ir.Throw visitTypeVariableTypeLiteralSetIfNull(
      Send node,
      TypeVariableElement element,
      Node rhs,
      _) {
    return buildUnsupported(node, "TypeVariableTypeLiteralSetIfNull");
  }

  @override
  ir.Throw visitTypedefTypeLiteralGet(
      Send node, ConstantExpression constant, _) {
    return buildUnsupported(node, "TypedefTypeLiteralGet");
  }

  @override
  ir.Throw visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      CallStructure callStructure,
      _) {
    return buildUnsupported(node, "TypedefTypeLiteralInvoke");
  }

  @override
  ir.Throw visitTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "TypedefTypeLiteralSet");
  }

  @override
  ir.Throw visitTypedefTypeLiteralSetIfNull(
      Send node,
      ConstantExpression constant,
      Node rhs,
      _) {
    return buildUnsupported(node, "TypedefTypeLiteralSetIfNull");
  }

  @override
  ir.MethodInvocation visitUnary(
      Send node, UnaryOperator operator, Node expression, _) {
    return new ir.MethodInvocation(
        expression.accept(this), kernel.irName(operator.name, currentElement),
        new ir.Arguments.empty());
  }

  @override
  ir.Throw visitConditionalUri(ConditionalUri node) {
    return buildUnsupported(node, "ConditionalUri");
  }

  @override
  ir.Throw visitDottedName(DottedName node) {
    return buildUnsupported(node, "DottedName");
  }

  @override
  ir.Throw visitForIn(ForIn node) {
    return internalError(
        node, "Should have been caught by visitAsyncForIn or visitSyncForIn");
  }

  @override
  ir.Expression visitIndexSetIfNull(
      SendSet node, Node receiver, Node index, Node rhs, _) {
    return buildIndexAccessor(receiver, index)
        .buildNullAwareAssignment(rhs.accept(this));
  }

  @override
  ir.Throw visitSuperIndexSetIfNull(
      SendSet node, MethodElement getter, MethodElement setter, Node index,
      Node rhs, _) {
    return buildUnsupported(node, "SuperIndexSetIfNull");
  }

  @override
  ir.Node visitVariableDefinitions(VariableDefinitions definitions) {
    // TODO(ahe): This method is copied from [SemanticDeclarationResolvedMixin]
    // and modified. Perhaps we can find a way to avoid code duplication.
    List<ir.VariableDeclaration> variables = <ir.VariableDeclaration>[];
    computeVariableStructures(definitions,
        (Node node, VariableStructure structure) {
      if (structure == null) {
        return internalError(node, 'No structure for $node');
      } else {
        ir.VariableDeclaration variable =
            structure.dispatch(declVisitor, node, null);
        variables.add(variable);
        return variable;
      }
    });
    if (variables.length == 1) return variables.single;
    return new VariableDeclarations(variables);
  }

  ir.Throw buildUnsupported(Node node, String name) {
    // TODO(ahe): Do this:
    // throw new Unsupported("Kernel IR not yet implemented for '$name'.");
    if (const bool.fromEnvironment("verbose")) {
      print("Kernel IR not yet implemented for '$name'.");
    }
    return new ir.Throw(
        new ir.StringLiteral("Kernel IR not yet implemented for '$name'."));
  }

  ir.ExpressionStatement buildUnsupportedStatement(Node node, String name) {
    return new ir.ExpressionStatement(buildUnsupported(node, name));
  }

  IrFunction buildFunction() {
    return kernel.compiler.reporter.withCurrentElement(currentElement, () {
      if (currentElement.isMalformed) {
        ir.FunctionNode functionNode = buildFunctionNode(currentElement, null);
        functionNode.body = new ir.InvalidStatement()..parent = functionNode;
        return new IrFunction.procedure(ir.ProcedureKind.Method, functionNode);
      } else if (currentElement.isSynthesized) {
        if (currentElement.isGenerativeConstructor) {
          return buildGenerativeConstructor(currentElement, null);
        } else {
          return internalError(currentElement, "Unhandled synthetic function.");
        }
      } else {
        return currentElement.node.accept(this);
      }
    });
  }

  ir.Expression buildInitializer() {
    return kernel.compiler.reporter.withCurrentElement(currentElement, () {
      FieldElement field = currentElement;
      return field.initializer.accept(this);
    });
  }
}

class VariableDeclarations implements ir.Node {
  final List<ir.VariableDeclaration> variables;

  VariableDeclarations(this.variables);

  accept(ir.Visitor v) => throw "unsupported";

  visitChildren(ir.Visitor v) => throw "unsupported";

  String toString() => "VariableDeclarations($variables)";
}

class IrFunction implements ir.Node {
  final ir.ProcedureKind kind;
  final bool isConstructor;
  final ir.FunctionNode node;
  final List<ir.Initializer> initializers;

  IrFunction(this.kind, this.isConstructor, this.node, this.initializers);

  IrFunction.procedure(ir.ProcedureKind kind, ir.FunctionNode node)
      : this(kind, false, node, null);

  IrFunction.constructor(
            ir.FunctionNode node,
      List<ir.Initializer> initializers)
      : this(null, true, node, initializers);

  accept(ir.Visitor v) => throw "unsupported";

  visitChildren(ir.Visitor v) => throw "unsupported";

  String toString() {
    return "IrFunction($kind, $isConstructor, $node, $initializers)";
  }
}

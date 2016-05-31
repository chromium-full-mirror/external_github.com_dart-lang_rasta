// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.bench;

import 'package:compiler/src/tokens/token.dart' show
    BadInputToken,
    BeginGroupToken,
    ErrorToken,
    StringToken,
    Token,
    UnmatchedToken,
    UnterminatedToken;

import 'package:compiler/src/tokens/precedence_constants.dart' as Precedence;

import 'package:compiler/src/parser/listener.dart' show
    Listener,
    ParserError,
    closeBraceFor;

import 'package:compiler/src/tree/tree.dart' show
    Node;

import 'package:compiler/src/util/util.dart' show
    Link;

import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind,
    MessageTemplate;

import 'package:compiler/src/diagnostics/spannable.dart' show
    Spannable,
    SpannableAssertionFailure;

// This class is a copy of [Listener] extended with [logEvent].
class BenchListener implements Listener {
  final List<String> messagesList = <String>[];
  Link<String> messagesLink = const Link<String>();

  set suppressParseErrors(bool value) {}

  void logEvent(String message) {
    // messagesList.add(message);
    messagesLink = messagesLink.prepend(message);
  }

  void beginArguments(Token token) {
    logEvent("beginArguments");
  }

  void endArguments(int count, Token beginToken, Token endToken) {
    logEvent("endArguments");
  }

  void handleAsyncModifier(Token asyncToken, Token startToken) {
    logEvent("handleAsyncModifier");
  }

  void beginAwaitExpression(Token token) {
    logEvent("beginAwaitExpression");
  }

  void endAwaitExpression(Token beginToken, Token endToken) {
    logEvent("endAwaitExpression");
  }

  void beginBlock(Token token) {
    logEvent("beginBlock");
  }

  void endBlock(int count, Token beginToken, Token endToken) {
    logEvent("endBlock");
  }

  void beginCascade(Token token) {
    logEvent("beginCascade");
  }

  void endCascade() {
    logEvent("endCascade");
  }

  void beginClassBody(Token token) {
    logEvent("beginClassBody");
  }

  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    logEvent("endClassBody");
  }

  void beginClassDeclaration(Token token) {
    logEvent("beginClassDeclaration");
  }

  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    logEvent("endClassDeclaration");
  }

  void beginCombinators(Token token) {
    logEvent("beginCombinators");
  }

  void endCombinators(int count) {
    logEvent("endCombinators");
  }

  void beginCompilationUnit(Token token) {
    logEvent("beginCompilationUnit");
  }

  void endCompilationUnit(int count, Token token) {
    logEvent("endCompilationUnit");
  }

  void beginConstructorReference(Token start) {
    logEvent("beginConstructorReference");
  }

  void endConstructorReference(
      Token start,
      Token periodBeforeName,
      Token endToken) {
    logEvent("endConstructorReference");
  }

  void beginDoWhileStatement(Token token) {
    logEvent("beginDoWhileStatement");
  }

  void endDoWhileStatement(
      Token doKeyword,
      Token whileKeyword,
      Token endToken) {
    logEvent("endDoWhileStatement");
  }

  void beginEnum(Token enumKeyword) {
    logEvent("beginEnum");
  }

  void endEnum(Token enumKeyword, Token endBrace, int count) {
    logEvent("endEnum");
  }

  void beginExport(Token token) {
    logEvent("beginExport");
  }

  void endExport(Token exportKeyword, Token semicolon) {
    logEvent("endExport");
  }

  void beginExpressionStatement(Token token) {
    logEvent("beginExpressionStatement");
  }

  void endExpressionStatement(Token token) {
    logEvent("endExpressionStatement");
  }

  void beginFactoryMethod(Token token) {
    logEvent("beginFactoryMethod");
  }

  void endFactoryMethod(Token beginToken, Token endToken) {
    logEvent("endFactoryMethod");
  }

  void beginFormalParameter(Token token) {
    logEvent("beginFormalParameter");
  }

  void endFormalParameter(Token thisKeyword) {
    logEvent("endFormalParameter");
  }

  void handleNoFormalParameters(Token token) {
    logEvent("handleNoFormalParameters");
  }

  void beginFormalParameters(Token token) {
    logEvent("beginFormalParameters");
  }

  void endFormalParameters(int count, Token beginToken, Token endToken) {
    logEvent("endFormalParameters");
  }

  void endFields(int count, Token beginToken, Token endToken) {
    logEvent("endFields");
  }

  void beginForStatement(Token token) {
    logEvent("beginForStatement");
  }

  void endForStatement(
      int updateExpressionCount,
      Token beginToken,
      Token endToken) {
    logEvent("endForStatement");
  }

  void endForIn(
      Token awaitToken,
      Token forToken,
      Token inKeyword,
      Token endToken) {
    logEvent("endForIn");
  }

  void beginFunction(Token token) {
    logEvent("beginFunction");
  }

  void endFunction(Token getOrSet, Token endToken) {
    logEvent("endFunction");
  }

  void beginFunctionDeclaration(Token token) {
    logEvent("beginFunctionDeclaration");
  }

  void endFunctionDeclaration(Token token) {
    logEvent("endFunctionDeclaration");
  }

  void beginFunctionBody(Token token) {
    logEvent("beginFunctionBody");
  }

  void endFunctionBody(int count, Token beginToken, Token endToken) {
    logEvent("endFunctionBody");
  }

  void handleNoFunctionBody(Token token) {
    logEvent("handleNoFunctionBody");
  }

  void skippedFunctionBody(Token token) {
    logEvent("skippedFunctionBody");
  }

  void beginFunctionName(Token token) {
    logEvent("beginFunctionName");
  }

  void endFunctionName(Token token) {
    logEvent("endFunctionName");
  }

  void beginFunctionTypeAlias(Token token) {
    logEvent("beginFunctionTypeAlias");
  }

  void endFunctionTypeAlias(Token typedefKeyword, Token endToken) {
    logEvent("endFunctionTypeAlias");
  }

  void beginMixinApplication(Token token) {
    logEvent("beginMixinApplication");
  }

  void endMixinApplication() {
    logEvent("endMixinApplication");
  }

  void beginNamedMixinApplication(Token token) {
    logEvent("beginNamedMixinApplication");
  }

  void endNamedMixinApplication(
      Token classKeyword,
      Token implementsKeyword,
      Token endToken) {
    logEvent("endNamedMixinApplication");
  }

  void beginHide(Token hideKeyword) {
    logEvent("beginHide");
  }

  void endHide(Token hideKeyword) {
    logEvent("endHide");
  }

  void beginIdentifierList(Token token) {
    logEvent("beginIdentifierList");
  }

  void endIdentifierList(int count) {
    logEvent("endIdentifierList");
  }

  void beginTypeList(Token token) {
    logEvent("beginTypeList");
  }

  void endTypeList(int count) {
    logEvent("endTypeList");
  }

  void beginIfStatement(Token token) {
    logEvent("beginIfStatement");
  }

  void endIfStatement(Token ifToken, Token elseToken) {
    logEvent("endIfStatement");
  }

  void beginImport(Token importKeyword) {
    logEvent("beginImport");
  }

  void endImport(
      Token importKeyword,
      Token DeferredKeyword,
      Token asKeyword,
      Token semicolon) {
    logEvent("endImport");
  }

  void beginConditionalUris(Token token) {
    logEvent("beginConditionalUris");
  }

  void endConditionalUris(int count) {
    logEvent("endConditionalUris");
  }

  void beginConditionalUri(Token ifKeyword) {
    logEvent("beginConditionalUri");
  }

  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    logEvent("endConditionalUri");
  }

  void beginDottedName(Token token) {
    logEvent("beginDottedName");
  }

  void endDottedName(int count, Token firstIdentifier) {
    logEvent("endDottedName");
  }

  void beginInitializedIdentifier(Token token) {
    logEvent("beginInitializedIdentifier");
  }

  void endInitializedIdentifier() {
    logEvent("endInitializedIdentifier");
  }

  void beginInitializer(Token token) {
    logEvent("beginInitializer");
  }

  void endInitializer(Token assignmentOperator) {
    logEvent("endInitializer");
  }

  void beginInitializers(Token token) {
    logEvent("beginInitializers");
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    logEvent("endInitializers");
  }

  void handleNoInitializers() {
    logEvent("handleNoInitializers");
  }

  void handleLabel(Token token) {
    logEvent("handleLabel");
  }

  void beginLabeledStatement(Token token, int labelCount) {
    logEvent("beginLabeledStatement");
  }

  void endLabeledStatement(int labelCount) {
    logEvent("endLabeledStatement");
  }

  void beginLibraryName(Token token) {
    logEvent("beginLibraryName");
  }

  void endLibraryName(Token libraryKeyword, Token semicolon) {
    logEvent("endLibraryName");
  }

  void beginLiteralMapEntry(Token token) {
    logEvent("beginLiteralMapEntry");
  }

  void endLiteralMapEntry(Token colon, Token endToken) {
    logEvent("endLiteralMapEntry");
  }

  void beginLiteralString(Token token) {
    logEvent("beginLiteralString");
  }

  void endLiteralString(int interpolationCount) {
    logEvent("endLiteralString");
  }

  void handleStringJuxtaposition(int literalCount) {
    logEvent("handleStringJuxtaposition");
  }

  void beginMember(Token token) {
    logEvent("beginMember");
  }

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    logEvent("endMethod");
  }

  void beginMetadataStar(Token token) {
    logEvent("beginMetadataStar");
  }

  void endMetadataStar(int count, bool forParameter) {
    logEvent("endMetadataStar");
  }

  void beginMetadata(Token token) {
    logEvent("beginMetadata");
  }

  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    logEvent("endMetadata");
  }

  void beginOptionalFormalParameters(Token token) {
    logEvent("beginOptionalFormalParameters");
  }

  void endOptionalFormalParameters(
      int count,
      Token beginToken,
      Token endToken) {
    logEvent("endOptionalFormalParameters");
  }

  void beginPart(Token token) {
    logEvent("beginPart");
  }

  void endPart(Token partKeyword, Token semicolon) {
    logEvent("endPart");
  }

  void beginPartOf(Token token) {
    logEvent("beginPartOf");
  }

  void endPartOf(Token partKeyword, Token semicolon) {
    logEvent("endPartOf");
  }

  void beginRedirectingFactoryBody(Token token) {
    logEvent("beginRedirectingFactoryBody");
  }

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    logEvent("endRedirectingFactoryBody");
  }

  void beginReturnStatement(Token token) {
    logEvent("beginReturnStatement");
  }

  void endReturnStatement(
      bool hasExpression,
      Token beginToken,
      Token endToken) {
    logEvent("endReturnStatement");
  }

  void beginSend(Token token) {
    logEvent("beginSend");
  }

  void endSend(Token token) {
    logEvent("endSend");
  }

  void beginShow(Token showKeyword) {
    logEvent("beginShow");
  }

  void endShow(Token showKeyword) {
    logEvent("endShow");
  }

  void beginSwitchStatement(Token token) {
    logEvent("beginSwitchStatement");
  }

  void endSwitchStatement(Token switchKeyword, Token endToken) {
    logEvent("endSwitchStatement");
  }

  void beginSwitchBlock(Token token) {
    logEvent("beginSwitchBlock");
  }

  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    logEvent("endSwitchBlock");
  }

  void beginLiteralSymbol(Token token) {
    logEvent("beginLiteralSymbol");
  }

  void endLiteralSymbol(Token hashToken, int identifierCount) {
    logEvent("endLiteralSymbol");
  }

  void beginThrowExpression(Token token) {
    logEvent("beginThrowExpression");
  }

  void endThrowExpression(Token throwToken, Token endToken) {
    logEvent("endThrowExpression");
  }

  void beginRethrowStatement(Token token) {
    logEvent("beginRethrowStatement");
  }

  void endRethrowStatement(Token throwToken, Token endToken) {
    logEvent("endRethrowStatement");
  }

  void endTopLevelDeclaration(Token token) {
    logEvent("endTopLevelDeclaration");
  }

  void beginTopLevelMember(Token token) {
    logEvent("beginTopLevelMember");
  }

  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    logEvent("endTopLevelFields");
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    logEvent("endTopLevelMethod");
  }

  void beginTryStatement(Token token) {
    logEvent("beginTryStatement");
  }

  void handleCaseMatch(Token caseKeyword, Token colon) {
    logEvent("handleCaseMatch");
  }

  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    logEvent("handleCatchBlock");
  }

  void handleFinallyBlock(Token finallyKeyword) {
    logEvent("handleFinallyBlock");
  }

  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    logEvent("endTryStatement");
  }

  void endType(Token beginToken, Token endToken) {
    logEvent("endType");
  }

  void beginTypeArguments(Token token) {
    logEvent("beginTypeArguments");
  }

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    logEvent("endTypeArguments");
  }

  void handleNoTypeArguments(Token token) {
    logEvent("handleNoTypeArguments");
  }

  void beginTypeVariable(Token token) {
    logEvent("beginTypeVariable");
  }

  void endTypeVariable(Token token) {
    logEvent("endTypeVariable");
  }

  void beginTypeVariables(Token token) {
    logEvent("beginTypeVariables");
  }

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    logEvent("endTypeVariables");
  }

  void beginUnnamedFunction(Token token) {
    logEvent("beginUnnamedFunction");
  }

  void endUnnamedFunction(Token token) {
    logEvent("endUnnamedFunction");
  }

  void beginVariablesDeclaration(Token token) {
    logEvent("beginVariablesDeclaration");
  }

  void endVariablesDeclaration(int count, Token endToken) {
    logEvent("endVariablesDeclaration");
  }

  void beginWhileStatement(Token token) {
    logEvent("beginWhileStatement");
  }

  void endWhileStatement(Token whileKeyword, Token endToken) {
    logEvent("endWhileStatement");
  }

  void handleAsOperator(Token operathor, Token endToken) {
    logEvent("handleAsOperator");
  }

  void handleAssignmentExpression(Token token) {
    logEvent("handleAssignmentExpression");
  }

  void handleBinaryExpression(Token token) {
    logEvent("handleBinaryExpression");
  }

  void handleConditionalExpression(Token question, Token colon) {
    logEvent("handleConditionalExpression");
  }

  void handleConstExpression(Token token) {
    logEvent("handleConstExpression");
  }

  void handleFunctionTypedFormalParameter(Token token) {
    logEvent("handleFunctionTypedFormalParameter");
  }

  void handleIdentifier(Token token) {
    logEvent("handleIdentifier");
  }

  void handleIndexedExpression(
      Token openCurlyBracket,
      Token closeCurlyBracket) {
    logEvent("handleIndexedExpression");
  }

  void handleIsOperator(Token operathor, Token not, Token endToken) {
    logEvent("handleIsOperator");
  }

  void handleLiteralBool(Token token) {
    logEvent("handleLiteralBool");
  }

  void handleBreakStatement(
      bool hasTarget,
      Token breakKeyword,
      Token endToken) {
    logEvent("handleBreakStatement");
  }

  void handleContinueStatement(
      bool hasTarget,
      Token continueKeyword,
      Token endToken) {
    logEvent("handleContinueStatement");
  }

  void handleEmptyStatement(Token token) {
    logEvent("handleEmptyStatement");
  }

  void handleAssertStatement(
      Token assertKeyword,
      Token commaToken,
      Token semicolonToken) {
    logEvent("handleAssertStatement");
  }

  void handleLiteralDouble(Token token) {
    logEvent("handleLiteralDouble");
  }

  void handleLiteralInt(Token token) {
    logEvent("handleLiteralInt");
  }

  void handleLiteralList(
      int count,
      Token beginToken,
      Token constKeyword,
      Token endToken) {
    logEvent("handleLiteralList");
  }

  void handleLiteralMap(
      int count,
      Token beginToken,
      Token constKeyword,
      Token endToken) {
    logEvent("handleLiteralMap");
  }

  void handleLiteralNull(Token token) {
    logEvent("handleLiteralNull");
  }

  void handleModifier(Token token) {
    logEvent("handleModifier");
  }

  void handleModifiers(int count) {
    logEvent("handleModifiers");
  }

  void handleNamedArgument(Token colon) {
    logEvent("handleNamedArgument");
  }

  void handleNewExpression(Token token) {
    logEvent("handleNewExpression");
  }

  void handleNoArguments(Token token) {
    logEvent("handleNoArguments");
  }

  void handleNoExpression(Token token) {
    logEvent("handleNoExpression");
  }

  void handleNoType(Token token) {
    logEvent("handleNoType");
  }

  void handleNoTypeVariables(Token token) {
    logEvent("handleNoTypeVariables");
  }

  void handleOperator(Token token) {
    logEvent("handleOperator");
  }

  void handleOperatorName(Token operatorKeyword, Token token) {
    logEvent("handleOperatorName");
  }

  void handleParenthesizedExpression(BeginGroupToken token) {
    logEvent("handleParenthesizedExpression");
  }

  void handleQualified(Token period) {
    logEvent("handleQualified");
  }

  void handleStringPart(Token token) {
    logEvent("handleStringPart");
  }

  void handleSuperExpression(Token token) {
    logEvent("handleSuperExpression");
  }

  void handleSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      int statementCount,
      Token firstToken,
      Token endToken) {
    logEvent("handleSwitchCase");
  }

  void handleThisExpression(Token token) {
    logEvent("handleThisExpression");
  }

  void handleUnaryPostfixAssignmentExpression(Token token) {
    logEvent("handleUnaryPostfixAssignmentExpression");
  }

  void handleUnaryPrefixExpression(Token token) {
    logEvent("handleUnaryPrefixExpression");
  }

  void handleUnaryPrefixAssignmentExpression(Token token) {
    logEvent("handleUnaryPrefixAssignmentExpression");
  }

  void handleValuedFormalParameter(Token equals, Token token) {
    logEvent("handleValuedFormalParameter");
  }

  void handleVoidKeyword(Token token) {
    logEvent("handleVoidKeyword");
  }

  void beginYieldStatement(Token token) {
    logEvent("beginYieldStatement");
  }

  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    logEvent("endYieldStatement");
  }

  Token expected(String string, Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected '$string', but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token synthesizeIdentifier(Token token) {
    Token synthesizedToken = new StringToken.fromString(
        Precedence.IDENTIFIER_INFO, '?', token.charOffset);
    synthesizedToken.next = token.next;
    return synthesizedToken;
  }

  Token expectedIdentifier(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected identifier, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedType(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a type, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedExpression(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected an expression, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token unexpected(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("unexpected token '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedBlockToSkip(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a block, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedFunctionBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a function body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedClassBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a class body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedClassBodyToSkip(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a class body, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token expectedDeclaration(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("expected a declaration, but got '${token.value}'", token);
    }
    return skipToEof(token);
  }

  Token unmatched(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      error("unmatched '${token.value}'", token);
    }
    return skipToEof(token);
  }

  skipToEof(Token token) {
    while (!identical(token.info, Precedence.EOF_INFO)) {
      token = token.next;
    }
    return token;
  }

  void recoverableError(Token token, String message) {
    error(message, token);
  }

  void error(String message, Token token) {
    throw new ParserError("$message @ ${token.charOffset}");
  }

  void reportError(Spannable spannable, MessageKind messageKind,
      [Map arguments = const {}]) {
    MessageTemplate template = MessageTemplate.TEMPLATES[messageKind];
    String message = template.message(arguments, true).toString();
    Token token;
    if (spannable is Token) {
      token = spannable;
    } else if (spannable is Node) {
      token = spannable.getBeginToken();
    } else {
      throw new ParserError(message);
    }
    recoverableError(token, message);
  }

  void reportErrorToken(ErrorToken token) {
    if (token is BadInputToken) {
      String hex = token.character.toRadixString(16);
      if (hex.length < 4) {
        String padding = "0000".substring(hex.length);
        hex = "$padding$hex";
      }
      reportError(
          token, MessageKind.BAD_INPUT_CHARACTER, {'characterHex': hex});
    } else if (token is UnterminatedToken) {
      MessageKind kind;
      var arguments = const {};
      switch (token.start) {
        case '1e':
          kind = MessageKind.EXPONENT_MISSING;
          break;
        case '"':
        case "'":
        case '"""':
        case "'''":
        case 'r"':
        case "r'":
        case 'r"""':
        case "r'''":
          kind = MessageKind.UNTERMINATED_STRING;
          arguments = {'quote': token.start};
          break;
        case '0x':
          kind = MessageKind.HEX_DIGIT_EXPECTED;
          break;
        case r'$':
          kind = MessageKind.MALFORMED_STRING_LITERAL;
          break;
        case '/*':
          kind = MessageKind.UNTERMINATED_COMMENT;
          break;
        default:
          kind = MessageKind.UNTERMINATED_TOKEN;
          break;
      }
      reportError(token, kind, arguments);
    } else if (token is UnmatchedToken) {
      String begin = token.begin.value;
      String end = closeBraceFor(begin);
      reportError(
          token, MessageKind.UNMATCHED_TOKEN, {'begin': begin, 'end': end});
    } else {
      throw new SpannableAssertionFailure(token, token.assertionMessage);
    }
  }
}

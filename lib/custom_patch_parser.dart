// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_patch_parser;

import 'dart:async' show
    Future;

import 'package:compiler/src/patch_parser.dart' show
    PatchParserTask;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:compiler/src/library_loader.dart' show
    LibraryLoader;

import 'package:compiler/src/elements/elements.dart' show
    CompilationUnitElement,
    Element,
    LibraryElement;

import 'package:compiler/src/parser/partial_elements.dart' show
    PartialClassElement;

import 'package:compiler/src/elements/modelx.dart' show
    LibraryElementX;

import 'package:compiler/src/script.dart' show
    Script;

import 'package:compiler/src/tokens/token.dart' show
    Token;

import 'package:compiler/src/scanner/scanner.dart' show
    Scanner;

import 'package:compiler/src/parser/listener.dart' show
    Listener,
    ParserError;

import 'package:compiler/src/patch_parser.dart' show
    PartialPatchParser,
    PatchClassElementParser,
    PatchElementListener,
    PatchMemberListener;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'package:compiler/src/options.dart' show
    ParserOptions;

class CustomPatchParserTask extends CompilerTask implements PatchParserTask {

  CustomPatchParserTask(CustomCompiler compiler)
      : super(compiler);

  @override ParserOptions get parserOptions => compiler.parsing.parserOptions;

  @override Future patchLibrary(
      LibraryLoader loader, Uri patchUri, LibraryElement originLibrary) {
    throw "unsupported";
  }

  @override void scanLibraryElements(CompilationUnitElement compilationUnit) {
    throw "unsupported";
  }

  @override void parsePatchClassNode(PartialClassElement cls) {

    // Parse [PartialClassElement] using a "patch"-aware parser instead
    // of calling its [parseNode] method.
    if (cls.cachedNode != null) return;

    measure(() => reporter.withCurrentElement(cls, () {
      PatchMemberListener listener = new PatchMemberListener(compiler, cls);
      PatchClassElementParser parser =
      new PatchClassElementParser(listener, parserOptions);
      try {
        Token token = parser.parseTopLevelDeclaration(cls.beginToken);
        assert(identical(token, cls.endToken.next));
      } on ParserError catch (e) {
        // No need to recover from a parser error in platform libraries, user
        // will never see this if the libraries are tested correctly.
        reporter.internalError(cls, "Parser error in patch file: $e");
      }
      cls.cachedNode = listener.popNode();
      assert(listener.nodes.isEmpty);
    }));
  }

  Future<Null> onLibraryScanned(LibraryElement library,
      LibraryLoader loader) async {
    Uri uri = library.canonicalUri;
    CustomCompiler compiler = this.compiler;
    List<Uri> patches = compiler.target.patches[uri];
    return patches == null ? null : patchLibraryMulti(loader, patches, library);
  }

  Future<Null> patchLibraryMulti(LibraryLoader loader, List<Uri> patches,
      LibraryElement originLibrary) async {
    for (Uri patchUri in patches) {
      await loadPatchLibrary(patchUri, originLibrary, loader);
    }
  }

  Future<LibraryElementX> loadPatchLibrary(
      Uri patchUri, LibraryElement originLibrary, LibraryLoader loader) async {
    Script script = await compiler.readScript(patchUri, originLibrary);
    LibraryElementX patchLibrary = new LibraryElementX(script, null);
    {
      // TODO(ahe): This circumvents an invariant in PatchMixin.applyPatch. How
      // to correctly do this?
      originLibrary.patch = patchLibrary;
      patchLibrary.origin = originLibrary;
    }
    loader.registerNewLibrary(patchLibrary);
    Token tokens = compiler.scanner.measureElement(patchLibrary.compilationUnit,
        () => new Scanner(script.file).tokenize());
    Listener patchListener = new PatchElementListener(
        compiler, patchLibrary.compilationUnit, compiler);
    try {
      new PartialPatchParser(patchListener, compiler.options).parseUnit(tokens);
    } on ParserError catch (e) {
      // No need to recover from a parser error in platform libraries, user
      // will never see this if the libraries are tested correctly.
      compiler.reporter.internalError(
          originLibrary.compilationUnit, "Parser error in patch file: $e");
    }

    await loader.processLibraryTags(patchLibrary);

    patchLibrary.compilationUnit.forEachLocalMember((Element e) {
      // TODO(ahe): Inject or patch [e] into [originLibrary].
    });
  }
}

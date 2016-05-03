// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_backend;

import 'dart:async' show
    Future;

import 'package:compiler/src/common/backend_api.dart' show
    Backend,
    ImpactTransformer;

import 'package:compiler/src/compile_time_constants.dart' show
    BackendConstantEnvironment,
    ConstantCompilerTask;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    FunctionElement,
    LibraryElement;

import 'package:compiler/src/common/codegen.dart' show
    CodegenWorkItem;

import 'package:compiler/src/common/tasks.dart' show
    CompilerTask;

import 'package:compiler/src/constants/constant_system.dart' show
    ConstantSystem;

import 'package:compiler/src/common/registry.dart' show
    Registry;

import 'package:compiler/src/enqueue.dart' show
    ResolutionEnqueuer;

import 'package:compiler/src/diagnostics/spannable.dart' show
    Spannable;

import 'package:compiler/src/universe/world_impact.dart' show
    WorldImpact;

import 'package:compiler/src/dart_backend/dart_backend.dart' show
    DartConstantTask;

import 'package:compiler/src/library_loader.dart' show
    LibraryLoader;

import 'target_specification.dart' show
    TargetSpecification;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'custom_patch_parser.dart' show
    CustomPatchParserTask;

import 'custom_impact_transformer.dart' show
    CustomImpactTransformer;

import 'src/unimplemented.dart' show
    unimplemented;

class CustomBackend extends Backend {
  final TargetSpecification target;

  @override final ConstantCompilerTask constantCompilerTask;

  @override final List<CompilerTask> tasks = <CompilerTask>[];

  @override final ImpactTransformer impactTransformer =
      new CustomImpactTransformer();

  CustomBackend(CustomCompiler compiler, this.target)
      : constantCompilerTask = new DartConstantTask(compiler),
        super(compiler);

  @override Future onLibraryScanned(
      LibraryElement library, LibraryLoader loader) async {
    await super.onLibraryScanned(library, loader);
    CustomPatchParserTask custom = compiler.patchParser;
    return custom.onLibraryScanned(library, loader);
  }

  @override void enqueueHelpers(ResolutionEnqueuer world, Registry registry) {
    unimplemented;
  }

  @override bool enableCodegenWithErrorsIfSupported(Spannable node) {
    return unimplemented;
  }

  @override int assembleProgram() => unimplemented;

  @override WorldImpact codegen(CodegenWorkItem work) => unimplemented;

  @override bool get supportsReflection => unimplemented;

  @override bool get supportsAsyncAwait => true;

  @override ConstantSystem get constantSystem => unimplemented;

  @override BackendConstantEnvironment get constants => unimplemented;

  @override bool classNeedsRti(ClassElement cls) => unimplemented;

  @override bool methodNeedsRti(FunctionElement function) => unimplemented;

  @override bool enableDeferredLoadingIfSupported(
      Spannable node, Registry registry) => unimplemented;

  @override Uri resolvePatchUri(String libraryName, Uri plaformConfigUri) {
    return unimplemented;
  }
}

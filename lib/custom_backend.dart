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
    LibraryElement,
    MethodElement;

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

import 'package:compiler/src/js_backend/patch_resolver.dart' show
    PatchResolverTask;

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

  PatchResolverTask patchResolver;

  CustomBackend(CustomCompiler compiler, this.target)
      : constantCompilerTask = new DartConstantTask(compiler),
        super(compiler) {
    patchResolver = new PatchResolverTask(compiler);
    tasks.add(patchResolver);
  }

  @override Future onLibraryScanned(
      LibraryElement library, LibraryLoader loader) {
    // TODO(ahe): We may want to call super to enable @native and JS-interop.
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

  @override bool get supportsReflection => false;

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

  @override MethodElement resolveExternalFunction(MethodElement element) {
    return patchResolver.resolveExternalFunction(element);
  }

  @override bool canLibraryUseNative(LibraryElement library) {
    return library.isPlatformLibrary || isNativeTest(library);
  }

  /// Returns true if [library] is a test of native keyword.
  bool isNativeTest(LibraryElement library) {
    Uri uri = library.canonicalUri;
    return uri.scheme == "file" &&
        uri.path.contains("/test/kernel/regression/native/");
  }
}

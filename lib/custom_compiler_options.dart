// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_compiler_options;

import 'package:compiler/src/options.dart' show
    CompilerOptions;

import 'package:compiler/compiler.dart' show
    PackagesDiscoveryProvider;

import 'target_specification.dart' show
    TargetSpecification;

const String _UNDETERMINED_BUILD_ID = "build number could not be determined";

class CustomCompilerOptions implements CompilerOptions {
  @override final Uri libraryRoot;

  @override final Uri packageConfig;

  @override final Map<String, dynamic> environment;

  @override final bool analyzeAll;

  @override final bool analyzeMain;

  @override final bool analyzeOnly;

  @override final bool analyzeSignaturesOnly;

  @override final String buildId;

  @override final bool preserveUris;

  @override final bool verbose;

  @override final Uri platformConfigUri;

  final Uri base;

  CustomCompilerOptions(
      this.libraryRoot,
      this.packageConfig,
      this.environment,
      this.analyzeAll,
      this.analyzeMain,
      this.analyzeOnly,
      this.analyzeSignaturesOnly,
      this.buildId,
      this.preserveUris,
      this.verbose,
      this.platformConfigUri,
      this.base);

  @override bool get hasBuildId => buildId != _UNDETERMINED_BUILD_ID;

  @override Uri get entryPoint => _unsupported;

  @override Uri get packageRoot => null;

  @override PackagesDiscoveryProvider get packagesDiscoveryProvider => null;

  @override bool get allowMockCompilation => false;

  @override bool get allowNativeExtensions => true;

  @override Uri get deferredMapUri => null;

  @override bool get disableInlining => true;

  @override bool get disableTypeInference => true;

  @override bool get dumpInfo => false;

  @override bool get enableAssertMessage => false;

  @override bool get enableExperimentalMirrors => false;

  @override bool get enableMinification => false;

  @override bool get enableNativeLiveTypeAnalysis => false;

  @override bool get enableTypeAssertions => false;

  @override bool get enableUserAssertions => false;

  @override bool get generateCodeWithCompileTimeErrors => true;

  @override bool get generateSourceMap => false;

  @override bool get hasIncrementalSupport => true;

  @override Uri get outputUri => null;

  @override Uri get sourceMapUri => _unsupported;

  @override bool get testMode => false;

  @override bool get trustJSInteropTypeAnnotations => false;

  @override bool get trustPrimitives => false;

  @override bool get trustTypeAnnotations => false;

  @override bool get useContentSecurityPolicy => false;

  @override bool get useCpsIr => false;

  @override bool get useFrequencyNamer => false;

  @override bool get useNewSourceInfo => false;

  @override bool get useStartupEmitter => false;

  @override bool get preserveComments => false;

  @override bool get emitJavaScript => _unsupported;

  @override bool get dart2dartMultiFile => _unsupported;

  @override List<String> get strips => _unsupported;

  @override bool get enableGenericMethodSyntax => false;

  @override bool get fatalWarnings => false;

  @override bool get terseDiagnostics => false;

  @override bool get suppressWarnings => false;

  @override bool get suppressHints => false;

  @override bool get showAllPackageWarnings => true;

  @override bool get hidePackageWarnings => false;

  @override bool showPackageWarningsFor(Uri uri) => true;

  static CustomCompilerOptions copy(
      CompilerOptions options,
      {Uri libraryRoot,
       Uri packageConfig,
       Map<String, dynamic> environment,
       bool analyzeAll,
       bool analyzeMain,
       bool analyzeOnly,
       bool analyzeSignaturesOnly,
       String buildId,
       bool preserveUris,
       bool verbose,
       Uri platformConfigUri,
       Uri base}) {
    return new CustomCompilerOptions(
        libraryRoot ?? options.libraryRoot,
        packageConfig ?? options.packageConfig,
        environment ?? options.environment,
        analyzeAll ?? options.analyzeAll,
        analyzeMain ?? options.analyzeMain,
        analyzeOnly ?? options.analyzeOnly,
        analyzeSignaturesOnly ?? options.analyzeSignaturesOnly,
        buildId ?? options.buildId,
        preserveUris ?? options.preserveUris,
        verbose ?? options.verbose,
        platformConfigUri ?? options.platformConfigUri,
        base ?? Uri.base);
  }

  static CustomCompilerOptions parse(
      List<String> arguments,
      {Uri base,
       Map<String, dynamic> environment,
       TargetSpecification targetSpecification}) {
    if (arguments == null) {
      throw new ArgumentError("[arguments] is null");
    }
    if (base == null) {
      throw new ArgumentError("[base] is null");
    }
    if (environment == null) {
      throw new ArgumentError("[environment] is null");
    }
    if (targetSpecification == null) {
      throw new ArgumentError("[targetSpecification] is null");
    }

    CompilerOptions options = new CompilerOptions.parse(
        entryPoint: null,
        libraryRoot: targetSpecification.libraryRoot,
        packageRoot: null,
        packageConfig: targetSpecification.packageConfig,
        packagesDiscoveryProvider: null,
        environment: environment,
        options: arguments);

    return copy(options, base: base,
        platformConfigUri: targetSpecification.platformConfig);
  }
}

get _unsupported => throw "not supported";

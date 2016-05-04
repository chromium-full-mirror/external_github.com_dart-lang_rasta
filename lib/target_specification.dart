// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.target_specification;

import 'dart:convert' show
    JSON,
    UTF8;

import 'dart:async' show
    Future;

import 'package:compiler/compiler_new.dart' show
    CompilerInput;

class TargetSpecification {
  /// The location of the JSON file that defined this TargetSpecification.
  final Uri source;

  /// The --library-root option of dart2js.
  final Uri libraryRoot;

  /// The value of --packages option of dart2js.
  final Uri packageConfig;

  /// The location of the platform configuration.
  final Uri platformConfig;

  /// Maps each library to a list of patches.
  final Map<Uri, List<Uri>> patches;

  TargetSpecification({Uri source, Uri libraryRoot, Uri packageConfig,
      Uri platformConfig, this.patches})
      : source = nullCheck('source', source),
        libraryRoot = nullCheck('libraryRoot', libraryRoot),
        packageConfig = nullCheck('packageConfig', packageConfig),
        platformConfig = nullCheck('platformConfig', platformConfig);

  Future<Null> validate(CompilerInput inputProvider) async {
    await validateIsFile(inputProvider, packageConfig, 'packages', source);
    await validateHasFile(
        inputProvider, libraryRoot, 'library-root', source,
        'dart_shared.platform');
    await validateIsFile(inputProvider, platformConfig, 'platform', source);
  }

  String toString() {
    return "TargetSpecification(source: '$source', "
        "libraryRoot: '$libraryRoot', packageConfig: '$packageConfig')";
  }

  static TargetSpecification decode(String jsonText, Uri source) {
    Map<String, dynamic> json = JSON.decode(jsonText);
    Uri libraryRoot = decodeUri("library-root", json, source);
    Uri packageConfig = decodeUri("packages", json, source);
    Uri platformConfig = decodeUri("platform", json, source);
    Map<Uri, List<Uri>> patches = decodePatches("patches", json, source);
    return new TargetSpecification(
        source: source, libraryRoot: libraryRoot, packageConfig: packageConfig,
        platformConfig: platformConfig, patches: patches);
  }
}

Map<Uri, List<Uri>> decodePatches(
    String name, Map<String, dynamic> json, Uri base) {
  Map<String, dynamic> patches = json[name];
  if (patches == null) {
    throw new StateError("'$name' not defined in $base");
  }
  Map<Uri, List<Uri>> result = <Uri, List<Uri>>{};
  patches.forEach((String libraryName, List patchNames) {
    Uri uri = base.resolve(libraryName);
    List<Uri> uris = result[uri];
    if (uris != null) {
      throw new StateError(
          "$base: '$name' has multitple entries for '$libraryName'");
    }
    uris = new List<Uri>.from(patchNames.map(base.resolve));
    result[uri] = uris;
  });
  return result;
}

Uri decodeUri(String name, Map<String, dynamic> json, Uri base) {
  String path = json[name];
  if (path == null) {
    throw new StateError("'$name' not defined in $base");
  }
  return base.resolve(path);
}

Future<String> readStringFromUri(
    CompilerInput inputProvider,
    Uri uri) async {
  var data = await inputProvider.readFromUri(uri);
  if (data is String) return data;
  List<int> bytes = data;
  if (bytes.isNotEmpty && bytes.last == 0) {
    bytes = bytes.getRange(0, bytes.length - 1).toList();
  }
  return UTF8.decode(bytes);
}

nullCheck(String name, value) {
  if (value == null) {
    throw new ArgumentError("[$name] is null");
  }
  return value;
}

/// Validate that [uri] is a file that can be read by [inputProvider].
Future validateIsFile(
    CompilerInput inputProvider, Uri uri, String name, Uri source) async {
  await inputProvider.readFromUri(uri).catchError((error, StackTrace trace) {
    throw new ConfigurationError(name, source, uri, error, trace);
  });
}

/// Validate that [path] is is a file in [uri] that can be read by
/// [inputProvider].
Future validateHasFile(
    CompilerInput inputProvider, Uri uri, String name, Uri source, String path)
  async {
  Uri file = uri.resolve(path);
  await inputProvider.readFromUri(file).catchError((error, StackTrace trace) {
    throw new ConfigurationError(name, source, uri, error, trace);
  });
}

class ConfigurationError {
  final String name;
  final Uri source;
  final Uri uri;
  final error;
  final StackTrace trace;

  ConfigurationError(this.name, this.source, this.uri, this.error, this.trace);

  String toString() {
    String traceText = trace == null ? "" : "\n$trace";
    return "'$name' in '$source' ($uri) has a problem: $error$traceText";
  }
}

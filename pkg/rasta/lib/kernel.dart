// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.kernel;

import 'dart:async' show
    Future;

import 'package:kernel/ast.dart' as ir;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element,
    LibraryElement;

import 'package:compiler/src/dart_types.dart' show
    InterfaceType;

import 'custom_compiler.dart' show
    CustomCompiler;

class Kernel {
  final CustomCompiler compiler;

  final Map<ClassElement, ir.Class> loadedClasses = <ClassElement, ir.Class>{};

  Kernel(this.compiler);

  Future<ir.Library> loadLibrary(Uri uri) async {
    return libraryToIr(await compiler.libraryLoader.loadLibrary(uri));
  }

  ir.Library libraryToIr(LibraryElement library) {
    List<ir.Class> classes = <ir.Class>[];

    library.forEachLocalMember((Element e) {
      if (e.isClass) {
        classes.add(classToIr(e));
      }
    });
    String name = library.hasLibraryName ? library.name : null;
    return new ir.Library(library.canonicalUri, name: name, classes: classes);
  }

  ir.Class classToIr(ClassElement cls) => loadedClasses.putIfAbsent(cls, () {
    cls.ensureResolved(compiler.resolution);
    ir.InterfaceType supertype;
    if (cls.supertype != null) {
      supertype = interfaceTypeToIr(cls.supertype);
    }

    // TODO(ahe): Fill in the following typeParameters, implementedTypes,
    // fields, constructors, procedures;

    return new ir.NormalClass(
        supertype, name: cls.name, isAbstract: cls.isAbstract);
  });

  ir.InterfaceType interfaceTypeToIr(InterfaceType type) {
    ir.Class cls = classToIr(type.element);
    // TODO(ahe): Type arguments.
    return new ir.InterfaceType(cls);
  }
}

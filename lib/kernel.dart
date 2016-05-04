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
    FunctionElement,
    LibraryElement;

import 'package:compiler/src/dart_types.dart' show
    InterfaceType;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'kernel_visitor.dart' show
    KernelVisitor;

class Kernel {
  final CustomCompiler compiler;

  final Map<ClassElement, ir.Class> loadedClasses = <ClassElement, ir.Class>{};

  ir.Library currentLibrary;

  Kernel(this.compiler);

  Future<ir.Library> loadLibrary(Uri uri) async {
    return libraryToIr(await compiler.libraryLoader.loadLibrary(uri));
  }

  ir.Library libraryToIr(LibraryElement library) {
    if (currentLibrary != null) {
      throw new StateError("currentLibrary != null");
    }
    String name = library.hasLibraryName ? library.name : null;
    ir.Library libraryNode = new ir.Library(library.canonicalUri, name: name);
    currentLibrary = libraryNode;

    library.forEachLocalMember((Element e) {
      if (e.isClass) {
        libraryNode.addClass(classToIr(e));
      }
    });
    currentLibrary = null;
    return libraryNode;
  }

  ir.Class classToIr(ClassElement cls) => loadedClasses.putIfAbsent(cls, () {
    cls.ensureResolved(compiler.resolution);
    ir.InterfaceType supertype;
    if (cls.supertype != null) {
      supertype = interfaceTypeToIr(cls.supertype);
    }

    ir.Class classNode = new ir.NormalClass(
        supertype, name: cls.name, isAbstract: cls.isAbstract);

    cls.forEachLocalMember((Element member) {
      if (member.isFunction) {
        classNode.addMember(functionToIr(member));
      }
    });

    // TODO(ahe): Fill in the following typeParameters, implementedTypes,
    // fields, constructors, procedures;
    return classNode;
  });

  ir.InterfaceType interfaceTypeToIr(InterfaceType type) {
    ir.Class cls = classToIr(type.element);
    // TODO(ahe): Type arguments.
    return new ir.InterfaceType(cls);
  }

  ir.Procedure functionToIr(FunctionElement function) {
    compiler.analyzeElement(function);
    KernelVisitor visitor = new KernelVisitor(function, function.treeElements);
    ir.TreeNode body = function.node.body.accept(visitor);
    {
      // TODO(ahe): What goes on in this block is temporary as we complete
      // KernelVisitor.
      if (body is! ir.Statement) {
        body = new ir.ExpressionStatement(body);
      }
      if (body is! ir.Block) {
        body = new ir.Block(<ir.Statement>[body]);
      }
    }
    return new ir.Procedure(
        new ir.Name(function.name, currentLibrary), ir.ProcedureKind.Method,
        new ir.FunctionNode(body));
  }
}

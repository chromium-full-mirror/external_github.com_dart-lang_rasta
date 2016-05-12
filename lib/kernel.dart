// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.kernel;

import 'dart:async' show
    Future;

import 'dart:collection' show
    Queue;

import 'package:kernel/ast.dart' as ir;

import 'package:kernel/checks.dart' show
    CheckParentPointers;

import 'package:compiler/src/elements/elements.dart' show
    ClassElement,
    Element,
    FieldElement,
    FunctionElement,
    LibraryElement,
    Name;

import 'package:compiler/src/dart_types.dart' show
    DartType,
    InterfaceType;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'kernel_visitor.dart' show
    KernelVisitor;

typedef void VoidFunction();

class Kernel {
  final CustomCompiler compiler;

  final Map<LibraryElement, ir.Library> libraries =
      <LibraryElement, ir.Library>{};

  final Map<ClassElement, ir.Class> classes = <ClassElement, ir.Class>{};

  final Map<FunctionElement, ir.Procedure> functions =
      <FunctionElement, ir.Procedure>{};

  final Map<FieldElement, ir.Field> fields = <FieldElement, ir.Field>{};

  /// FIFO queue of work that needs to be completed before the returned AST
  /// nodes are correct.
  final Queue<VoidFunction> workQueue = new Queue<VoidFunction>();

  Kernel(this.compiler);

  void addWork(VoidFunction work) {
    workQueue.addFirst(work);
  }

  void checkMember(Element key, ir.TreeNode value) {
    if (value.parent == null) {
      compiler.reporter.internalError(key, "Missing parent on IR node.");
    }
    try {
      CheckParentPointers.check(value);
    } catch (e) {
      compiler.reporter.internalError(key, "$e");
    }
  }

  void processWorkQueue() {
    while (workQueue.isNotEmpty) {
      VoidFunction work = workQueue.removeLast();
      work();
    }
    libraries.values.forEach(CheckParentPointers.check);
    classes.forEach(checkMember);
    functions.forEach(checkMember);
  }

  ir.Name irName(String name, Element element) {
    return new ir.Name(name, libraryToIr(element.library));
  }

  ir.Name nameToIrName(Name name) {
    ir.Library library;
    if (name.isPrivate) {
      library = libraryToIr(name.library);
    }
    return new ir.Name(name.text, library);
  }

  Future<ir.Library> loadLibrary(Uri uri) async {
    return libraryToIr(await compiler.libraryLoader.loadLibrary(uri));
  }

  ir.Library libraryToIr(LibraryElement library) {
    return libraries.putIfAbsent(library, () {
      String name = library.hasLibraryName ? library.name : null;
      ir.Library libraryNode = new ir.Library(library.canonicalUri, name: name);
      addWork(() {
        library.forEachLocalMember((Element e) {
          if (e.isClass) {
            libraryNode.addClass(classToIr(e));
          } else if (e.isFunction || e.isAccessor) {
            libraryNode.addMember(functionToIr(e));
          } else if (e.isField) {
            libraryNode.addMember(fieldToIr(e));
          }
        });
      });
      return libraryNode;
    });
  }

  ir.Class classToIr(ClassElement cls) {
    cls = cls.declaration;
    return classes.putIfAbsent(cls, () {
      cls.ensureResolved(compiler.resolution);
      ir.InterfaceType supertype;
      if (cls.supertype != null) {
        supertype = interfaceTypeToIr(cls.supertype);
      }

      ir.Class classNode = new ir.NormalClass(
          supertype, name: cls.name, isAbstract: cls.isAbstract);
      addWork(() {
        classNode.parent = libraryToIr(cls.library);
        cls.implementation.forEachMember(
            (ClassElement enclosingClass, Element member) {
          if (member.enclosingClass.declaration != cls) {
            // Mixin applications include members declared in the applied
            // mixin.
            assert(cls.isMixinApplication);
            return;
          } else if (member.isFunction || member.isAccessor) {
            classNode.addMember(functionToIr(member));
          } else if (member.isField) {
            classNode.addMember(fieldToIr(member));
          }
        });
      });

      // TODO(ahe): Fill in the following typeParameters, implementedTypes,
      // fields, constructors, procedures;
      return classNode;
    });
  }

  ir.InterfaceType interfaceTypeToIr(InterfaceType type) {
    ir.Class cls = classToIr(type.element);
    // TODO(ahe): Type arguments.
    return new ir.InterfaceType(cls);
  }

  ir.DartType typeToIr(DartType type) {
    // TODO(ahe): Implement other types.
    return type is InterfaceType ?
        interfaceTypeToIr(type) : const ir.DynamicType();
  }

  void setParent(ir.Member member, Element element) {
    if (element.isLocal) {
      member.parent = elementToIr(element.enclosingElement);
    } else if (element.isTopLevel) {
      member.parent = elementToIr(element.library);
    } else if (element.isClassMember) {
      member.parent = elementToIr(element.enclosingClass);
    } else {
      member.parent = elementToIr(element.enclosingElement);
    }
  }

  ir.Procedure functionToIr(FunctionElement function) {
    if (function.isLocal) {
      compiler.reporter.internalError(function, "Local function.");
    }
    function = function.declaration;
    return functions.putIfAbsent(function, () {
      compiler.analyzeElement(function);
      if (function.isPatched) {
        function = function.implementation;
      }
      ir.Procedure procedure = new ir.Procedure(
          irName(function.name, function), ir.ProcedureKind.Method, null);
      addWork(() {
        setParent(procedure, function);
        KernelVisitor visitor =
            new KernelVisitor(function, function.treeElements, this);
        ir.FunctionNode functionNode = compiler.reporter.withCurrentElement(
            function, () => function.node.accept(visitor));
        // TODO(ahe): Add addFunction/set function to [ir.Procedure].
        functionNode.parent = procedure;
        procedure.function = functionNode;
        visitor.locals.forEach(checkMember);
      });
      return procedure;
    });
  }

  ir.Field fieldToIr(FieldElement field) {
    field = field.declaration;
    return fields.putIfAbsent(field, () {
      compiler.analyzeElement(field);
      if (field.isPatched) {
        field = field.implementation;
      }
      ir.Field fieldNode = new ir.Field(nameToIrName(field.memberName));
      // TODO(ahe): Add type, etc.
      addWork(() {
        setParent(fieldNode, field);
        // TODO(ahe): Visit initializer.
      });
      return fieldNode;
    });
  }

  ir.TreeNode elementToIr(Element element) {
    if (element.isLibrary) return libraryToIr(element);
    if (element.isClass) return classToIr(element);
    if (element.isFunction) return functionToIr(element);
    if (element.isField) return fieldToIr(element);
    throw "unhandled element: $element";
  }
}

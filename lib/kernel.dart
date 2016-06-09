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
    ImportElement,
    LibraryElement,
    MixinApplicationElement,
    Name,
    TypeVariableElement;

import 'package:compiler/src/dart_types.dart' show
    DartType,
    FunctionType,
    InterfaceType,
    TypeKind,
    TypeVariableType;

import 'package:compiler/src/diagnostics/spannable.dart' show
    Spannable;

import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind;

import 'custom_compiler.dart' show
    CustomCompiler;

import 'kernel_visitor.dart' show
    IrFunction,
    KernelVisitor;

import 'package:compiler/src/constants/expressions.dart' show
    TypeConstantExpression;

typedef void WorkAction(bool isTargeted);

class WorkItem {
  final Element element;
  final WorkAction action;

  WorkItem(this.element, this.action);
}

class Kernel {
  final CustomCompiler compiler;

  final Map<LibraryElement, ir.Library> libraries =
      <LibraryElement, ir.Library>{};

  final Map<ClassElement, ir.Class> classes = <ClassElement, ir.Class>{};

  final Map<FunctionElement, ir.Member> functions =
      <FunctionElement, ir.Member>{};

  final Map<FieldElement, ir.Field> fields = <FieldElement, ir.Field>{};

  final Map<TypeVariableElement, ir.TypeParameter> typeParameters =
      <TypeVariableElement, ir.TypeParameter>{};

  /// FIFO queue of work that needs to be completed before the returned AST
  /// nodes are correct.
  final Queue<WorkItem> workQueue = new Queue<WorkItem>();

  LibraryElement targetLibrary;

  Kernel(this.compiler);

  bool hasMainMethod(Uri uri) {
    LibraryElement library = compiler.libraryLoader.lookupLibrary(uri);
    return library.localLookup("main") != null;
  }

  bool isTargeted(Element element) {
    if (targetLibrary == null) return true;
    return element.library.declaration == targetLibrary;
  }

  void addWork(Element element, WorkAction action) {
    workQueue.addLast(new WorkItem(element, action));
  }

  void checkMember(Element key, ir.TreeNode value) {
    if (!isTargeted(key)) return;
    if (value.parent == null) {
      compiler.reporter.internalError(key, "Missing parent on IR node.");
    }
    try {
      CheckParentPointers.check(value);
    } catch (e, s) {
      compiler.reporter.internalError(key, "$e\n$s");
    }
  }

  void processWorkQueue({Uri targetLibrary}) {
    if (targetLibrary != null) {
      this.targetLibrary = compiler.libraryLoader.lookupLibrary(targetLibrary);
      assert(this.targetLibrary != null);
    }
    while (workQueue.isNotEmpty) {
      WorkItem work = workQueue.removeFirst();
      work.action(isTargeted(work.element));
    }
    assert(() {
      libraries.values.forEach(CheckParentPointers.check);
      classes.forEach(checkMember);
      functions.forEach(checkMember);
      fields.forEach(checkMember);
      return true;
    });
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
    library = library.declaration;
    return libraries.putIfAbsent(library, () {
      String name = library.hasLibraryName ? library.libraryName : null;
      ir.Library libraryNode = new ir.Library(
          library.canonicalUri, name: name, classes: null, procedures: null,
          fields: null);
      addWork(library, (bool isTargeted) {
        Queue<ir.Class> classes = new Queue<ir.Class>();
        Queue<ir.Member> members = new Queue<ir.Member>();
        library.implementation.forEachLocalMember((Element e) {
          if (e.isClass) {
            classes.addFirst(classToIr(e));
          } else if (e.isFunction || e.isAccessor) {
            members.addFirst(functionToIr(e));
          } else if (e.isField) {
            members.addFirst(fieldToIr(e));
          } else if (e.isTypedef) {
            // Ignored, typedefs are unaliased on use.
          } else {
            internalError(e, "Unhandled library member: $e");
          }
        });
        // The elements were inserted in reverse order as forEachLocalMember
        // above gives them in reversed order.
        classes.forEach(libraryNode.addClass);
        members.forEach(libraryNode.addMember);
      });
      return libraryNode;
    });
  }

  ir.Class classToIr(ClassElement cls) {
    if (cls.isMixinApplication) return mixinApplicationToIr(cls);
    cls = cls.declaration;
    return classes.putIfAbsent(cls, () {
      cls.ensureResolved(compiler.resolution);
      ir.NormalClass classNode = new ir.NormalClass(
          null, name: cls.name, isAbstract: cls.isAbstract,
          typeParameters: null, implementedClasses: null, constructors: null,
          procedures: null, fields: null);
      addWork(cls, (bool isTargeted) {
        if (cls.supertype != null) {
          classNode.superType = interfaceTypeToIr(cls.supertype);
        }
        classNode.parent = libraryToIr(cls.library);
        if (cls.isUnnamedMixinApplication) {
          classNode.enclosingLibrary.addClass(classNode);
        }
        cls.implementation.forEachMember(
            (ClassElement enclosingClass, Element member) {
          if (member.enclosingClass.declaration != cls) {
            internalError(cls, "`$member` isn't mine.");
          } else if (member.isFunction || member.isAccessor ||
                     member.isConstructor) {
            classNode.addMember(functionToIr(member));
          } else if (member.isField) {
            classNode.addMember(fieldToIr(member));
          } else {
            internalError(member, "Unhandled class member: $member");
          }
        });
        classNode.typeParameters.addAll(typeVariablesToIr(cls.typeVariables));
        for (ir.InterfaceType interface in typesToIr(cls.interfaces.toList())) {
          classNode.implementedTypes.add(interface);
        }
      });
      return classNode;
    });
  }

  ir.MixinClass mixinApplicationToIr(MixinApplicationElement cls) {
    cls = cls.declaration;
    return classes.putIfAbsent(cls, () {
      cls.ensureResolved(compiler.resolution);
      InterfaceType supertype = null; // Computed and set below.
      InterfaceType mixedInType = null; // Computed and set below.
      String name = cls.isUnnamedMixinApplication ? null : cls.name;
      ir.MixinClass classNode = new ir.MixinClass(
          supertype, mixedInType, name: name,
          isAbstract: cls.isAbstract,
          typeParameters: null,
          implementedClasses: null,
          constructors: null);
      addWork(cls, (bool isTargeted) {
        classNode.superType = interfaceTypeToIr(cls.supertype);
        classNode.parent = libraryToIr(cls.library);
        if (cls.isUnnamedMixinApplication) {
          classNode.enclosingLibrary.addClass(classNode);
        }
        classNode.mixedInType = interfaceTypeToIr(cls.mixinType);
        classNode.typeParameters.addAll(typeVariablesToIr(cls.typeVariables));
        for (ir.InterfaceType interface in typesToIr(cls.interfaces.toList())) {
          classNode.implementedTypes.add(interface);
        }
        cls.implementation.forEachMember(
            (ClassElement enclosingClass, Element member) {
          if (member.isConstructor) {
            ir.Constructor constructor = functionToIr(member);
            classNode.constructors.add(constructor);
            constructor.parent = classNode;
          }
        });
      });
      return classNode;
    });
  }

  ir.InterfaceType interfaceTypeToIr(InterfaceType type) {
    ir.Class cls = classToIr(type.element);
    if (type.typeArguments.isEmpty) {
      return cls.rawType;
    } else {
      return new ir.InterfaceType(cls, typesToIr(type.typeArguments));
    }
  }

  // TODO(ahe): Remove this method when dart2js support generic type arguments.
  List<ir.DartType> typeArgumentsNotImplemented() {
    return const <ir.DartType>[];
  }

  // TODO(ahe): Remove this method when dart2js support generic type arguments.
  List<ir.TypeParameter> typeParametersNotImplemented() {
    return const <ir.TypeParameter>[];
  }

  ir.FunctionType functionTypeToIr(FunctionType type) {
    List<ir.TypeParameter> typeParameters = typeParametersNotImplemented();
    int requiredParameterCount = type.parameterTypes.length;
    List<ir.DartType> positionalParameters =
        new List<ir.DartType>.from(typesToIr(type.parameterTypes))
            ..addAll(typesToIr(type.optionalParameterTypes));
    Map<String, ir.DartType> namedParameters = <String, ir.DartType>{};
    for (int i = 0; i < type.namedParameters.length; i++) {
      namedParameters[type.namedParameters[i]] =
          typeToIr(type.namedParameterTypes[i]);
    }
    ir.DartType returnType = typeToIr(type.returnType);

    return new ir.FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters, typeParameters: typeParameters,
        requiredParameterCount: requiredParameterCount);
  }

  ir.TypeParameterType typeVariableTypeToIr(TypeVariableType type) {
    return new ir.TypeParameterType(typeVariableToIr(type.element));
  }

  List<ir.DartType> typesToIr(List<DartType> types) {
    List<ir.DartType> result = new List<ir.DartType>(types.length);
    for (int i = 0; i < types.length; i++) {
      result[i] = typeToIr(types[i]);
    }
    return result;
  }

  ir.DartType typeToIr(DartType type) {
    switch (type.kind) {
      case TypeKind.FUNCTION:
        return functionTypeToIr(type);

      case TypeKind.INTERFACE:
        return interfaceTypeToIr(type);

      case TypeKind.STATEMENT:
        throw "Internal error: statement type: $type.";

      case TypeKind.TYPEDEF:
        type.computeUnaliased(compiler.resolution);
        return typeToIr(type.unaliased);

      case TypeKind.TYPE_VARIABLE:
        return typeVariableTypeToIr(type);

      case TypeKind.MALFORMED_TYPE:
        return const ir.InvalidType();

      case TypeKind.DYNAMIC:
        return const ir.DynamicType();

      case TypeKind.VOID:
        return const ir.VoidType();
    }
  }

  ir.DartType typeLiteralToIr(TypeConstantExpression constant) {
    return typeToIr(constant.type);
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

  ir.Member functionToIr(FunctionElement function) {
    if (function.isLocal) {
      compiler.reporter.internalError(function, "Local function.");
    }
    function = function.declaration;
    return functions.putIfAbsent(function, () {
      compiler.analyzeElement(function);
      compiler.enqueuer.resolution.emptyDeferredTaskQueue();
      function = function.implementation;
      ir.Member member;
      ir.Constructor constructor;
      ir.Procedure procedure;
      ir.Name name = irName(function.name, function);
      if (function.isGenerativeConstructor) {
        member = constructor = new ir.Constructor(
            null, name: name, isConst: function.isConst,
            isExternal: function.isExternal, initializers: null);
      } else {
        member = procedure = new ir.Procedure(
            name, null, null, isAbstract: function.isAbstract,
            isStatic: function.isStatic || function.isTopLevel
                || function.isFactoryConstructor,
            isExternal: function.isExternal,
            isConst: false); // TODO(ahe): When is this true?
      }
      addWork(function, (bool isTargeted) {
        setParent(member, function);
        if (!isTargeted) return;
        KernelVisitor visitor =
            new KernelVisitor(function, function.treeElements, this);
        IrFunction irFunction = visitor.buildFunction();
        // TODO(ahe): Add addFunction/set function to [ir.Procedure].
        irFunction.node.parent = member;
        if (irFunction.isConstructor) {
          assert(irFunction.kind == null);
          constructor.function = irFunction.node;
          constructor.initializers = irFunction.initializers;
          // TODO(ahe): Add setInitializers to [ir.Constructor].
          for (ir.Initializer initializer in irFunction.initializers) {
            initializer.parent = constructor;
          }
        } else {
          assert(irFunction.kind != null);
          procedure.function = irFunction.node;
          procedure.kind = irFunction.kind;
        }
        assert(() {
          visitor.locals.forEach(checkMember);
          return true;
        });
      });
      return member;
    });
  }

  ir.Field fieldToIr(FieldElement field) {
    field = field.declaration;
    return fields.putIfAbsent(field, () {
      compiler.analyzeElement(field);
      field = field.implementation;
      ir.Field fieldNode = new ir.Field(
          nameToIrName(field.memberName), type: typeToIr(field.type),
          initializer: null, isFinal: field.isFinal,
          isStatic: field.isStatic || field.isTopLevel, isConst: field.isConst);
      addWork(field, (bool isTargeted) {
        setParent(fieldNode, field);
        if (!isTargeted) return;
        if (!field.isInstanceMember && field.initializer != null) {
          KernelVisitor visitor =
              new KernelVisitor(field, field.treeElements, this);
          fieldNode.initializer = visitor.buildInitializer()
              ..parent = fieldNode;
        }
      });
      return fieldNode;
    });
  }

  ir.TypeParameter typeVariableToIr(TypeVariableElement variable) {
    variable = variable.declaration;
    return typeParameters.putIfAbsent(variable, () {
      ir.TypeParameter parameter = new ir.TypeParameter(variable.name, null);
      addWork(variable, (bool isTargeted) {
        // TODO(ahe): This assignment will probably not be correct when dart2js
        // supports generic methods.
        ClassElement cls = variable.typeDeclaration;
        cls.ensureResolved(compiler.resolution);
        parameter.parent = classToIr(cls);
        parameter.bound = typeToIr(variable.bound);
      });
      return parameter;
    });
  }

  List<ir.TypeParameter> typeVariablesToIr(List<DartType> variables) {
    List<ir.TypeParameter> result =
        new List<ir.TypeParameter>(variables.length);
    for (int i = 0; i < variables.length; i++) {
      TypeVariableType type = variables[i];
      result[i] = typeVariableToIr(type.element);
    }
    return result;
  }

  ir.TreeNode elementToIr(Element element) {
    if (element.isLibrary) return libraryToIr(element);
    if (element.isClass) return classToIr(element);
    if (element.isFunction || element.isAccessor) return functionToIr(element);
    if (element.isField) return fieldToIr(element);
    throw "unhandled element: $element";
  }

  void debugMessage(Spannable spannable, String message) {
    compiler.reporter.reportHintMessage(
        spannable, MessageKind.GENERIC, {'text': message});
  }

  void internalError(Spannable spannable, String message) {
    compiler.reporter.internalError(spannable, message);
    throw message;
  }

  forEachLibraryElement(f(LibraryElement library)) {
    return compiler.libraryLoader.libraries.forEach(f);
  }

  /// Compute all the dependencies on the library with [uri] (including the
  /// library itself). This is useful for creating a Kernel IR `Program`.
  List<ir.Library> libraryDependencies(Uri uri) {
    List<ir.Library> result = <ir.Library>[];
    Queue<LibraryElement> notProcessed = new Queue<LibraryElement>();
    Set<LibraryElement> seen = new Set<LibraryElement>();
    LibraryElement library = compiler.libraryLoader.lookupLibrary(uri);
    notProcessed.addLast(library);
    seen.add(library);
    LibraryElement core =
        compiler.libraryLoader.lookupLibrary(Uri.parse("dart:core"));
    if (seen.add(core)) {
      // `dart:core` is implicitly imported by most libraries, and for some
      // reason not included in `library.imports` below.
      notProcessed.addLast(core);
    }
    while (notProcessed.isNotEmpty) {
      LibraryElement library = notProcessed.removeFirst();
      ir.Library irLibrary = libraries[library];
      if (irLibrary == null) continue;
      result.add(irLibrary);
      for (ImportElement import in library.imports) {
        if (seen.add(import.importedLibrary)) {
          notProcessed.addLast(import.importedLibrary);
        }
      }
      for (ImportElement import in library.implementation.imports) {
        if (seen.add(import.importedLibrary)) {
          notProcessed.addLast(import.importedLibrary);
        }
      }
    }
    return result;
  }
}

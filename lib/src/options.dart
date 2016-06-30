// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.options;

import 'dart:async' show
    Future;

import 'dart:isolate' show
    Isolate;

const Map<String, OptionDescription> descriptions =
    const <String, OptionDescription>{
    "--library": const OptionDescription(Option.library),

    "--program": const OptionDescription(Option.program),

    "--verbose": const OptionDescription(Option.verbose),

    "--list-dependencies":
        const OptionDescription(Option.listDependencies, hasArgument: true),

    "--batch": const OptionDescription(Option.batch),

    "--pattern": const OptionDescription(Option.pattern, hasArgument: true),

    "--target": const OptionDescription(Option.target, hasArgument: true),

    "--throw-on-error": const OptionDescription(
        Option.throwOnError, hasOptionalArgument: true),
};

const List<Option> supportedBatchOptions = const <Option>[
    Option.batch,
    Option.verbose,
    Option.target,
    Option.throwOnError,

    // TODO(ahe): These options shouldn't be supported in batch server
    // mode. See run_batch.dart.
    Option.argument,
    Option.library,
    Option.program,
    Option.pattern,
];

enum Option {
  /// `--library`.
  library,

  /// `--program`.
  program,

  /// `--verbose`.
  verbose,

  /// `--list-dependencies`.
  listDependencies,

  /// `--batch`.
  batch,

  /// `--pattern`.
  pattern,

  /// `--target`.
  target,

  /// `--throw-on-error`.
  throwOnError,

  // `--` which signals option parsing should end (the rest are arguments).
  skip,

  // Non-option argument, for example, a file name.
  argument,
}

class OptionDescription {
  final Option option;
  final bool hasArgument;
  final bool hasOptionalArgument;

  const OptionDescription(
      this.option, {this.hasArgument: false, this.hasOptionalArgument: false});
}

class OptionValue {
  final Option option;
  final String argument;

  const OptionValue(this.option, [this.argument]);
}

class Options {
  final Uri input;
  final Uri output;
  final Uri dependenciesFile;
  final Uri targetSpecification;
  final bool generateLibrary;
  final bool isVerbose;
  final bool isBatch;
  final Pattern pattern;
  final bool throwOnError;
  final int throwOnErrorCount;

  Options(this.input, this.output,
          {this.dependenciesFile, this.targetSpecification,
           this.generateLibrary, this.isVerbose, this.isBatch, this.pattern,
           this.throwOnError, this.throwOnErrorCount});
}

class OptionParser {
  final Iterator<String> arguments;
  final Uri base;

  OptionParser(Iterable<String> arguments, this.base)
      : arguments = arguments.iterator;

  Future<Options> parse() async {
    List<OptionValue> values = parseValues();

    // Null means not specified.
    bool generateLibrary;
    bool isVerbose;
    bool isBatch;
    bool throwOnError;
    int throwOnErrorCount = 1;
    Uri dependenciesFile;
    Uri targetSpecification;
    List<String> uris = <String>[];
    Pattern pattern;
    for (OptionValue value in values) {
      switch (value.option) {
        case Option.library:
          generateLibrary = true;
          break;

        case Option.program:
          generateLibrary = false;
          break;

        case Option.verbose:
          isVerbose = true;
          break;

        case Option.listDependencies:
          dependenciesFile = Uri.base.resolveUri(new Uri.file(value.argument));
          break;

        case Option.target:
          targetSpecification =
              Uri.base.resolveUri(new Uri.file(value.argument));
          break;

        case Option.batch:
          isBatch = true;
          break;

        case Option.pattern:
          pattern = (value.argument.contains(new RegExp(r'[*$^]')))
              ? new RegExp(value.argument) : value.argument;
          break;

        case Option.throwOnError:
          throwOnError = true;
          if (value.argument != null) {
            throwOnErrorCount = int.parse(value.argument);
          }
          break;

        case Option.skip:
          throw "internal error";

        case Option.argument:
          uris.add(value.argument);
      }
    }
    if (targetSpecification == null) {
      Uri script = await Isolate.resolvePackageUri(
          Uri.parse("package:rasta/src/options.dart"));
      targetSpecification =
          Uri.base.resolveUri(script).resolve("../../dart_vm_standalone.json");
    }
    Uri input;
    Uri output;
    if (isBatch == true) {
      if (uris.length == 0) {
        // All set. Read compilation tasks from stdin.
      } else if (uris.length == 1) {
        input = Uri.base.resolve(uris.single);
      } else {
        assert(uris.length > 1);
        throw "Additional arguments: '${uris.join("' '")}'.";
      }
      Set<Option> extraOptions = values.map((v) => v.option).toSet()
          ..removeAll(supportedBatchOptions);
      if (extraOptions.isNotEmpty) {
        throw "Batch mode (--batch) doesn't support these options: "
            "'${extraOptions.join("' '")}'.";
      }
    } else if (uris.length == 2) {
      if (uris[0] != "-") {
        // `-` means read from `stdin`.
        input = Uri.base.resolve(uris[0]);
      } else {
        throw "Unable to read from stdin (-).";
      }
      if (uris[1] != "-") {
        // `-` means print to stdout.
        output = Uri.base.resolve(uris[1]);
      }
    } else if (uris.length == 0) {
      throw "Missing required argument: [input].";
    } else if (uris.length == 1) {
      if (uris[0] != "-") {
        // `-` means read from `stdin`.
        input = Uri.base.resolve(uris[0]);
      } else {
        throw "Unable to read from stdin (-).";
      }
      output = null; // Print on stdout.
    } else {
      assert(uris.length > 2);
      String extraArguments = uris.join("' '");
      throw "Additional argument: '$extraArguments'.";
    }
    return new Options(
        input, output, dependenciesFile: dependenciesFile,
        targetSpecification: targetSpecification,
        generateLibrary: generateLibrary, isVerbose: isVerbose ?? false,
        isBatch: isBatch ?? false, pattern: pattern,
        throwOnError: throwOnError ?? false,
        throwOnErrorCount: throwOnErrorCount);
  }

  List<OptionValue> parseValues() {
    OptionValue value;
    List<OptionValue> values = <OptionValue>[];
    while ((value = nextOptionValue()) != null) {
      if (value.option == Option.skip) break;
      values.add(value);
    }
    while (arguments.moveNext()) {
      values.add(new OptionValue(Option.argument, arguments.current));
    }
    return values;
  }

  OptionValue nextOptionValue() {
    if (!arguments.moveNext()) return null;
    String name = arguments.current;
    if (name == "--") return const OptionValue(Option.skip);
    if (name == "-" || !name.startsWith("-")) {
      return new OptionValue(Option.argument, name);
    }

    String argument;
    int equalSignIndex = name.indexOf("=");
    if (equalSignIndex != -1) {
      argument = name.substring(equalSignIndex + 1);
      name = name.substring(0, equalSignIndex);
    }
    OptionDescription description = descriptions[name];
    if (description == null) {
      throw "Unknown option: '$name'.";
    }
    if (description.hasOptionalArgument) {
      // If an argument is optional, we require this form `--option=argument`,
      // not `--option argument`.
    } else if (description.hasArgument) {
      argument ??= getArgument(name);
    } else if (argument != null) {
      throw "Extra argument to option '$name'.";
    }

    return new OptionValue(description.option, argument);
  }

  String getArgument(String name) {
    if (!arguments.moveNext()) {
      throw "Missing argument to option '$name'";
    }
    return arguments.current;
  }
}

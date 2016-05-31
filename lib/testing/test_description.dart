// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.testing.test_description;

import 'dart:io' show
    File,
    FileSystemEntity;

class TestDescription implements Comparable<TestDescription> {
  final File file;

  TestDescription(this.file);

  Uri get uri => file.uri;

  String get shortName {
    String baseName = uri.path.split("/").last;
    return baseName.substring(0, baseName.length - ".dart".length);
  }

  static TestDescription from(FileSystemEntity entity) {
    if (entity is File) {
      if ("${entity.uri}".endsWith("_test.dart")) {
        return new TestDescription(entity);
      }
    }
    return null;
  }

  int compareTo(TestDescription other) => "$uri".compareTo("${other.uri}");
}

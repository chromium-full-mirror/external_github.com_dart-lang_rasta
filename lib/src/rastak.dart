// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.rastak;

import 'dart:async' show
    Future;

import 'dart:isolate' show
    ReceivePort;

import 'rastask.dart' show
    Rastask;

Future<Null> main(List<String> arguments, isolateArgument) async {
  final ReceivePort port = new ReceivePort();
  Stopwatch wallClock = new Stopwatch()..start();
  Rastask task = await Rastask.setup(wallClock, arguments);

  // Due to an implementation detail (an optimization that may be wrong) in
  // zones, a `then` handler on a future may be run recursively inside a
  // measuring zone. If the handler belongs to a non-measuring zone, its run
  // time will be incorrectly counted in the measuring zone. In practice, the
  // library loader was blamed for the execution time of rastak. By adding a
  // Rasta task, we avoid counting rastak towards the library loader, and we
  // get a counter for rastak.
  await task.measure(task.run);

  port.close();
}

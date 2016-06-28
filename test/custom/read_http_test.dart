// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.read_http_test;

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:rasta/testing.dart";

Future<Null> main() async {
  Uri serverScript = Uri.base.resolve("test/custom/read_http_server.dart");
  Uri clientScript = Uri.base.resolve("test/custom/read_http_client.dart");
  Process server = await startDart(serverScript);
  await server.stdin.close();
  server.stderr.drain();
  String uri = await server.stdout.transform(UTF8.decoder)
      .transform(new LineSplitter()).first;
  Process client = await startDart(clientScript, <String>[uri]);
  await client.stdin.close();
  Future stdoutFuture = client.stdout.listen(stdout.add).asFuture();
  Future stderrFuture = client.stderr.listen(stderr.add).asFuture();
  int exitCode = await client.exitCode;
  await stdoutFuture;
  await stderrFuture;
  if (exitCode != 0) {
    print("Non-zero exit code from client: $exitCode");
  } else {
    print("Client exited successfully.");
  }

  server.kill();
}

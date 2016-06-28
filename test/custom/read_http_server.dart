// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Helper HTTP server that doesn't close the connection.
library rasta.read_http_server;

import 'dart:async' show
    Future,
    StreamSubscription;

import 'dart:io' show
    HttpRequest,
    HttpServer,
    stdout;

Future<Null> main() async {
  HttpServer server = await HttpServer.bind('127.0.0.1', 0);
  server.idleTimeout = null;
  Uri uri = new Uri(
      scheme: "http", host: server.address.host, port: server.port, path: "/");
  stdout.writeln(uri);
  await stdout.close();
  StreamSubscription subscription = server.listen(null);

  void handleRequest(HttpRequest request) {
    request.response.statusCode = 404;
    request.response.bufferOutput = false;
    request.response.write("404");
    request.response.flush();
  }

  subscription.onData(handleRequest);
}

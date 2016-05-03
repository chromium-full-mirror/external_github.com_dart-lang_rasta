// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library rasta.custom_impact_transformer;

import 'package:compiler/src/common/backend_api.dart' show
    ImpactTransformer;

import 'src/unimplemented.dart' show
    unimplemented;

class CustomImpactTransformer extends ImpactTransformer {
  @override transformResolutionImpact(worldImpact) => worldImpact;

  @override transformCodegenImpact(impact) => unimplemented;
}

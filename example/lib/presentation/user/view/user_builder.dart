import 'package:y_lints/annotations.dart';

import '../../_widget_stubs.dart';

// The example uses local stubs instead of `package:flutter/` so it compiles
// without a Flutter SDK. feature_builder_must_be_widget resolves the
// superclass element and checks its library URI, so stubs don't satisfy it
// — real projects extending Flutter's StatelessWidget/StatefulWidget will.
// ignore: feature_builder_must_be_widget
@FeatureBuilder()
class UserBuilder extends StatelessWidget {
  const UserBuilder();
}

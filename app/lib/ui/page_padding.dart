import 'package:flutter/widgets.dart';

/// Padding for a full page's list: it scrolls under the phone's own
/// navigation buttons but ends above them.
EdgeInsets pagePadding(BuildContext context) =>
    EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom);

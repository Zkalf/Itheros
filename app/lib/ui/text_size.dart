import 'package:flutter/widgets.dart';

/// The size of [text] in [style], as a Text in [context] draws it: with the
/// default text style, the bold text setting of the phone and [textScaler],
/// by default the text scale of the phone. The text breaks only at its "\n".
Size textSizeOf(
  BuildContext context,
  String text,
  TextStyle? style, {
  TextScaler? textScaler,
}) {
  var drawn = DefaultTextStyle.of(context).style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    drawn = drawn.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: drawn),
    textDirection: Directionality.of(context),
    textScaler: textScaler ?? MediaQuery.textScalerOf(context),
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

import 'package:flutter/material.dart';

/// Animate actual score changes only, retaining tabular digit alignment.
class AnimatedScore extends StatelessWidget {
  const AnimatedScore(this.value, {super.key, this.style, this.textAlign = TextAlign.start});
  final String value;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) => RepaintBoundary(child: AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft,
      children: [...previous, if (current != null) current],
    ),
    child: Text(value, key: ValueKey(value), textAlign: textAlign, maxLines: 2,
      overflow: TextOverflow.ellipsis, style: style),
  ));
}

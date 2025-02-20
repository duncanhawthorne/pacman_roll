import 'package:flutter/material.dart';

import 'palette.dart';

Widget popupDialog({required List<Widget> children, double spacing = 16}) {
  return purePopup(
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Palette.seed.color, width: 3),
        borderRadius: BorderRadius.circular(10),
        color: Palette.background.color,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40.0, 12, 40, 12),
        child: Column(
          spacing: spacing,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    ),
  );
}

Widget purePopup({required Widget child}) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(padding: const EdgeInsets.all(75.0), child: child),
    ),
  );
}

Widget titleWidget({required Widget child}) {
  return Padding(padding: const EdgeInsets.fromLTRB(0, 8, 0, 8), child: child);
}

Widget titleText({required String text}) {
  return titleWidget(
    child: Text(text, style: textStyleHeading, textAlign: TextAlign.center),
  );
}

Widget bodyWidget({required Widget child}) {
  return child;
}

Widget bottomRowWidget({required List<Widget> children}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: Row(
      spacing: 10,
      children: List<Widget>.generate(
        children.length,
        (int index) => children[index],
        growable: false,
      ),
    ),
  );
}

const TextStyle textStyleHeading = TextStyle(
  fontFamily: 'Press Start 2P',
  fontSize: 28,
);

const TextStyle textStyleBody = TextStyle(
  fontFamily: 'Press Start 2P',
  color: Palette.textColor,
);

const TextStyle textStyleBodyDull = TextStyle(
  fontFamily: 'Press Start 2P',
  color: Palette.dullColor,
);

const TextStyle textStyleBodyPacman = TextStyle(
  fontFamily: 'Press Start 2P',
  color: Palette.pacmanColor,
);

const Color _defaultButtonStyleBorderColor = Palette.seedColor;

ButtonStyle buttonStyle({
  Color? borderColor = _defaultButtonStyleBorderColor,
  bool small = false,
}) {
  final Color borderColorReal = borderColor ?? _defaultButtonStyleBorderColor;
  return TextButton.styleFrom(
    backgroundColor: Palette.background.color,
    minimumSize: Size.zero,
    padding: EdgeInsets.all(small ? 16 : 24),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: borderColorReal, width: 3),
    ),
  );
}

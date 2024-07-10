import 'package:flutter/material.dart';

import 'palette.dart';

Widget pacmanDialog({required Widget child}) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(75.0),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Palette.borderColor.color, width: 3),
              borderRadius: BorderRadius.circular(10),
              color: Palette.playSessionBackground.color),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 4, 40, 4), child: child),
        ),
      ),
    ),
  );
}

Widget titleWidget({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
    child: child,
  );
}

Widget titleText({required String text}) {
  return titleWidget(
    child: Text(text, style: textStyleHeading, textAlign: TextAlign.center),
  );
}

Widget bodyWidget({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: child,
  );
}

Widget bottomRowWidget({required List<Widget> children}) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
      child: Row(
          children: List<Widget>.generate(
              children.length,
              (int index) => Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                    child: children[index],
                  ),
              growable: false)));
}

TextStyle textStyleHeading =
    const TextStyle(fontFamily: 'Press Start 2P', fontSize: 28);

TextStyle textStyleBody = const TextStyle(
    fontFamily: 'Press Start 2P', color: Palette.playSessionContrast);

TextStyle textStyleBodyDull = const TextStyle(
    fontFamily: 'Press Start 2P', color: Palette.playSessionDull);

ButtonStyle buttonStyleNormal = TextButton.styleFrom(
  minimumSize: Size.zero,
  padding: const EdgeInsets.all(24.0),
  //padding: EdgeInsets.zero,
  //tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    side: BorderSide(
      color: Palette.blueMaze,
      width: 3,
    ),
  ),
);

ButtonStyle buttonStyleWarning = TextButton.styleFrom(
  minimumSize: Size.zero,
  padding: const EdgeInsets.all(24.0),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    side: BorderSide(
      color: Palette.redWarning,
      width: 3,
    ),
  ),
);

ButtonStyle buttonStyleSmallActive = TextButton.styleFrom(
  minimumSize: Size.zero,
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    side: BorderSide(
      color: Palette.blueMaze,
      width: 3,
    ),
  ),
);

ButtonStyle buttonStyleSmallPassive = TextButton.styleFrom(
  minimumSize: Size.zero,
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    side: BorderSide(
      color: Palette.transp,
      width: 3,
    ),
  ),
);

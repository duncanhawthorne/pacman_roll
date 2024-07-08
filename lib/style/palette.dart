import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.
///
/// The reason we're not going with something like Material Design's
/// `Theme` is simply that this is simpler to work with and yet gives
/// us everything we need for a game.
///
/// Games generally have more radical color palettes than apps. For example,
/// every level of a game can have radically different colors.
/// At the same time, games rarely support dark mode.
///
/// Colors here are implemented as getters so that hot reloading works.
/// In practice, we could just as easily implement the colors
/// as `static const`. But this way the palette is more malleable:
/// we could allow players to customize colors, for example,
/// or even get the colors from the network.
class Palette {
  static const seed = PaletteEntry(blueMaze); //Color(0xFF000000) //0xFF0050bc
  static const text =
      PaletteEntry(white); //const PaletteEntry(Color(0xee352b42));
  static const mainBackground = PaletteEntry(black); //0xffa2fff3
  static const mainContrast = PaletteEntry(white);
  static const backgroundLevelSelection = PaletteEntry(Color(0xffffcd75));

  static const playSessionBackground = PaletteEntry(black); //0xffa2fff3

  static const borderColor = PaletteEntry(blueMaze); //0xffa2fff3
  static const backgroundSettings = PaletteEntry(Color(0xffbfc8e3));

  static const pageTransition = PaletteEntry(black); //0xffa2fff3

  static const flameGameBackground = PaletteEntry(black);

  static const black = Color(0xff000000);
  static const darkGrey = Color(0xff222222);
  static const lightBluePMR = Color(0xffa2fff3);
  static const blueMaze = Color(0xFF3B32D4);
  static const redWarning = Colors.red;
  static const transp = Color(0x00000000);
  static const white = Color(0xffffffff);
  static const playSessionContrast = white; //0xffa2fff3
  static const playSessionDull = Colors.grey; //0xffa2fff3

  static const transpPalette = PaletteEntry(transp);
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

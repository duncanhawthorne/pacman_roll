import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.

class Palette {
  static const seed = PaletteEntry(blueMaze); //Color(0xFF000000) //0xFF0050bc
  static const text =
      PaletteEntry(white); //const PaletteEntry(Color(0xee352b42));
  static const mainBackground = PaletteEntry(black); //0xffa2fff3
  static const mainContrast = PaletteEntry(white);
  static const backgroundLevelSelection = PaletteEntry(Color(0xffffcd75));
  static const yellowPacman = Colors.yellowAccent;

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

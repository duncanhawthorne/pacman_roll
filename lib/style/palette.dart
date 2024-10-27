import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.

class Palette {
  static const PaletteEntry seed = PaletteEntry(seedColor);
  static const PaletteEntry text = PaletteEntry(textColor);
  static const PaletteEntry pacman = PaletteEntry(pacmanColor);
  static const PaletteEntry background = PaletteEntry(_black);
  static const PaletteEntry warning = PaletteEntry(_red);
  static const PaletteEntry transp = PaletteEntry(_transp);
  static const PaletteEntry dull = PaletteEntry(dullColor);

  static const Color seedColor = _blueMaze;
  static const Color textColor = _white;
  static const MaterialColor dullColor = _grey;
  static const MaterialAccentColor pacmanColor = _yellow;

  static const MaterialAccentColor _yellow = Colors.yellowAccent;
  static const Color _black = Color(0xff000000);
  static const Color _blueMaze = Color(0xFF3B32D4);
  static const MaterialColor _red = Colors.red;
  static const Color _transp = Color(0x00000000);
  static const Color _white = Color(0xffffffff);
  static const MaterialColor _grey = Colors.grey;
}

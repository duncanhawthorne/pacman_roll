import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// A palette of colors to be used in the game.

class Palette {
  static const seed = PaletteEntry(seedColor);
  static const text = PaletteEntry(textColor);
  static const pacman = PaletteEntry(_yellow);
  static const background = PaletteEntry(_black);
  static const warning = PaletteEntry(_red);
  static const transp = PaletteEntry(_transp);
  static const dull = PaletteEntry(dullColor);

  static const seedColor = _blueMaze;
  static const textColor = _white;
  static const dullColor = _grey;

  static const _yellow = Colors.yellowAccent;
  static const _black = Color(0xff000000);
  static const _blueMaze = Color(0xFF3B32D4);
  static const _red = Colors.red;
  static const _transp = Color(0x00000000);
  static const _white = Color(0xffffffff);
  static const _grey = Colors.grey;
}

class ColorsP {}

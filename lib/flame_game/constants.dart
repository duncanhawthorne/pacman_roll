import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../audio/audio_controller.dart';
import 'maze_layout.dart';
import 'package:flame/components.dart';

const bool addRandomWalls = false;
bool mazeOn = true;
const dzoom = 20.0;
//bool surf = true; //false;
const bool realsurf = false;
const defaultColor = Colors.cyan;
final defaultPaint = Paint()
  ..color = defaultColor
  ..style = PaintingStyle.stroke;
AudioController? globalAudioController;

double ksizex = 100;
double ksizey = 100;
Vector2 globalGravity = Vector2(0, 0);

bool android = defaultTargetPlatform == TargetPlatform.android;

//https://github.com/samio5/pacman/blob/master/src/app.js

// 0 - pac-dots
// 1 - wall
// 2 - ghost-lair
// 3 - power-pellet
// 4 - empty
const mazeLayout = realLayout;

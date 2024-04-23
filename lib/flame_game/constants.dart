import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../audio/audio_controller.dart';
import 'maze_layout.dart';
import 'package:flame/components.dart';

const debugMode = false;
const bool addRandomWalls = false;
bool mazeOn = true;
const dzoom = 20.0;
//bool surf = true; //false;
//const bool realsurf = false;
const defaultColor = Colors.cyan;
final defaultPaint = Paint()
  ..color = defaultColor
  ..style = PaintingStyle.stroke;
AudioController? globalAudioController;

double ksizex = 100;
double ksizey = 100;
Vector2 globalGravity = Vector2(0, 0);
const mazelen = 21;
final Vector2 kGhostStartLocation = Vector2(0, -12); //FIXME hardcoded
final Vector2 kPacmanStartLocation = Vector2(0, 20); //FIXME harcoded
final Vector2 kCageLocation = Vector2(0, -6); //FIXME hardcoded
final Vector2 kLeftPortalLocation = Vector2(-36, -4); //FIXME hardcoded
final Vector2 kRightPortalLocation = Vector2(36, -4); //FIXME harcoded
const int ghostResetTime = 1;
const int ghostChaseTime = 10;
const int pacmanDeadResetTime = 1;
const int pacmanEatingResetTime = 130;
bool globalPhysicsLinked = true;
bool gravityTurnedOn = false;
bool startGameMusic = false; //FIXME need to detect is settings have turned sound off, else slow down game when no sound playing

bool android = defaultTargetPlatform == TargetPlatform.android;

//https://github.com/samio5/pacman/blob/master/src/app.js

// 0 - pac-dots
// 1 - wall
// 2 - ghost-lair
// 3 - power-pellet
// 4 - empty
const mazeLayout = realLayout;

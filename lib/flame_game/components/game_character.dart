import 'dart:core';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'pacman.dart';
import 'physics_ball.dart';

final Paint highQualityPaint = Paint()
  ..filterQuality = FilterQuality.high
//..color = const Color.fromARGB(255, 255, 255, 255)
  ..isAntiAlias = true;

/// The [GameCharacter] is the generic object that is linked to a [PhysicsBall]
class GameCharacter extends SpriteAnimationGroupComponent<CharacterState>
    with
        //CollisionCallbacks,
        IgnoreEvents,
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame> {
  GameCharacter({
    super.position,
    super.priority = 1,
  }) : super(
            size: Vector2.all(maze.spriteWidth()),
            paint: highQualityPaint,
            anchor: Anchor.center);

  late final PhysicsBall _ball = PhysicsBall(position: position);

  bool connectedToBall = true;

  double get speed => _ball.speed;

  int get _spinParity =>
      _ball.body.linearVelocity.x.abs() > _ball.body.linearVelocity.y.abs()
          ? (world.gravity.y > 0 ? 1 : -1) *
              (_ball.body.linearVelocity.x > 0 ? 1 : -1)
          : (world.gravity.x > 0 ? -1 : 1) *
              (_ball.body.linearVelocity.y > 0 ? 1 : -1);

  void setPositionStill(Vector2 targetLoc) {
    _ball.position = targetLoc;
    _ball.velocity = Vector2(0, 0);
    position.setFrom(targetLoc);
    _connectToBall();
  }

  void disconnectFromBall({spawning = false}) {
    if (!spawning) {
      /// if body not yet initialised, this will crash
      _ball.setStatic();
    }
    connectedToBall = false;
  }

  void _connectToBall() {
    connectedToBall = true;
    _ball.setDynamic();
  }

  void _oneFrameOfPhysics(double dt) {
    if (connectedToBall) {
      position.setFrom(_ball.position);
      angle += speed * dt / (size.x / 2) * _spinParity;
    }
  }

  @override
  Future<void> onLoad() async {
    parent!.add(_ball); //should be added to static parent but risks going stray
    add(CircleHitbox(
      isSolid: true,
      collisionType:
          this is Pacman ? CollisionType.active : CollisionType.passive,
    )); //hitbox as large as possible
  }

  @override
  Future<void> onRemove() async {
    disconnectFromBall();
    _ball.removeFromParent();
    super.onRemove();
  }

  @override
  void update(double dt) {
    _oneFrameOfPhysics(dt);
    super.update(dt);
  }
}

enum CharacterState { normal, scared, scaredIsh, eating, dead, birthing }

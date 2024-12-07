import 'pellet.dart';

class SuperPellet extends Pellet {
  SuperPellet(
      {required super.position, required super.pelletsRemainingNotifier})
      : super(hitBoxRadiusFactor: 0.5);
}

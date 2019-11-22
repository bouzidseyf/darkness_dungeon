
import 'dart:math';

import 'package:darkness_dungeon/core/Enemy.dart';
import 'package:darkness_dungeon/core/Player.dart';
import 'package:flutter/material.dart';
import 'package:flame/animation.dart' as FlameAnimation;

class GoblinEnemy extends Enemy{

  static const double SIZE = 20;
  static const double DAMAGE = 15;

  GoblinEnemy():super(
      FlameAnimation.Animation.sequenced("goblin_idle.png", 6, textureWidth: 16, textureHeight: 16),
      animationDie: FlameAnimation.Animation.sequenced("enemy_explosin.png", 5, textureWidth: 16, textureHeight: 16),
      size:SIZE,
      life: 50,
      intervalAtack: 1000,
      speed: 1.4,
      visionCells: 5
  );

  @override
  void updateEnemy(double t, Player player, double mapPaddingLeft, double mapPaddingTop, List<Rect> collisionsMap) {

    moveToHero(player, (){
      double damageMin = DAMAGE /2;
      int p = Random().nextInt(DAMAGE.toInt() + (damageMin.toInt()));
      double damage = damageMin + p;
      player.recieveAtack(damage);
    });

    super.updateEnemy(t, player,mapPaddingLeft,mapPaddingTop,collisionsMap);
  }

}

import 'dart:async';

import 'package:darkness_dungeon/core/Direction.dart';
import 'package:darkness_dungeon/core/ObjectCollision.dart';
import 'package:darkness_dungeon/core/Player.dart';
import 'package:darkness_dungeon/core/AnimationGameObject.dart';
import 'package:flutter/material.dart';
import 'package:flame/animation.dart' as FlameAnimation;

abstract class Enemy extends AnimationGameObject with ObjectCollision{

  double life;
  double _maxlife;
  final double speed;
  //millesegundos
  final int intervalAtack;
  final double visionCells;
  final double size;
  final FlameAnimation.Animation animationDie;
  final FlameAnimation.Animation animationIdle;
  final FlameAnimation.Animation animationMoveLeft;
  final FlameAnimation.Animation animationMoveRight;
  final FlameAnimation.Animation animationMoveTop;
  final FlameAnimation.Animation animationMoveBottom;

  Rect _currentPosition;
  bool _isSetPosition = false;
  bool _closePlayer = false;
  bool _isIdle = true;
  Timer _timer;
  Rect _moveTo;

  Enemy(
      this.animationIdle,
      {
        this.size = 16,
        this.life = 1,
        this.speed = 1,
        this.intervalAtack = 500,
        this.visionCells = 4,
        this.animationMoveLeft,
        this.animationMoveRight,
        this.animationMoveTop,
        this.animationMoveBottom,
        this.animationDie,
      }
      ){
    _maxlife = life;
    animation = animationIdle;
    this.position = Rect.fromLTWH(0, 0, size, size);
    this._currentPosition = this.position;
    rectCollision = _getRectCollision();
  }

  setInitPosition(Rect position){
    if(!_isSetPosition){
      _isSetPosition = true;
      this.position = Rect.fromLTWH(position.left, position.top, this.position.width, this.position.height);
    }
  }

  void updateEnemy(double t, Player player, double mapPaddingLeft, double mapPaddingTop, List<Rect> collisionsMap){
    this.collisionsMap = collisionsMap;
    _currentPosition = Rect.fromLTWH(
        position.left + mapPaddingLeft,
        position.top + mapPaddingTop,
        position.width,
        position.height
    );
    rectCollision = _getRectCollision();
    super.update(t);
  }

  @override
  void render(Canvas canvas) {
    _drawLife(canvas);
    super.renderRect(canvas, _currentPosition);
  }

  void moveToHero(Player player, Function() attack){

    if(isDie()){
      return;
    }

    if(player != null){

      // CRIA COMPO DE VISÃO DO INIMIGO
      double visionWidth = _currentPosition.width * visionCells*2;
      double visionHeight = _currentPosition.height * visionCells*2;
      Rect fieldOfVision = Rect.fromLTWH(_currentPosition.left - (visionWidth/2), _currentPosition.top - (visionHeight/2), visionWidth, visionHeight);

      //CALCULA CENTRO DO PLAYER
      double leftPlayer = player.position.center.dx;
      double topPlayer = player.position.center.dy;

      if(fieldOfVision.overlaps(player.position)){

        double translateX = _currentPosition.left > leftPlayer ? (-1 * speed):speed;
        double translateY = _currentPosition.top > topPlayer? (-1 * speed):speed;

        if(_currentPosition.left == leftPlayer
            || (translateX == -1 &&  _currentPosition.left - leftPlayer < 3)
            || (translateX == 1 && leftPlayer - _currentPosition.left < 3)){
          translateX = 0;
        }
        if(_currentPosition.top == topPlayer
            || (translateY == -1 &&  _currentPosition.top - topPlayer < 3)
            || (translateY == 1 && topPlayer - _currentPosition.top < 3)){
          translateY = 0;
        }

        if(translateX > 0){
          animToRight();
        }else if(translateX < 0){
          animToLeft();
        }else if(translateY > 0){
          animToBottom();
        }else if(translateY < 0){
          animToTop();
        }else{
          if(!_isIdle) {
            animation = animationIdle;
          }
        }

        _moveTo = position.translate(translateX, translateY);

        var collisionAll = _occurredCollision(player.position, translateX, translateY);
        var collisionX = _occurredCollision(player.position, translateX, 0);
        var collisionY = _occurredCollision(player.position, 0, translateY);

        if(collisionAll && collisionX && collisionY){
          animation = animationIdle;
          return;
        }

        if(collisionAll && !collisionX){
          _moveTo = position.translate(translateX, 0);
        }

        if(collisionAll && !collisionY){
          _moveTo = position.translate(0, translateY);
        }

        if(_arrivedNext(player.position)){
          if(!_closePlayer){
            attack();
          }
          _closePlayer = true;
          _verifyAtack(attack);
          return;
        }else{
          if(_closePlayer){
            notSee();
          }
        }

        position = _moveTo;

      }else{

        if(_closePlayer){
          notSee();
        }

      }

    }

  }

  bool _arrivedNext(Rect player) {
    return _currentPosition.overlaps(player);
  }

  bool _occurredCollision(Rect player, double translateX,double translateY){
    var moveToCurrent = _currentPosition.translate(translateX, translateY);
    return verifyCollisionRect(moveToCurrent);
  }

  void _verifyAtack(Function() attack) {
    if(_timer != null && _timer.isActive){
      return;
    }
    _timer = Timer.periodic(new Duration(milliseconds: intervalAtack), (timer) {
      if(isDie()){
        return;
      }
      if(_closePlayer){
        attack();
      }
    });
  }

  void notSee() {
    _closePlayer = false;
    animation = animationIdle;
  }

  void animToRight() {
    if(animationMoveRight != null){
      _isIdle = false;
      animation = animationMoveRight;
    }
  }

  void animToLeft() {
    if(animationMoveLeft != null){
      _isIdle = false;
      animation = animationMoveLeft;
    }
  }

  void animToTop() {
    if(animationMoveTop != null){
      _isIdle = false;
      animation = animationMoveTop;
    }
  }
  void animToBottom() {
    if(animationMoveBottom != null){
      _isIdle = false;
      animation = animationMoveBottom;
    }
  }

  void receiveDamage(double damage,Direction direction){
    if(isDie()){
      return;
    }
    life = life - damage;
    if(life < 0){
      life = 0;
    }

    switch(direction){
      case Direction.left:
        position = Rect.fromLTWH(position.left - size, position.top, position.width, position.height);
        break;
      case Direction.right:
        position = Rect.fromLTWH(position.left + size, position.top, position.width, position.height);
        break;
      case Direction.top:
        position = Rect.fromLTWH(position.left, position.top - size, position.width, position.height);
        break;
      case Direction.bottom:
        position = Rect.fromLTWH(position.left, position.top + size, position.width, position.height);
        break;
    }

    if(life == 0){
      _dieAnimation();
    }
  }

  bool isDie(){
    return life ==0;
  }

  void _dieAnimation() {
    if(animationDie != null){
      animationDie.loop = false;
      animation = animationDie;
    }
  }

  void _drawLife(Canvas canvas) {
    double currentBarLife = (life*size)/_maxlife;
    canvas.drawLine(Offset(_currentPosition.left, _currentPosition.top - 4),
        Offset(_currentPosition.left + currentBarLife, _currentPosition.top - 4),
        Paint()..color = _getColorLife(currentBarLife)
          ..strokeWidth = 2
          ..style = PaintingStyle.fill);
  }

  Color _getColorLife(double currentBarLife) {
    if(currentBarLife > size - (size/3)){
      return Colors.green;
    }
    if(currentBarLife > (size/3)){
      return Colors.yellow;
    }else{
      return Colors.red;
    }
  }

  void destroy(){
    if(_timer != null && _timer.isActive)
      _timer.cancel();
  }

  Rect _getRectCollision() {
    return Rect.fromLTWH(
        _currentPosition.left,
        _currentPosition.top + (_currentPosition.height / 2),
        _currentPosition.width / 1.5,
        _currentPosition.height / 3
    );
  }

}
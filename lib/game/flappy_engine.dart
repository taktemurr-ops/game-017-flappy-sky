import 'dart:math';

class FlappyEngine {
  static const double gravity = 1.05;
  static const double flapVelocity = -7.2;
  static const double pipeSpeed = 2.1;
  static const double gapHeight = 150;
  static const double birdX = 90;
  static const double birdRadius = 13;
  final double width;
  final double height;
  double birdY;
  double velocity = 0;
  double pipeX;
  double gapCenter;
  int score = 0;
  int ticks = 0;
  bool started = false;
  bool gameOver = false;
  bool _scored = false;
  FlappyEngine({this.width = 360, this.height = 600})
      : birdY = 300, pipeX = 390, gapCenter = 300 {
    birdY = height / 2;
    pipeX = width + 30;
    gapCenter = height / 2;
  }
  void flap() {
    if (gameOver) return;
    started = true;
    velocity = flapVelocity;
  }
  void restart() {
    birdY = height / 2;
    velocity = 0;
    pipeX = width + 30;
    gapCenter = height / 2;
    score = 0;
    ticks = 0;
    started = false;
    gameOver = false;
    _scored = false;
  }
  void tick() {
    if (!started || gameOver) return;
    ticks++;
    velocity = min(velocity + gravity, 9.0);
    birdY += velocity;
    pipeX -= pipeSpeed;
    if (birdY - birdRadius <= 0 || birdY + birdRadius >= height) {
      gameOver = true;
      return;
    }
    const pipeWidth = 55.0;
    if (pipeX < birdX + birdRadius && pipeX + pipeWidth > birdX - birdRadius &&
        (birdY - birdRadius < gapCenter - gapHeight / 2 ||
         birdY + birdRadius > gapCenter + gapHeight / 2)) {
      gameOver = true;
      return;
    }
    if (!_scored && pipeX + pipeWidth < birdX - birdRadius) {
      score++;
      _scored = true;
    }
    if (pipeX + pipeWidth < 0) {
      pipeX = width + 20;
      gapCenter = 130 + (ticks * 37 % max(1, (height - 260).floor()));
      _scored = false;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:game_017_flappy_sky/game/flappy_engine.dart';

void main() {
  test('starts paused with zero score', () {
    final game = FlappyEngine();
    game.tick();
    expect(game.started, false);
    expect(game.score, 0);
    expect(game.birdY, 300);
  });
  test('flap starts game and gives upward velocity', () {
    final game = FlappyEngine();
    game.flap();
    game.tick();
    expect(game.started, true);
    expect(game.birdY, lessThan(300));
  });
  test('ceiling collision ends game and disables flap', () {
    final game = FlappyEngine();
    game.flap();
    for (var i = 0; i < 200 && !game.gameOver; i++) {
      game.flap();
      game.tick();
    }
    expect(game.gameOver, true);
    final y = game.birdY;
    game.flap();
    game.tick();
    expect(game.birdY, y);
  });
  test('restart resets all progress', () {
    final game = FlappyEngine();
    game.flap();
    game.tick();
    game.restart();
    expect(game.started, false);
    expect(game.gameOver, false);
    expect(game.score, 0);
    expect(game.birdY, 300);
  });
}

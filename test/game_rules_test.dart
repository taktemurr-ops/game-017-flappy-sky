import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:game_017_flappy_sky/game/flappy_engine.dart';
import 'package:game_017_flappy_sky/game/rules.dart';

void main() {
  final rules = FlappyRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('bird waits for the first tap, then gravity applies', () {
    final s = FlappySim(rules.build(planner.spec(1)).puzzle);
    for (var i = 0; i < 30; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.started, isFalse);
    s.tick(const ArcadeInput(tap: true));
    final y0 = s.y;
    for (var i = 0; i < 60; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.y, greaterThan(y0));
  });

  test('falling to the ground costs a life', () {
    final s = FlappySim(rules.build(planner.spec(1)).puzzle);
    s.tick(const ArcadeInput(tap: true));
    for (var i = 0; i < 200 && s.lives == 3; i++) {
      s.tick(ArcadeInput.idle);
    }
    expect(s.lives, 2);
  });

  test('consecutive gaps stay reachable', () {
    final l = rules.build(planner.spec(300)).puzzle;
    final s = FlappySim(l);
    for (var i = 1; i < s.pipes.length; i++) {
      expect((s.pipes[i].gapY - s.pipes[i - 1].gapY).abs(), lessThanOrEqualTo(l.maxDelta + 0.001));
    }
  });
}

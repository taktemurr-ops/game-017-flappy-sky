import 'dart:math' as math;

import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/level_plan.dart';

class FlappyLevel {
  final ArcadeMeta meta;
  final int target; // pipes to pass, 0 = endless
  final double gap;
  final double spacing;
  final double speed;
  final double maxDelta;
  final bool moving;
  final bool coins;
  final bool wind;
  final bool narrow;

  const FlappyLevel({
    required this.meta,
    required this.target,
    required this.gap,
    required this.spacing,
    required this.speed,
    required this.maxDelta,
    required this.moving,
    required this.coins,
    required this.wind,
    required this.narrow,
  });
}

FlappyLevel generateFlappyLevel(LevelSpec spec) {
  final m = ArcadeMeta.of(spec);
  final d = spec.difficulty;
  return FlappyLevel(
    meta: m,
    target: m.goal ? 10 + d * 4 : 0,
    gap: (440 - d * 16).clamp(300, 440).toDouble(),
    spacing: (560 - d * 12).clamp(440, 560).toDouble(),
    speed: 5.0 + d * 0.3,
    maxDelta: 230 + d * 12.0,
    moving: spec.has('moving'),
    coins: spec.has('coins') || !m.goal,
    wind: spec.has('wind'),
    narrow: spec.has('narrow'),
  );
}

const double kBirdX = 300;
const double kBirdR = 30;
const double kPipeW = 140;
const double kGround = 1450;
const double kCeil = 110;

class Pipe {
  double x;
  final double gapY;
  final double gap;
  final double amp; // vertical oscillation
  final int phase;
  bool passed = false;
  bool coin;
  Pipe(this.x, this.gapY, this.gap, this.amp, this.phase, this.coin);
}

class FlappySim extends ArcadeSim {
  final FlappyLevel level;
  double y = 700, vy = 0;
  bool started = false;
  final List<Pipe> pipes = [];
  double lastGap = 760;
  int passed = 0, flaps = 0, starsGot = 0;
  double windForce = 0;
  int lastEvent = 0; // 1 flap, 2 pass, 3 coin

  FlappySim(this.level) : super(level.meta) {
    var x = 1250.0;
    while (pipes.length < 4) {
      _spawn(x);
      x += level.spacing;
    }
  }

  void _spawn(double x) {
    final lo = math.max(kCeil + 240, lastGap - level.maxDelta);
    final hi = math.min(kGround - 240, lastGap + level.maxDelta);
    final gy = lo + rng.nextDouble() * (hi - lo);
    lastGap = gy;
    var gap = level.gap;
    if (level.narrow && rng.chance(0.25)) gap -= 50;
    final amp = level.moving && rng.chance(0.4) ? 70.0 : 0.0;
    pipes.add(Pipe(x, gy, gap, amp, rng.nextInt(180), level.coins && rng.chance(0.5)));
  }

  double gapCenter(Pipe p, [int? at]) =>
      p.gapY + (p.amp == 0 ? 0 : p.amp * math.sin(((at ?? ticks) + p.phase) / 180 * 2 * math.pi));

  void flap() {
    vy = -9.6;
    flaps++;
    lastEvent = 1;
  }

  @override
  void update(ArcadeInput input) {
    lastEvent = 0;
    final pressed = input.tap || input.swipe == 0;
    if (!started) {
      y = 700 + 12 * math.sin(ticks / 12);
      if (pressed) {
        started = true;
        flap();
      }
      return;
    }
    if (pressed) flap();
    if (level.wind) {
      // Gusts: 2 s up/down pushes.
      final phase = (ticks ~/ 120) % 4;
      windForce = phase == 1 ? -0.12 : (phase == 3 ? 0.12 : 0);
    }
    vy = math.min(vy + 0.5 + windForce, 13);
    y += vy;
    if (y < kCeil + kBirdR) {
      y = kCeil + kBirdR;
      vy = 0;
    }
    for (final p in pipes) {
      p.x -= level.speed;
      if (!p.passed && p.x + kPipeW < kBirdX - kBirdR) {
        p.passed = true;
        passed++;
        score += 10;
        lastEvent = 2;
        if (level.target > 0 && passed >= level.target) win();
      }
      final gc = gapCenter(p);
      if (p.coin && (p.x + kPipeW / 2 - kBirdX).abs() < 45 && (gc - y).abs() < 60) {
        p.coin = false;
        starsGot++;
        score += 25;
        lastEvent = 3;
      }
      // collision
      if (kBirdX + kBirdR * 0.8 > p.x && kBirdX - kBirdR * 0.8 < p.x + kPipeW) {
        if (y - kBirdR * 0.8 < gc - p.gap / 2 || y + kBirdR * 0.8 > gc + p.gap / 2) {
          hit();
          if (over) return;
        }
      }
    }
    if (y + kBirdR > kGround) {
      if (meta.zen) {
        y = kGround - kBirdR;
        vy = -9.6;
      } else {
        hit();
      }
    }
    pipes.removeWhere((p) => p.x + kPipeW < -50);
    while (pipes.length < 4) {
      _spawn(pipes.last.x + level.spacing);
    }
  }

  Pipe? get nextPipe {
    for (final p in pipes) {
      if (p.x + kPipeW > kBirdX - kBirdR) return p;
    }
    return null;
  }

  @override
  void onLifeLost() {
    final p = nextPipe;
    y = p == null ? 700 : gapCenter(p);
    vy = -4;
    // Give room: push the next pipe away if it is too close.
    if (p != null && p.x < kBirdX + kBirdR + 10 && p.x + kPipeW > kBirdX - kBirdR) {
      // Inside a pipe: centered in its gap, shield makes it safe.
    }
  }

  @override
  double get progress => level.target == 0 ? 0 : passed / level.target;

  @override
  String get goalText => level.target == 0 ? '$passed' : '$passed/${level.target}';

  @override
  Map<String, int> get stats => {'pipes_passed': passed, 'flaps': flaps, 'stars_collected': starsGot};

  @override
  int get stars => lifeStars(this, 3);
}

ArcadeInput flappyBot(ArcadeSim sim) {
  final s = sim as FlappySim;
  if (!s.started) return const ArcadeInput(tap: true, down: true, x: 500, y: 800);
  final p = s.nextPipe;
  // Aim slightly below the gap center (a flap lifts ~90 units).
  var target = p == null ? 760.0 : s.gapCenter(p, s.ticks + 20) + 40;
  if (p != null) {
    // When approaching a lower/higher next gap, blend toward it.
    final after = s.pipes.indexOf(p) + 1 < s.pipes.length ? s.pipes[s.pipes.indexOf(p) + 1] : null;
    if (after != null && p.x + kPipeW < kBirdX + 10) target = s.gapCenter(after, s.ticks + 20) + 40;
  }
  final flap = s.y > target && s.vy > -1.5;
  return flap ? const ArcadeInput(tap: true, down: true, x: 500, y: 800) : ArcadeInput.idle;
}

import 'package:flutter/material.dart';

import 'package:studio_core/app/arcade_stage.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/game_rules.dart';
import 'flappy_engine.dart';
import 'rules.dart';

void paintFlappy(Canvas c, ArcadeSim sim, ArcadePalette p, double t) {
  final s = sim as FlappySim;
  // clouds (parallax)
  final cloud = Paint()..color = Colors.white24;
  for (var i = 0; i < 5; i++) {
    final x = (i * 260 - s.ticks * 1.2) % 1300 - 150;
    c.drawOval(Rect.fromLTWH(x, 220.0 + i * 170, 220, 70), cloud);
  }
  final pipeCol = p.piece(3);
  final dark = Color.lerp(pipeCol, Colors.black, 0.3)!;
  for (final pp in s.pipes) {
    final gc = s.gapCenter(pp);
    final topRect = Rect.fromLTRB(pp.x, kCeil, pp.x + kPipeW, gc - pp.gap / 2);
    final botRect = Rect.fromLTRB(pp.x, gc + pp.gap / 2, pp.x + kPipeW, kGround);
    for (final r in [topRect, botRect]) {
      c.drawRect(r, Paint()..color = pipeCol);
      c.drawRect(Rect.fromLTWH(r.left + 14, r.top, 18, r.height), Paint()..color = Colors.white24);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(pp.x - 12, topRect.bottom - 40, pp.x + kPipeW + 12, topRect.bottom), const Radius.circular(8)), Paint()..color = dark);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(pp.x - 12, botRect.top, pp.x + kPipeW + 12, botRect.top + 40), const Radius.circular(8)), Paint()..color = dark);
    if (pp.coin) paintText(c, '★', Offset(pp.x + kPipeW / 2, gc), 56, const Color(0xFFFFD60A));
  }
  c.drawRect(const Rect.fromLTRB(0, kGround, kWorldW, kWorldH), Paint()..color = const Color(0xFF6A994E));
  final stripe = Paint()..color = const Color(0xFF386641);
  for (var x = -(s.ticks * 5.0 % 60); x < kWorldW; x += 60) {
    c.drawRect(Rect.fromLTWH(x, kGround, 30, 18), stripe);
  }
  c.drawRect(const Rect.fromLTWH(0, 0, kWorldW, kCeil), Paint()..color = Colors.black26);
  // bird
  final tilt = (s.vy / 20).clamp(-0.6, 1.2);
  c.save();
  c.translate(kBirdX, s.y);
  c.rotate(tilt);
  final blink = s.shield > 0 && (s.ticks ~/ 5).isOdd;
  c.drawOval(Rect.fromCenter(center: Offset.zero, width: kBirdR * 2.4, height: kBirdR * 2), Paint()..color = blink ? Colors.white38 : p.piece(0));
  final flapUp = (s.ticks ~/ 5).isEven;
  c.drawOval(Rect.fromCenter(center: Offset(-10, flapUp ? -6 : 8), width: 34, height: 20), Paint()..color = Colors.white70);
  c.drawCircle(const Offset(16, -10), 9, Paint()..color = Colors.white);
  c.drawCircle(const Offset(19, -10), 4.5, Paint()..color = Colors.black);
  final beak = Path()
    ..moveTo(28, -2)
    ..lineTo(48, 4)
    ..lineTo(28, 10)
    ..close();
  c.drawPath(beak, Paint()..color = const Color(0xFFFF9F1C));
  c.restore();
  if (s.level.wind && s.windForce != 0) {
    paintText(c, s.windForce < 0 ? '↑ ~' : '↓ ~', const Offset(kWorldW - 120, 170), 40, Colors.white70);
  }
}

Sfx? flappySound(ArcadeSim sim) => switch ((sim as FlappySim).lastEvent) {
      1 => Sfx.tap,
      2 => Sfx.place,
      3 => Sfx.coin,
      _ => null,
    };

final gameConfig = GameConfig(
  gameId: 'game-017-flappy-sky',
  title: const ['Kanatlı Gökyüzü', 'Flappy Sky', 'Flatter-Himmel', 'Cielo Aleteo', 'Ciel Battant'],
  tagline: const ['Dokun, aradan uç!', 'Tap to fly through the gaps!', 'Tippen und durch die Lücken fliegen!', '¡Toca y vuela entre los huecos!', 'Touchez pour passer entre les tuyaux !'],
  seedColor: const Color(0xFFFFDD57),
  icon: Icons.flutter_dash,
  rules: FlappyRules(),
  buildPlay: (ctx) => ArcadeStage(
    ctx: ctx,
    create: () => FlappySim((ctx.generated as GeneratedLevel<FlappyLevel>).puzzle),
    paint: paintFlappy,
    sound: flappySound,
    howTo: const [
      'Her dokunuş bir kanat çırpışı. Boruların arasından geç!',
      'Each tap is a flap. Fly through the gaps!',
      'Jedes Tippen ein Flügelschlag.',
      'Cada toque es un aleteo.',
      'Chaque toucher est un battement d\'aile.',
    ],
  ),
  tutorial: const [
    TutorialStep(Icons.touch_app, [
      'Ekrana dokun (ya da boşluk) ve kanat çırp. Yere düşme.',
      'Tap (or space) to flap. Do not hit the ground.',
      'Tippen (oder Leertaste) zum Flattern.',
      'Toca (o espacio) para aletear.',
      'Touchez (ou espace) pour battre des ailes.',
    ]),
    TutorialStep(Icons.star, [
      'Yıldızları topla, hareketli borulara ve rüzgâra dikkat et.',
      'Collect stars, watch out for moving pipes and wind.',
      'Sammle Sterne, achte auf Wind.',
      'Recoge estrellas, cuidado con el viento.',
      'Ramassez les étoiles, attention au vent.',
    ]),
  ],
);

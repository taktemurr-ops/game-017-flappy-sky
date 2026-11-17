import 'dart:async';
import 'package:flutter/material.dart';
import 'game/flappy_engine.dart';

void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: FlappyScreen()));

class FlappyScreen extends StatefulWidget {
  const FlappyScreen({super.key});
  @override
  State<FlappyScreen> createState() => _FlappyScreenState();
}

class _FlappyScreenState extends State<FlappyScreen> {
  final game = FlappyEngine();
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted && game.started && !game.gameOver) setState(game.tick);
    });
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  void tap() => setState(() { if (game.gameOver) game.restart(); else game.flap(); });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Flappy Sky'), actions: [
      IconButton(onPressed: () => setState(game.restart), tooltip: 'Restart',
        icon: const Icon(Icons.refresh))
    ]),
    body: Center(child: AspectRatio(aspectRatio: 0.6,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: tap,
        child: CustomPaint(painter: _SkyPainter(game),
          child: Stack(children: [
            Align(alignment: Alignment.topCenter,
              child: Padding(padding: const EdgeInsets.all(24),
                child: Text('Score: ${game.score}', style: const TextStyle(fontSize: 28, color: Colors.white)))),
            Align(alignment: Alignment.center,
              child: Text(game.gameOver ? 'Game over — tap to restart'
                : !game.started ? 'Tap to flap' : '',
                style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))),
          ]))))),
  );
}

class _SkyPainter extends CustomPainter {
  final FlappyEngine game;
  _SkyPainter(this.game);
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / game.width, sy = size.height / game.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.lightBlue.shade400);
    canvas.save();
    canvas.scale(sx, sy);
    final pipe = Paint()..color = Colors.green.shade700;
    const gap = FlappyEngine.gapHeight;
    canvas.drawRect(Rect.fromLTWH(game.pipeX, 0, 55, game.gapCenter - gap / 2), pipe);
    canvas.drawRect(Rect.fromLTWH(game.pipeX, game.gapCenter + gap / 2, 55,
      game.height - game.gapCenter - gap / 2), pipe);
    canvas.drawCircle(Offset(FlappyEngine.birdX, game.birdY),
      FlappyEngine.birdRadius, Paint()..color = Colors.yellow);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => true;
}

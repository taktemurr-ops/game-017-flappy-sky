import '../core/arcade.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'flappy_engine.dart';

class FlappyRules extends ArcadeRules<FlappyLevel> {
  @override
  String get gameId => 'game-017-flappy-sky';

  @override
  List<String> get optionalMechanics => const ['moving', 'coins', 'wind', 'narrow'];

  @override
  List<GameStat> get gameStats => const [
        GameStat('pipes_passed', 'Geçilen boru', 'Pipes passed', scale: 100),
        GameStat('flaps', 'Kanat çırpma', 'Flaps', scale: 300),
        GameStat('stars_collected', 'Yıldız', 'Stars', scale: 20),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('pipes_passed', 'pipes_passed', [33, 66, 100]),
        MissionTemplate('flaps', 'flaps', [100, 200, 300]),
      ];

  @override
  FlappyLevel generate(LevelSpec spec) => generateFlappyLevel(spec);

  @override
  ArcadeMeta metaOf(FlappyLevel l) => l.meta;

  @override
  ArcadeSim createSim(FlappyLevel l) => FlappySim(l);

  @override
  ArcadeInput bot(ArcadeSim sim) => flappyBot(sim);
}

ArcadeRules createRules() => FlappyRules();

import 'package:endlessrunner/game/dino.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../respository/game_setting_respository.dart';
import '../respository/player_respository.dart';
import '../widgets/game_over_menu.dart';
import '../widgets/hud.dart';
import '../widgets/main_menu.dart';
import '../widgets/pause_menu.dart';
import '/models/game_settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {
  int tempHighScore = 0;

  DinoRun({super.camera});

  static const _imageAssets = [
    'dino.png',
    'spikes.png',
    'fly.png',
    'run.png',
    'DinoSprites - tard.png',
    'AngryPig/Walk (36x30).png',
    'Bat/Flying (46x30).png',
    'Rino/Run (52x34).png',
  ];

  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  late GameSettings gameSettings;
  late PlayerModel playerModel;
  late EnemyManager _enemyManager;

  final PlayerRepository playerRepository = PlayerRepository();
  final GameSettingsRepository settingsRepository = GameSettingsRepository();

  Vector2 get virtualSize => camera.viewport.virtualSize;

  get highscore => null;

  @override
  Future<void> onLoad() async {
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    playerModel = await _readPlayerData();
    gameSettings = await _readSettings();

    await AudioManager.instance.init(_audioAssets, gameSettings);
    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    await images.loadAll(_imageAssets);
    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;

    final whiteBackground = RectangleComponent(
      size: camera.viewport.size,
      paint: Paint()
        ..color = Colors.white,
    );
    camera.backdrop.add(whiteBackground);

    overlays.add(MainMenu.id);
  }

  Future<PlayerModel> _readPlayerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    String uid = user.uid;
    PlayerModel? player = await playerRepository.getPlayer(uid);

    if (player == null) {
      player = PlayerModel(uid: uid, highscore: highscore);
      await playerRepository.createPlayer(player);
    }

    return player;
  }

  Future<GameSettings> _readSettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    String uid = user.uid;
    GameSettings? settings = await settingsRepository.getSettings(uid);

    if (settings == null) {
      settings = GameSettings(uid: uid);
      await settingsRepository.createSettings(settings);
    }

    return settings;
  }

  void startGamePlay() {
    _dino = Dino(images.fromCache('DinoSprites - tard.png'), playerModel);
    _enemyManager = EnemyManager();

    world.add(_dino);
    world.add(_enemyManager);
    overlays.remove(MainMenu.id);
    overlays.add(Hud.id);
  }

  void _disconnectActors() {
    _dino.removeFromParent();
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
  }

  void reset() {
    _disconnectActors();
    playerModel.currentScore = 0;
    playerModel.lives = 5;
    playerModel.resetPlayerData();
  }

  @override
  void update(double dt) {
    if (playerModel.lives <= 0) {
      tempHighScore = playerModel.currentScore;

      if (!overlays.isActive(GameOverMenu.id)) {
        pauseEngine();
        AudioManager.instance.pauseBgm();
        overlays.add(GameOverMenu.id);

        reset();
      }
    }
    super.update(dt);
  }


  @override
  void onTapDown(TapDownInfo info) {
    if (overlays.isActive(Hud.id)) {
      _dino.jump();
    }
    super.onTapDown(info);
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!(overlays.isActive(PauseMenu.id)) &&
            !(overlays.isActive(GameOverMenu.id))) {
          resumeEngine();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (overlays.isActive(Hud.id)) {
          overlays.remove(Hud.id);
          overlays.add(PauseMenu.id);
        }
        pauseEngine();
        break;
    }
    super.lifecycleStateChange(state);
  }

}

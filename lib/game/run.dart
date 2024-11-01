


import 'package:endlessrunner/game/runner.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:hive/hive.dart';

import 'package:flutter/material.dart';


import '/widgets/hud.dart';
import '/models/settings.dart';
import '/game/audio_manager.dart';
import '/game/enemy_manager.dart';
import '/models/player_data.dart';
import '/widgets/pause_menu.dart';
import '/widgets/game_over_menu.dart';

// This is the main flame game class.
class DinoRun extends FlameGame with TapDetector, HasCollisionDetection {
  DinoRun({super.camera});

  static const _imageAssets = [
    'dino.png',
    'spikes.png',
    'fly.png',
    'run.png',
  ];


  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  late Settings settings;
  late PlayerData playerData;
  late EnemyManager _enemyManager;

  Vector2 get virtualSize => camera.viewport.virtualSize;

  @override
  Future<void> onLoad() async {

    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    playerData = await _readPlayerData();
    settings = await _readSettings();

    await AudioManager.instance.init(_audioAssets, settings);


    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');

    await images.loadAll(_imageAssets);

    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;



    final whiteBackground = RectangleComponent(
      size: camera.viewport.size,
      paint: Paint()..color = Colors.white,
    );
    camera.backdrop.add(whiteBackground);
  }


  void startGamePlay() {
    _dino = Dino(images.fromCache('dino.png'), playerData);
    _enemyManager = EnemyManager();

    world.add(_dino);
    world.add(_enemyManager);
  }


  void _disconnectActors() {
    _dino.removeFromParent();
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
  }


  void reset() {

    _disconnectActors();


    playerData.currentScore = 0;
    playerData.lives = 5;
  }


  @override
  void update(double dt) {

    if (playerData.lives <= 0) {
      overlays.add(GameOverMenu.id);
      overlays.remove(Hud.id);
      pauseEngine();
      AudioManager.instance.pauseBgm();
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


  Future<PlayerData> _readPlayerData() async {
    final playerDataBox =
    await Hive.openBox<PlayerData>('DinoRun.PlayerDataBox');
    final playerData = playerDataBox.get('DinoRun.PlayerData');


    if (playerData == null) {

      await playerDataBox.put('DinoRun.PlayerData', PlayerData());
    }


    return playerDataBox.get('DinoRun.PlayerData')!;
  }


  Future<Settings> _readSettings() async {
    final settingsBox = await Hive.openBox<Settings>('DinoRun.SettingsBox');
    final settings = settingsBox.get('DinoRun.Settings');


    if (settings == null) {

      await settingsBox.put(
        'DinoRun.Settings',
        Settings(bgm: true, sfx: true),
      );
    }


    return settingsBox.get('DinoRun.Settings')!;
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

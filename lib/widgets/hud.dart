import 'package:endlessrunner/models/player_model.dart';
import 'package:endlessrunner/widgets/pause_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/dino_run.dart';
import '/game/audio_manager.dart';

class Hud extends StatelessWidget {
  final DinoRun game;
  static const String id = 'Hud';

  const Hud(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<PlayerModel?>.value(
      value: PlayerModel.listenToPlayer(game.playerModel.uid),
      initialData: null,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Consumer<PlayerModel?>(
          builder: (context, playerModel, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      'Score: ${playerModel?.currentScore ?? 0}',
                      style: const TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    game.overlays.remove(Hud.id);
                    game.overlays.add(PauseMenu.id);
                    game.pauseEngine();
                    AudioManager.instance.pauseBgm();
                  },
                  child: const Icon(Icons.pause, color: Colors.black),
                ),
                Row(
                  children: List.generate(5, (index) {
                    if (playerModel != null && index < playerModel.lives) {
                      return const Icon(
                        Icons.favorite,
                        color: Colors.red,
                      );
                    } else {
                      return const Icon(
                        Icons.favorite_border,
                        color: Colors.red,
                      );
                    }
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

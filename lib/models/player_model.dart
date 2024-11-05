import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';


class PlayerModel extends ChangeNotifier {
  final String uid;
  int lives;
  int currentScore;
  int highscore;

  PlayerModel({
    required this.uid,
    this.lives = 5,
    this.currentScore = 0,
    required this.highscore,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      uid: data['uid'],
      lives: data['lives'] ?? 5,
      currentScore: data['current_score'] ?? 0,
      highscore: data['highScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'lives': lives,
      'current_score': currentScore,
      'highScore': highscore
    };
  }

  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('players').doc(uid).set(toMap());
  }

  static Future<PlayerModel?> getPlayerByUid(String uid) async {
    final playerDoc = await FirebaseFirestore.instance.collection('players').doc(uid).get();
    if (playerDoc.exists) {
      return PlayerModel.fromMap(playerDoc.data()!);
    }
    return null;
  }

  void increaseScore(int amount) {
    currentScore += amount;


    if (currentScore > highscore) {
      highscore = currentScore;
    }

    saveToFirestore();
    notifyListeners();
  }

  void decreaseLives() {
    if (lives > 0) {
      lives--;
      saveToFirestore();
      notifyListeners();
    }
  }




  static Stream<PlayerModel?> listenToPlayer(String uid) {
    return FirebaseFirestore.instance.collection('players').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return PlayerModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class PlayerModel extends ChangeNotifier {
  final String uid;
  int lives;
  int currentScore;
  int highscore;
  DateTime? highScoreDateTime;

  PlayerModel({
    required this.uid,
    this.lives = 5,
    this.currentScore = 0,
    required this.highscore,
    this.highScoreDateTime,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> data) {
    return PlayerModel(
      uid: data['uid'],
      lives: data['lives'] ?? 5,
      currentScore: data['current_score'] ?? 0,
      highscore: data['highScore'] ?? 0,
      highScoreDateTime: data['datetime'] != null
          ? (data['datetime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'lives': lives,
      'current_score': currentScore,
      'highScore': highscore,
      'datetime': highScoreDateTime != null
          ? Timestamp.fromDate(highScoreDateTime!)
          : FieldValue.serverTimestamp(),
    };
  }

  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance
        .collection('players')
        .doc(uid)
        .set(toMap());
  }

  Future<void> increaseScore(int damage) async {
    currentScore += damage;
    if (currentScore > highscore) {
      highscore = currentScore;
      highScoreDateTime = DateTime.now();


    }

    await saveToFirestore();
    notifyListeners();
  }

  Future<void> decreaseLives(int damage) async {
    lives -= damage;
    if (lives < 0) {
      lives = 0;
    }
    await saveToFirestore();
    notifyListeners();
  }

  Future<void> resetPlayerData() async {
    lives = 5;
    currentScore = 0;
    await saveToFirestore();
    notifyListeners();
  }

  static Stream<PlayerModel?> listenToPlayer(String uid) {
    return FirebaseFirestore.instance
        .collection('players')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return PlayerModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }
}

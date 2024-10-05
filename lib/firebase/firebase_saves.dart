import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../google/google.dart';
import '../utils/helper.dart';

/// This file has utilities for loading and saving the leaderboard in firebase

class FBase {
  static const bool firebaseOn =
      true && firebaseOnReal; //!(windows && !kIsWeb);

  static const String mainDB = "records";
  static const String userSaves = "userSaves";

  FirebaseFirestore? db;

  Future<void> initialize() async {
    if (firebaseOn) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      db = FirebaseFirestore.instance;
    } else {
      debug("fb off");
    }
  }

  Future<void> firebasePushSingleScore(
      String recordID, Map<String, dynamic> state) async {
    if (kDebugMode) {
      return;
    }
    if (firebaseOn) {
      //debug("firebase push");
      try {
        if (firebaseOn) {
          db!
              .collection(mainDB)
              .doc(recordID)
              .set(state)
              .onError((e, _) => debug("Error writing document: $e"));
        }
      } catch (e) {
        debug(["firebasePushSingleScore", e]);
      }
    }
  }

  Future<double> firebasePercentile(
      {required int levelNum,
      required int levelCompletedInMillis,
      required int mazeId}) async {
    if (firebaseOn) {
      try {
        if (firebaseOn) {
          final collectionRef = db!.collection(mainDB);
          AggregateQuerySnapshot fasterSnapshot = await collectionRef
              .where("levelCompleteTime", isLessThan: levelCompletedInMillis)
              .where("levelNum", isEqualTo: levelNum)
              .where("mazeId", isEqualTo: mazeId)
              .count()
              .get();
          int fasterCount = fasterSnapshot.count ?? 0;
          AggregateQuerySnapshot slowerSnapshot = await collectionRef
              .where("levelCompleteTime", isGreaterThan: levelCompletedInMillis)
              .where("levelNum", isEqualTo: levelNum)
              .where("mazeId", isEqualTo: mazeId)
              .count()
              .get();
          int slowerCount = slowerSnapshot.count ?? 100;
          int allCount = fasterCount + slowerCount + 1; //ignore equal times
          return (fasterCount + 1 - 1) / (allCount == 1 ? 100 : allCount - 1);
        }
      } catch (e) {
        debug(["firebasePercentile error", e]);
      }
    }
    return 1.0;
  }

  Future<void> firebasePushPlayerProgress(G g, String state) async {
    debug(["firebasePush", g.gUser]);
    if (firebaseOn && g.signedIn) {
      final dhState = <String, dynamic>{"data": state};
      db!
          .collection("userSaves")
          .doc(g.gUser)
          .set(dhState)
          .onError((e, _) => debug("Error writing document: $e"));
    }
  }

  Future<String> firebasePullPlayerProgress(G g) async {
    await initialize();
    String gameEncoded = "";
    debug(["firebasePull"]);
    if (firebaseOn && g.signedIn) {
      final docRef = db!.collection("userSaves").doc(g.gUser);
      await docRef.get().then(
        (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (e) => debug("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}

FBase fBase = FBase();

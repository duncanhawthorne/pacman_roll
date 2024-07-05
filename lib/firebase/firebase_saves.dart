import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../utils/helper.dart';

/// This file has utilities for loading and saving the leaderboard in firebase

class Save {
  static const bool firebaseOn =
      true && firebaseOnReal; //!(windows && !kIsWeb);

  static const String mainDB = "records";

  FirebaseFirestore? db;

  Random random = Random();

  void fbStart() async {
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
    if (firebaseOn) {
      debug("firebase push");
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

  Future<double> firebasePercentile(int vsMillis) async {
    if (firebaseOn) {
      try {
        if (firebaseOn) {
          final collectionRef = db!.collection(mainDB);
          Query fasterQuery =
              collectionRef.where("levelCompleteTime", isLessThan: vsMillis);
          AggregateQuerySnapshot fasterSnapshot =
              await fasterQuery.count().get();
          int fasterCount = fasterSnapshot.count ?? 0;
          Query allQuery = collectionRef;
          AggregateQuerySnapshot allSnapshot = await allQuery.count().get();
          int allCount = allSnapshot.count ?? 100;
          return (fasterCount + 1 - 1) / (allCount == 1 ? 100 : allCount - 1);
        }
      } catch (e) {
        debug(["firebasePercentile error", e]);
      }
    }
    return 1.0;
  }
}

Save save = Save();

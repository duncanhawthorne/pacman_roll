import 'dart:async';

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
          unawaited(db!
              .collection(mainDB)
              .doc(recordID)
              .set(state)
              .onError((Object? e, _) => debug("Error writing document: $e")));
        }
      } catch (e) {
        debug(<Object>["firebasePushSingleScore", e]);
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
          final CollectionReference<Map<String, dynamic>> collectionRef =
              db!.collection(mainDB);
          final AggregateQuerySnapshot fasterSnapshot = await collectionRef
              .where("levelCompleteTime", isLessThan: levelCompletedInMillis)
              .where("levelNum", isEqualTo: levelNum)
              .where("mazeId", isEqualTo: mazeId)
              .count()
              .get();
          final int fasterCount = fasterSnapshot.count ?? 0;
          final AggregateQuerySnapshot slowerSnapshot = await collectionRef
              .where("levelCompleteTime", isGreaterThan: levelCompletedInMillis)
              .where("levelNum", isEqualTo: levelNum)
              .where("mazeId", isEqualTo: mazeId)
              .count()
              .get();
          final int slowerCount = slowerSnapshot.count ?? 100;
          final int allCount =
              fasterCount + slowerCount + 1; //ignore equal times
          return (fasterCount + 1 - 1) / (allCount == 1 ? 100 : allCount - 1);
        }
      } catch (e) {
        debug(<Object>["firebasePercentile error", e]);
      }
    }
    return 1.0;
  }

  Future<void> firebasePushPlayerProgress(G g, String state) async {
    debug(<String>["firebasePush", g.gUser]);
    if (firebaseOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{"data": state};
      unawaited(db!
          .collection("userSaves")
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => debug("Error writing document: $e")));
    }
  }

  Future<String> firebasePullPlayerProgress(G g) async {
    await initialize();
    String gameEncoded = "";
    debug(<String>["firebasePull"]);
    if (firebaseOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef =
          db!.collection("userSaves").doc(g.gUser);
      await docRef.get().then(
        (DocumentSnapshot<dynamic> doc) {
          final Map<String, dynamic> gameEncodedTmp =
              doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (dynamic e) => debug("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }
}

FBase fBase = FBase();

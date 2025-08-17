import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_user/google_user.dart';
import 'package:logging/logging.dart';

import '../firebase_options.dart';

/// This file has utilities for loading and saving the leaderboard in firebase

class FBase {
  FBase._() {
    //unawaited(fBase.initialize());
  }

  factory FBase() {
    assert(_instance == null);
    _instance ??= FBase._();
    return _instance!;
  }

  ///ensures singleton [FBase]
  static FBase? _instance;

  static const bool firebaseOn =
      true && firebaseOnReal; //!(windows && !kIsWeb);

  static const String _mainDB = "records";
  static const String _userSaves = "userSaves";
  static const String _data = "data";

  static final Logger _log = Logger('FB');

  FirebaseFirestore? _db;

  Future<void> initialize() async {
    if (firebaseOn) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _db = FirebaseFirestore.instance;
    } else {
      _log.info("Off");
    }
  }

  Future<void> firebasePushSingleScore(
    String recordID,
    Map<String, dynamic> state,
  ) async {
    if (kDebugMode) {
      _log.info("firebasePushSingleScore not called as debug");
      return;
    }
    _log.fine("firebasePushSingleScore");
    await initialize();
    if (firebaseOn) {
      //debug("firebase push");
      try {
        if (firebaseOn) {
          await _db!
              .collection(_mainDB)
              .doc(recordID)
              .set(state)
              .onError(
                (Object? e, _) => _log.severe("Error writing document: $e"),
              );
        }
      } catch (e) {
        _log.severe("firebasePushSingleScore $e");
      }
    }
  }

  Future<double> firebasePercentile({
    required int levelNum,
    required int levelCompletedInMillis,
    required int mazeId,
  }) async {
    await initialize();
    if (firebaseOn) {
      try {
        final CollectionReference<Map<String, dynamic>> collectionRef = _db!
            .collection(_mainDB);
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
        final int allCount = fasterCount + slowerCount + 1; //ignore equal times
        return (fasterCount + 1 - 1) / (allCount == 1 ? 100 : allCount - 1);
      } catch (e) {
        _log.severe("firebasePercentile error $e");
      }
    }
    return 1.0;
  }

  Future<void> firebasePushPlayerProgress(G g, String state) async {
    await initialize();
    _log.info("Push ${g.gUser}");
    if (firebaseOn && g.signedIn) {
      final Map<String, dynamic> dhState = <String, dynamic>{_data: state};
      await _db!
          .collection(_userSaves)
          .doc(g.gUser)
          .set(dhState)
          .onError((Object? e, _) => _log.severe("Error writing document: $e"));
    }
  }

  Future<String> firebasePullPlayerProgress(G g) async {
    await initialize();
    String gameEncoded = "";
    _log.info("Pull");
    if (firebaseOn && g.signedIn) {
      final DocumentReference<Map<String, dynamic>> docRef = _db!
          .collection(_userSaves)
          .doc(g.gUser);
      await docRef.get().then((DocumentSnapshot<dynamic> doc) {
        final Map<String, dynamic> gameEncodedTmp =
            doc.data() as Map<String, dynamic>;
        gameEncoded = gameEncodedTmp[_data] as String;
      }, onError: (dynamic e) => _log.severe("Error getting document: $e"));
    }
    return gameEncoded;
  }
}

FBase fBase = FBase();

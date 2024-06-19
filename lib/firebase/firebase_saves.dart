import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../utils/helper.dart';

/// This file has utilities for loading and saving the leaderboard in firebase

class Save {
  static const bool firebaseOn =
      true && firebaseOnReal; //!(windows && !kIsWeb);

  static const String mainDB = "scores";
  static const String summaryDB = "summary";

  FirebaseFirestore? db;

  Future<List<double>>? leaderboardWinTimesCache;

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

  void cacheLeaderboardNow() async {
    leaderboardWinTimesCache ??= getCacheLeaderboard(random);
  }

  Future<void> firebasePushSingleScore(String recordID, String state) async {
    if (firebaseOn) {
      debug("firebase push");
      try {
        if (firebaseOn) {
          final dhState = <String, dynamic>{"data": state};
          db!
              .collection(mainDB)
              .doc(recordID)
              .set(dhState)
              .onError((e, _) => debug("Error writing document: $e"));
        }
      } catch (e) {
        debug(e);
      }
    }
  }

  Future<void> firebasePushSummaryLeaderboard(String state) async {
    if (firebaseOn) {
      debug("firebase push percentiles");
      try {
        if (firebaseOn) {
          final dhState = <String, dynamic>{"data": state};
          db!
              .collection(summaryDB)
              .doc("percentiles")
              .set(dhState)
              .onError((e, _) => debug("Error writing document: $e"));
        }
      } catch (e) {
        debug(e);
      }
    }
  }

  Future<String> firebasePullSummaryLeaderboard() async {
    String gameEncoded = "";
    if (firebaseOn) {
      try {
        final docRef = db!.collection(summaryDB).doc("percentiles");
        await docRef.get().then(
          (DocumentSnapshot doc) {
            final gameEncodedTmp = doc.data() as Map<String, dynamic>;
            gameEncoded = gameEncodedTmp["data"];
          },
          onError: (e) => debug("Error getting document: $e"),
        );
      } catch (e) {
        debug(["no matching fb entries", e]);
      }
    }
    return gameEncoded;
  }

  Future<List> firebasePullFullLeaderboard() async {
    List<Map<String, dynamic>> allFirebaseEntries = [];
    if (firebaseOn) {
      try {
        if (firebaseOn) {
          final collectionRef = db!.collection(mainDB);
          QuerySnapshot querySnapshot = await collectionRef.get();
          final allData = querySnapshot.docs
              .map((doc) => {doc.id: doc.data() as Map<String, dynamic>})
              .toList();
          for (int i = 0; i < allData.length; i++) {
            try {
              var item = allData[i];
              for (String key in item.keys) {
                String x = item[key]!["data"].toString();
                Map<String, dynamic> singleEntry = {};
                singleEntry = json.decode(x);
                allFirebaseEntries.add(singleEntry);
              }
            } catch (e) {
              debug(["ill formed firebase entry", e]);
            }
          }
          return allFirebaseEntries;
        }
      } catch (e) {
        debug(["full firebase entries error", e]);
      }
    }
    return allFirebaseEntries;
  }

  double percentile(int percentile, List origList) {
    List<double> list = List<double>.from(origList);
    list.sort();
    double firstPositionUnrounded = (percentile / 100 * (list.length - 1));
    int firstPosition = firstPositionUnrounded.floor();
    double first = list[firstPosition];
    int secondPosition = firstPosition + 1;
    double second = secondPosition >= list.length ? 1 : list[secondPosition];
    return (firstPositionUnrounded - firstPosition) /
            (secondPosition - firstPosition) *
            (second - first) +
        first;
  }

  List<double> summariseLeaderboard(List<double> startList) {
    List<double> percentilesList = [];
    List<double> newList = List<double>.from(startList);
    if (newList.isNotEmpty) {
      newList.sort();
      for (int i = 0; i < 101; i++) {
        percentilesList.add((percentile(i, newList) * 1000).round() / 1000);
      }
    }
    return percentilesList;
  }

  String encodeSummarisedLeaderboard(int length, List<double> percentilesList) {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["effectiveDate"] = DateTime.now().millisecondsSinceEpoch;
    gameTmp["percentilesList"] = percentilesList;
    gameTmp["leaderboardLength"] = length;
    String result = json.encode(gameTmp);
    //p(["encoded percentiles", result]);
    return result;
  }

  Future<List<double>> downloadLeaderboardFull() async {
    List<double> tmpList = [];
    List firebaseDownloadCache = await save.firebasePullFullLeaderboard();
    for (int i = 0; i < firebaseDownloadCache.length; i++) {
      tmpList.add(firebaseDownloadCache[i]["levelCompleteTime"]);
    }
    return tmpList;
  }

  Future<Map<String, dynamic>> downloadLeaderboardSummary() async {
    String firebaseDownloadCacheEncoded =
        await save.firebasePullSummaryLeaderboard();
    Map<String, dynamic> gameTmp = {};
    if (firebaseDownloadCacheEncoded != "") {
      gameTmp = json.decode(firebaseDownloadCacheEncoded) ?? {};
    }
    return gameTmp;
  }

  Future<List<double>> getCacheLeaderboard(Random random) async {
    Map<String, dynamic> leaderboardSummary = {};
    List<double> leaderboardWinTimesTmp = [];

    if (firebaseOn) {
      //so don't re-download
      try {
        leaderboardSummary = await downloadLeaderboardSummary();
      } catch (e) {
        //likely firebase database blank, i.e. first run
        debug(["ill-formed leaderboard", e]);
      }

      if (leaderboardSummary.isEmpty ||
          leaderboardSummary["percentilesList"].isEmpty ||
          leaderboardSummary["effectiveDate"] <
              DateTime.now().millisecondsSinceEpoch -
                  1000 * 60 * 60 * 6 -
                  1000 * 60 * 10 * random.nextDouble() ||
          !leaderboardSummary.keys.contains("leaderboardLength") ||
          leaderboardSummary["leaderboardLength"] < 20) {
        //random 10 minutes to avoid multiple hits at the same time
        debug("full refresh required");
        List<double> downloadedLeaderboard = await downloadLeaderboardFull();
        await save.firebasePushSummaryLeaderboard(encodeSummarisedLeaderboard(
            downloadedLeaderboard.length,
            summariseLeaderboard(downloadedLeaderboard)));
        debug("pushed new summary");
        leaderboardSummary = await downloadLeaderboardSummary();
        debug("refreshed summary download");
      }

      for (int i = 0; i < leaderboardSummary["percentilesList"].length; i++) {
        leaderboardWinTimesTmp.add(leaderboardSummary["percentilesList"][i]);
      }
      debug("summary saved locally");
    }
    return leaderboardWinTimesTmp;
  }
}

Save save = Save();

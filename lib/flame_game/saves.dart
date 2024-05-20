import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'helper.dart';
import 'constants.dart';
import 'dart:convert';

class Save {

  FirebaseFirestore? db = fbOn ? FirebaseFirestore.instance : null;

  Future<void> firebasePushSingleScore(String recordID, String state) async {
    if (fbOn) {
      p("firebase push");
      try {
        if (fbOn) {
          final dhState = <String, dynamic>{"data": state};
          db!
              .collection(mainDB)
              .doc(recordID)
              .set(dhState)
              .onError((e, _) => p("Error writing document: $e"));
        }
      } catch (e) {
        p(e);
      }
    }
  }

  Future<void> firebasePushSummaryLeaderboard(String state) async {
    if (fbOn) {
      p("firebase push percentiles");
      try {
        if (fbOn) {
          final dhState = <String, dynamic>{"data": state};
          db!
              .collection(summaryDB)
              .doc("percentiles")
              .set(dhState)
              .onError((e, _) => p("Error writing document: $e"));
        }
      } catch (e) {
        p(e);
      }
    }
  }

  Future<String> firebasePullSummaryLeaderboard() async {
    String gameEncoded = "";
    if (fbOn) {
      try {
        final docRef = db!.collection(summaryDB).doc("percentiles");
        await docRef.get().then(
              (DocumentSnapshot doc) {
            final gameEncodedTmp = doc.data() as Map<String, dynamic>;
            gameEncoded = gameEncodedTmp["data"];
          },
          onError: (e) => p("Error getting document: $e"),
        );
      }
      catch(e) {
        p(["no matching fb entries",e]);
      }
    }
    return gameEncoded;
  }

  Future<List> firebasePullFullLeaderboard() async {
    List<Map<String, dynamic>> allFirebaseEntries = [];
    if (fbOn) {
      try {
        if (fbOn) {
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
              p(["ill formed firebase entry",e]);
            }
          }
          return allFirebaseEntries;
        }
      } catch (e) {
        p(["full firebase entries error",e]);
      }
    }
    return allFirebaseEntries;
  }

  List<double> summariseLeaderboard(List<double> startList) {
    List<double> percentilesList = [];

    List<double> newList = List<double>.from(startList);

    if (newList.isNotEmpty) {
      newList.sort();

      for (int i = 0; i < 101; i++) {
        percentilesList.add(newList[(i / 100 * (newList.length - 1)).floor()]);
      }
    }
    return percentilesList;
  }

  String encodeSummarisedLeaderboard(percentilesList) {
    Map<String, dynamic> gameTmp = {};
    gameTmp = {};
    gameTmp["effectiveDate"] = DateTime.now().millisecondsSinceEpoch;
    gameTmp["percentilesList"] = percentilesList;
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

    if (true) {
      //so don't re-download
      try {
        leaderboardSummary = await downloadLeaderboardSummary();
      } catch (e) {
        //likely firebase database blank, i.e. first run
        p(["ill-formed leaderboard",e]);
      }

      if (leaderboardSummary.isEmpty ||
          leaderboardSummary["percentilesList"].isEmpty ||
          leaderboardSummary["effectiveDate"] <
              DateTime.now().millisecondsSinceEpoch -
                  1000 * 60 * 60 -
                  1000 * 60 * 10 * random.nextDouble()) {
        //random 10 minutes to avoid multiple hits at the same time
        p("full refresh required");
        await save.firebasePushSummaryLeaderboard(encodeSummarisedLeaderboard(
            summariseLeaderboard(await downloadLeaderboardFull())));
        p("pushed new summary");
        leaderboardSummary = await downloadLeaderboardSummary();
        p("refreshed summary download");
      }

      for (int i = 0; i < leaderboardSummary["percentilesList"].length; i++) {
        leaderboardWinTimesTmp.add(leaderboardSummary["percentilesList"][i]);
      }
      p("summary saved locally");
    }
    return leaderboardWinTimesTmp;
  }

}

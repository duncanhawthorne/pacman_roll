import 'package:cloud_firestore/cloud_firestore.dart';
import 'helper.dart';
import 'constants.dart';
import 'dart:convert';

class Save {
  Future<void> firebasePushSingleScore(String recordID, String state) async {
    if (fbOn) {
      p("firebase push");
      try {
        if (fbOn) {
          final dhState = <String, dynamic>{"data": state};
          db!
              .collection("PMR3")
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
              .collection("PMRpercent")
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
      final docRef = db!.collection("PMRpercent").doc("percentiles");
      await docRef.get().then(
            (DocumentSnapshot doc) {
          final gameEncodedTmp = doc.data() as Map<String, dynamic>;
          gameEncoded = gameEncodedTmp["data"];
        },
        onError: (e) => p("Error getting document: $e"),
      );
    }
    return gameEncoded;
  }

  Future<List> firebasePullFullLeaderboard() async {
    List<Map<String, dynamic>> allFirebaseEntries = [];
    if (fbOn) {
      try {
        if (fbOn) {
          final collectionRef = db!.collection("PMR3");
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
              p(e);
            }
          }
          return allFirebaseEntries;
        }
      } catch (e) {
        p(e);
      }
    }
    return allFirebaseEntries;
  }
}

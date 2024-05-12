import 'package:cloud_firestore/cloud_firestore.dart';
import 'helper.dart';
import 'constants.dart';
import 'dart:convert';

class Save {
  Future<void> firebasePush(String recordID, String state) async {
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

  Future<List> firebasePull() async {
    List<Map<String, dynamic>> allFirebaseEntries = [];
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
              //String x = item[key].toString();
              //x = x.substring(7, x.length - 1);
              String x = item[key]!["data"].toString();
              Map<String, dynamic> singleEntry = {};
              singleEntry = json.decode(x);
              //p(singleEntry);
              allFirebaseEntries.add(singleEntry);
            }
          }
          catch(e) {
            p(e);
          }
        }
        //p(allFirebaseEntries);
        return allFirebaseEntries;
      }
    } catch (e) {
      p(e);
    }
    return allFirebaseEntries;
  }
}

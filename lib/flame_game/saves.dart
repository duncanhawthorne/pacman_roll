import 'package:cloud_firestore/cloud_firestore.dart';
import 'helper.dart';
import 'constants.dart';
import 'dart:math';

class Save {
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  Future<void> firebasePush(double state) async {
    try {
      if (fbOn && state > 10.0) { //dont store short times from debug sessions
        final dhState = <String, dynamic>{"data": state};
        db!
            .collection("PMR")
            .doc(getRandomString(10))
            .set(dhState)
            .onError((e, _) => p("Error writing document: $e"));
      }
    }
    catch(e) {
      p(e);
    }
  }

  Future<Map<String, double>> firebasePull() async {
    Map<String, double> result = {};
    try {
      if (fbOn) {
        final collectionRef = db!.collection("PMR");
        QuerySnapshot querySnapshot = await collectionRef.get();
        final allData =
        querySnapshot.docs.map((doc) => {doc.id: doc.data()}).toList();

        for (int i = 0; i < allData.length; i++) {
          var item = allData[i];
          for (String key in item.keys) {
            try {
              var x = item[key].toString();
              x = x.substring(7, x.length - 1);
              double y = double.parse(x);
              result[key] = y;
            }
            catch (e) {
              p(e);
            }
          }
        }
      }

    }
    catch(e) {
      p(e);
    }
    return result;
  }

}

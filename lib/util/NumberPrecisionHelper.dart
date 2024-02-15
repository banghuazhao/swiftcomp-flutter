import 'package:flutter/material.dart';

import 'others.dart';

class NumberPrecisionHelper extends ChangeNotifier {
  final String KEY = "Number_Precision";

  int get precision {
    int temp = SharedPreferencesHelper.localStorage.getInt(KEY) ?? 5;
    return temp;
  }

  set(int precision) {
    SharedPreferencesHelper.localStorage.setInt(KEY, precision);
    notifyListeners();
  }
}

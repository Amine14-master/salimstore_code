import 'package:flutter/foundation.dart';

class OrdersBadgeController extends ValueNotifier<int> {
  OrdersBadgeController._() : super(0);

  static final OrdersBadgeController instance = OrdersBadgeController._();

  void setCount(int count) {
    if (value != count) {
      value = count;
    }
  }
}

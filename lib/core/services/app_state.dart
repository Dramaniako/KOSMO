import 'package:flutter/foundation.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<bool> isVerifiedNotifier = ValueNotifier<bool>(false);

  bool get isVerified => isVerifiedNotifier.value;
  set isVerified(bool value) {
    isVerifiedNotifier.value = value;
  }
}

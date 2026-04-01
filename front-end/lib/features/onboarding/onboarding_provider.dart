import 'package:flutter/material.dart';

class OnboardingProvider extends ChangeNotifier {
  int _page = 0;
  static const int total = 3;

  int get page => _page;
  bool get isLast => _page == total - 1;

  void next(PageController ctrl) {
    if (!isLast) {
      _page++;
      ctrl.animateToPage(_page,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOutCubic);
      notifyListeners();
    }
  }

  void onChanged(int p) {
    _page = p;
    notifyListeners();
  }

  void jumpTo(int p, PageController ctrl) {
    _page = p;
    ctrl.animateToPage(p,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic);
    notifyListeners();
  }
}
import 'package:flutter/foundation.dart';
import 'package:sekurity/tools/keymanagement.dart';

class Keys extends ChangeNotifier {
  final List<KeyStruct> _items = [];

  List<KeyStruct> get items => _items;

  void addItem(KeyStruct item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(KeyStruct item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// This is used to update the UI when settings are changed
  void uiUpdate() {
    notifyListeners();
  }
}

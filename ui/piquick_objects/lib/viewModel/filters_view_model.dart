import 'package:flutter/foundation.dart';
import 'package:piquick_objects/model/filters_model.dart';
import 'package:piquick_objects/model/filter.dart';

class FiltersViewModel with ChangeNotifier {
  final FiltersModel _filtersModel = FiltersModel(filters: []);
  List<Filter> get filters => _filtersModel.filters;

  void updateFilter(String type, int min, int max) {
    _filtersModel.updateFilter(type, min, max);
    notifyListeners();
  }

  void applyFilters() {
    _filtersModel.fetchFilteredIds();
    // Logika a szűrők alkalmazásához
  }

}
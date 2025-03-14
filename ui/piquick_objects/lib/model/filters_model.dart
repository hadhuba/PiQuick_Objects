import 'package:piquick_objects/model/filter.dart';
import 'package:piquick_objects/services/filter_service.dart';

class FiltersModel {
  final FilterService _filterService = FilterService();

  final List<Filter> filters;
  FiltersModel({required this.filters}){
    List<dynamic> lista = _filterService.getFilterTypes();
    filters.addAll(lista.map((e) => Filter(type: e)).toList());

    // filters.forEach((filter) => filter.minValue = filter.minValue ?? null);
    // filters.forEach((filter) => filter.maxValue = filter.maxValue ?? null);
    filters.forEach((filter) => filter.minValue = null);
    filters.forEach((filter) => filter.maxValue = null);
  }

  void updateFilter(String type, int min, int max) {
    final filter = filters.firstWhere((filter) => filter.type == type);
    filter.minValue = min;
    filter.maxValue = max;
  }

    // ne legyen visszatérési értéke, az id-kat más kapja meg
  void fetchFilteredIds() async {
    await _filterService.fetchFilteredIds(this);
  }
}
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'filter.dart';

class Filters {
  final List<Filter> filters;
  Filters({required this.filters});

  // late List<Filter> filters;
  // Filters({required List<String> types}) {
  //   filters = types.map((e) => Filter(type: e)).toList();
  // }

  // Filters.fromFiltersList({required this.filters});

  void updateFilter(String type, int min, int max) {
    final filter = filters.firstWhere(
      (filter) => filter.type == type,
      orElse: () => throw Exception('Filter with type $type not found'),
    );
    filter.minValue = min;
    filter.maxValue = max;
  }

  Filters copyWith({List<Filter>? filters}) {
    return Filters(filters: filters ?? this.filters);
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'filters': filters.map((x) => x.toMap()).toList()};
  }

  factory Filters.fromMap(Map<String, dynamic> map) {
    return Filters(
      filters: List<Filter>.from(
        (map['filters'] as List<dynamic>).map<Filter>(
          (x) => Filter.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
  String toJson() => json.encode(toMap());

  factory Filters.fromJson(String source) =>
      Filters.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Filters(filters: $filters)';

  @override
  int get hashCode => filters.hashCode;
}

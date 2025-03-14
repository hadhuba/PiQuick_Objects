import 'package:piquick_objects/model/filters_model.dart';

class FilterService {
  Future<List<String>> fetchFilteredIds(FiltersModel model) async {
    // Simulate a network request to fetch IDs based on filters
    // Replace this with actual network request code
    await Future.delayed(Duration(seconds: 2));
    return ['id1', 'id2', 'id3']; // Example response
  }

    Map<String, dynamic> toJson(filters) {
    return {
      'filters': filters.map((filter) => filter.toJson()).toList(),
    }; 
    //Future<List<String>>
  }

  List getFilterTypes() { //initial maxvalue, minvalue for each filter
    return ['type1', 'type2', 'type3'];
  }
}
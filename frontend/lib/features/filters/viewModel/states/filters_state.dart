import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/filters/model/filter.dart';

class FiltersState {
  final AsyncValue<String> serverConnection;
  final AsyncValue<List<Filter>> filters;
  final AsyncValue<List<String>> objectsList;

  FiltersState({
    required this.serverConnection,
    required this.filters,
    required this.objectsList,
  });

  FiltersState copyWith({
    AsyncValue<String>? serverConnection,
    AsyncValue<List<Filter>>? filters,
    AsyncValue<List<String>>? objectsList,
  }) {
    return FiltersState(
      serverConnection: serverConnection ?? this.serverConnection,
      filters: filters ?? this.filters,
      objectsList: objectsList ?? this.objectsList,
    );
  }

  // Getter to extract the filters list from AsyncValue<Filters>
  List<Filter>? get filtersList {
    return filters.when(
      data:
          (filters) =>
              filters, // Return the list of filters if data is available
      loading: () => null, // Return null if loading
      error: (error, stackTrace) => null, // Return null if there's an error
    );
  }
}

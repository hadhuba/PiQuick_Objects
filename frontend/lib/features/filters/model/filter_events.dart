/// Base class for all filter-related events in the application.
abstract class FilterEvent {
  const FilterEvent();
}

/// Event triggered when filters are applied, containing the new list of objects.
class AppliedFiltersEvent extends FilterEvent {
  final List<String>? newObjects;

  const AppliedFiltersEvent({required this.newObjects});
}

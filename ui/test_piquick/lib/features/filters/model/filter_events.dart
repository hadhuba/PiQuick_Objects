// A filters modul különböző eseményeinek definíciói
abstract class FilterEvent {
  const FilterEvent();
}

// A beállítások mentésének eseménye
class AppliedFiltersEvent extends FilterEvent {
  final List<String>? newObjects; // A beállítások objektum

  const AppliedFiltersEvent({required this.newObjects});
}

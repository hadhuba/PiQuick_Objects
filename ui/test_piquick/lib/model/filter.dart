class Filter {
  final String type;
  num? minValue;
  num? maxValue;

  Filter({required this.type, this.minValue, this.maxValue});

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }
}
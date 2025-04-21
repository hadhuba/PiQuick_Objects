// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Filter {
  final String type;
  num? minValue;
  num? maxValue;
  String? description;

  Filter({required this.type, this.minValue, this.maxValue, this.description}) {
    minValue = minValue ?? null;
    maxValue = maxValue ?? null;
    description = description ?? null;
  }

  Filter copyWith({String? type, num? minValue, num? maxValue, String? description}) {
    return Filter(
      type: type ?? this.type,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      description: this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      'minValue': minValue,
      'maxValue': maxValue
    };
  }

  factory Filter.fromMap(Map<String, dynamic> map) {
    return Filter(
      type: map['type'] as String,
      minValue: map['minValue'] != null ? map['minValue'] as num : null,
      maxValue: map['maxValue'] != null ? map['maxValue'] as num : null,
      description: map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Filter.fromJson(String source) =>
      Filter.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Filter(type: $type, minValue: $minValue, maxValue: $maxValue)';

  @override
  bool operator ==(covariant Filter other) {
    if (identical(this, other)) return true;

    return other.type == type &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.description == description;
  }

  @override
  int get hashCode => type.hashCode ^ minValue.hashCode ^ maxValue.hashCode ^ description.hashCode;
  }

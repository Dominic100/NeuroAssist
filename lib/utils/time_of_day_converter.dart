import 'package:flutter/material.dart';

// Extension to help with TimeOfDay and Firestore
extension TimeOfDayConverter on TimeOfDay {
  Map<String, int> toMap() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  static TimeOfDay fromMap(Map<String, dynamic> map) {
    return TimeOfDay(
      hour: map['hour'] ?? 0,
      minute: map['minute'] ?? 0,
    );
  }
}
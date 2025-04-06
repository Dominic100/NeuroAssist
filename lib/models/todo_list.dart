import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TodoTask {
  final String id;
  String name;
  String description;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isCompleted;
  DateTime createdAt;
  DateTime? completedAt;
  // These fields are not used in the model but will be added 
  // when saving to Firestore in the service
  // String? listId;
  // String? userEmail;

  TodoTask({
    String? id,
    required this.name,
    this.description = '',
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'dueTime': dueTime != null ? {
        'hour': dueTime!.hour,
        'minute': dueTime!.minute,
      } : null,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      // listId and userEmail will be added in the TodoService
    };
  }

  // Create a TodoTask from a Firestore document
  factory TodoTask.fromDocument(Map<String, dynamic> doc) {
    try {
      final dueTimeMap = doc['dueTime'];
      TimeOfDay? timeOfDay;
      
      if (dueTimeMap != null) {
        timeOfDay = TimeOfDay(
          hour: dueTimeMap['hour'] ?? 0,
          minute: dueTimeMap['minute'] ?? 0,
        );
      }

      return TodoTask(
        id: doc['id'] ?? const Uuid().v4(),
        name: doc['name'] ?? 'Unnamed Task',
        description: doc['description'] ?? '',
        dueDate: doc['dueDate'] != null ? (doc['dueDate'] as Timestamp).toDate() : null,
        dueTime: timeOfDay,
        isCompleted: doc['isCompleted'] ?? false,
        createdAt: doc['createdAt'] != null ? (doc['createdAt'] as Timestamp).toDate() : DateTime.now(),
        completedAt: doc['completedAt'] != null ? (doc['completedAt'] as Timestamp).toDate() : null,
      );
    } catch (e) {
      print('Error parsing TodoTask from document: $e');
      return TodoTask(
        id: doc['id'] ?? const Uuid().v4(),
        name: 'Error loading task',
        description: 'There was an error loading this task.',
      );
    }
  }

  TodoTask copyWith({
    String? name,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return TodoTask(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class TodoList {
  final String id;
  String name;
  String color; // Store as a hex string
  DateTime createdAt;
  // This field is not used in the model but will be added 
  // when saving to Firestore in the service
  // String? userEmail;
  
  // We don't store tasks here in the flattened model
  // List<TodoTask> tasks;

  TodoList({
    String? id,
    required this.name,
    this.color = '#4CAF50', // Default to green
    DateTime? createdAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      // userEmail will be added in the TodoService
    };
  }

  // Create a TodoList from a Firestore document
  factory TodoList.fromDocument(Map<String, dynamic> doc) {
    try {
      return TodoList(
        id: doc['id'] ?? const Uuid().v4(),
        name: doc['name'] ?? 'Untitled List',
        color: doc['color'] ?? '#4CAF50',
        createdAt: doc['createdAt'] != null ? (doc['createdAt'] as Timestamp).toDate() : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing TodoList from document: $e');
      return TodoList(
        id: doc['id'] ?? const Uuid().v4(),
        name: 'Error loading list',
      );
    }
  }
}
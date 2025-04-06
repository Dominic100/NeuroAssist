import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/todo_list.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's email or throw if not signed in
  String get _userEmail {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw Exception('User must be authenticated to access todo lists');
    }
    return email;
  }

  // Reference to the todoLists collection (root level)
  CollectionReference get _listsCollection {
    return _firestore.collection('todoLists');
  }

  // Reference to the tasks collection (root level)
  CollectionReference get _tasksCollection {
    return _firestore.collection('tasks');
  }

  // Get all lists for the current user
  Stream<List<TodoList>> getLists() {
    return _listsCollection
        .where('userEmail', isEqualTo: _userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Lists snapshot received, count: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) {
        try {
          return TodoList.fromDocument(doc.data() as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing list: $e');
          return TodoList(
            id: doc.id,
            name: 'Error loading list',
          );
        }
      }).toList();
    });
  }

  // Get all tasks for a specific list
  Stream<List<TodoTask>> getTasks(String listId) {
    print('Getting tasks for list: $listId');
    return _tasksCollection
        .where('listId', isEqualTo: listId)
        .orderBy('isCompleted')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Tasks snapshot received, count: ${snapshot.docs.length}');
      return snapshot.docs.map((doc) {
        try {
          return TodoTask.fromDocument(doc.data() as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing task: $e');
          return TodoTask(
            id: doc.id,
            name: 'Error loading task',
            description: 'Error: $e',
          );
        }
      }).toList();
    });
  }

  // Create a new list
  Future<String> createList(TodoList list) async {
    try {
      // Add userEmail field to the list document
      final listMap = list.toMap();
      listMap['userEmail'] = _userEmail;
      
      await _listsCollection.doc(list.id).set(listMap);
      return list.id;
    } catch (e) {
      print('Error creating list: $e');
      rethrow;
    }
  }

  // Update an existing list
  Future<void> updateList(TodoList list) async {
    try {
      await _listsCollection.doc(list.id).update({
        'name': list.name,
        'color': list.color,
      });
    } catch (e) {
      print('Error updating list: $e');
      rethrow;
    }
  }

  // Delete a list and all its tasks
  Future<void> deleteList(String listId) async {
    try {
      // Get all tasks for this list
      final tasksDocs = await _tasksCollection
          .where('listId', isEqualTo: listId)
          .get();
      
      // Use a batch to delete all tasks and the list
      final batch = _firestore.batch();
      
      // Delete all tasks
      for (var doc in tasksDocs.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the list
      batch.delete(_listsCollection.doc(listId));
      
      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting list: $e');
      rethrow;
    }
  }

  // Add a task to a list
  Future<String> addTask(String listId, TodoTask task) async {
    try {
      // Add listId and userEmail fields to the task document
      final taskMap = task.toMap();
      taskMap['listId'] = listId;
      taskMap['userEmail'] = _userEmail;
      
      await _tasksCollection.doc(task.id).set(taskMap);
      return task.id;
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  // Update a task
  Future<void> updateTask(String listId, TodoTask task) async {
    try {
      final taskMap = task.toMap();
      taskMap['listId'] = listId; // Ensure listId is included
      
      await _tasksCollection.doc(task.id).update(taskMap);
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // Toggle task completion status
  Future<void> toggleTaskComplete(String listId, TodoTask task, bool isCompleted) async {
    try {
      await _tasksCollection.doc(task.id).update({
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? Timestamp.fromDate(DateTime.now()) : null,
      });
    } catch (e) {
      print('Error toggling task completion: $e');
      rethrow;
    }
  }

  // Delete a task
  Future<void> deleteTask(String listId, String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }
}
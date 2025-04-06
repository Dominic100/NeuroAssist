import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PomodoroSession {
  static const String COLLECTION_NAME = 'pomodoro';
  
  // Create a new session in Firestore
  static Future<String> startSession({
    required String userEmail,
    required bool isCustomMode,
    required Map<String, dynamic> config,
  }) async {
    try {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No signed-in user found, using Guest User email');
        userEmail = 'Guest User';
      } else {
        print('User is signed in: ${user.email}');
      }
      
      // Generate a session ID
      final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create initial document
      final sessionData = {
        // User identification - only store email
        'userEmail': userEmail,
        
        // Session metadata
        'sessionId': sessionId,
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'completed': false,
        
        // Session configuration
        'sessionType': isCustomMode ? 'custom' : 'standard',
        
        // Appropriate configuration based on mode
        'standardConfig': !isCustomMode ? config['standardConfig'] : null,
        'customConfig': isCustomMode ? config['customConfig'] : null,
        
        // Progress tracking (initial values)
        'sessionsCompleted': 0,
        'totalWorkMinutes': 0,
        'totalBreakMinutes': 0,
        
        // Empty session details array to be populated as session progresses
        'sessionDetails': [],
      };
      
      try {
        await FirebaseFirestore.instance
            .collection(COLLECTION_NAME)
            .doc(sessionId)
            .set(sessionData);
        print('Successfully created Firestore document: $sessionId');
        
        // Verify the document was created
        bool exists = await verifySessionExists(sessionId);
        if (exists) {
          print('✅ Verification: Session document exists in Firestore');
        } else {
          print('❌ Verification FAILED: Session document does NOT exist in Firestore!');
        }
        
        return sessionId;
      } catch (firestoreError) {
        print('❌ Firestore error during set operation: $firestoreError');
        print('Error details: ${firestoreError.toString()}');
        return '';
      }
    } catch (e) {
      print('❌ General error starting pomodoro session: $e');
      print('Error details: ${e.toString()}');
      return '';
    }
  }
  
  // Update session with a completed segment
  static Future<void> addSessionSegment({
    required String sessionId,
    required String type,
    required int durationPlanned,
    required int durationActual,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      if (sessionId.isEmpty) {
        print('Cannot add segment: Session ID is empty');
        return;
      }
      
      // Create segment data
      final segmentData = {
        'type': type,
        'durationPlanned': durationPlanned,
        'durationActual': durationActual,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      };
      
      print('Adding segment to session $sessionId: $segmentData');
      
      // Update the document
      await FirebaseFirestore.instance
          .collection(COLLECTION_NAME)
          .doc(sessionId)
          .update({
            'sessionDetails': FieldValue.arrayUnion([segmentData]),
            // Also update the aggregate counters
            'totalWorkMinutes': FieldValue.increment(
                type == 'work' ? durationActual : 0),
            'totalBreakMinutes': FieldValue.increment(
                type == 'break' ? durationActual : 0),
            'sessionsCompleted': FieldValue.increment(
                type == 'work' ? 1 : 0),
          })
          .then((_) => print('Successfully added segment to session $sessionId'))
          .catchError((error) => throw error);
    } catch (e) {
      print('Error updating pomodoro session: $e');
      print('Error details: ${e.toString()}');
    }
  }
  
  // Mark session as completed
  static Future<void> completeSession({
    required String sessionId,
    required bool completed,
  }) async {
    try {
      if (sessionId.isEmpty) {
        print('Cannot complete session: Session ID is empty');
        return;
      }
      
      print('Marking session $sessionId as ${completed ? "completed" : "incomplete"}');
      
      await FirebaseFirestore.instance
          .collection(COLLECTION_NAME)
          .doc(sessionId)
          .update({
            'endTime': FieldValue.serverTimestamp(),
            'completed': completed,
          })
          .then((_) => print('Successfully marked session $sessionId as ${completed ? "completed" : "incomplete"}'))
          .catchError((error) => throw error);
    } catch (e) {
      print('Error completing pomodoro session: $e');
      print('Error details: ${e.toString()}');
    }
  }
  
  // Verify if a session exists (can be used for debugging)
  static Future<bool> verifySessionExists(String sessionId) async {
    try {
      if (sessionId.isEmpty) return false;
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection(COLLECTION_NAME)
          .doc(sessionId)
          .get();
          
      final exists = docSnapshot.exists;
      print('Session $sessionId exists: $exists');
      return exists;
    } catch (e) {
      print('Error verifying session: $e');
      return false;
    }
  }
}
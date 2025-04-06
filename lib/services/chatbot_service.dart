import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotService {
  static const String apiKey = '***'; // Replace with your actual API key
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Sorry, I couldn't process that request. Please try again later.";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  String? getUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  String getUserFirstName() {
    final email = getUserEmail();
    if (email == null) return "User";
    return email.split('@').first;
  }
}
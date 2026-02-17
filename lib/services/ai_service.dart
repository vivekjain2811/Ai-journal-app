import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class AIService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Map<String, String>> enhanceJournal(String content) async {
    if (content.trim().isEmpty) {
      throw Exception('Content cannot be empty');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Updated to supported model
          'messages': [
            {
              'role': 'system',
              'content': '''
You are an empathetic ai journaling assistant. Analyze the user's journal entry.
Return a JSON object with 3 keys: "title", "enhanced_content", and "mood".

1. "title": A specific, creative, and relevant title (max 7 words) that reflects the EXACT topic of the entry. Avoid generic titles like "Journal Analysis" or "Daily Thoughts". Example: "Feeling Sad After Interview" or "Amazing Trip to Paris".
2. "enhanced_content": Improve the grammar, flow, and clarity of the paragraph. Remove unnecessary words but potentially expand slightly to make it more expressive. KEEP the user's original voice and meaning.
3. "mood": Detect the mood from the text. Return EXACTLY ONE of these emojis: �, 😌, 😔, �, 😠. (Happy, Calm, Sad, Anxious, Angry). If unsure, guess the closest one.

output JSON only.
'''
            },
            {
              'role': 'user',
              'content': content
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentString = data['choices'][0]['message']['content'];
        
        // Robust cleaning: remove markdown code blocks
        if (contentString.contains('```json')) {
          contentString = contentString.split('```json')[1].split('```')[0].trim();
        } else if (contentString.contains('```')) {
          contentString = contentString.split('```')[1].split('```')[0].trim();
        }
        
        try {
          final jsonResponse = jsonDecode(contentString) as Map<String, dynamic>;
          return {
            'title': jsonResponse['title']?.toString() ?? 'Journal Entry',
            'enhanced_content': jsonResponse['enhanced_content']?.toString() ?? content,
            'mood': jsonResponse['mood']?.toString() ?? '😐',
          };
        } catch (e) {
          debugPrint('Error parsing inner JSON: $e');
          debugPrint('Raw content was: $contentString');
          // Fallback if model doesn't return valid JSON
          return {
            'title': 'Journal Entry', 
            'enhanced_content': content,
            'mood': '😐',
          };
        }
      } else {
        throw Exception('Failed to enhance journal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI Service Error: $e');
      rethrow;
    }
  }
}

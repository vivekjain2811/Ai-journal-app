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
You are an expert editor. 
Your task is to Analyze the user's journal entry and return a JSON object.

RULES:
1. Return ONLY valid JSON. 
2. Do NOT use markdown code blocks (like ```json).
3. Do NOT include any conversational text.
4. The JSON must have exactly these 3 keys:
   - "title": A short, specific title (max 7 words).
   - "enhanced_content": The journal entry rephrased for better grammar, flow, and clarity. Fix ALL grammar mistakes. Keep the same meaning but make it sound better.
   - "mood": One single emoji representing the mood (😐, 😌, 😔, 😬, 😠).

Example Response:
{"title": "My Day", "enhanced_content": "Today was a good day.", "mood": "😌"}
'''
            },
            {
              'role': 'user',
              'content': 'Journal Content to enhance:\n"$content"\n\nRemember: JSON ONLY.'
            }
          ],
          'temperature': 0.3, // Lower temperature for more deterministic/valid JSON
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contentString = data['choices'][0]['message']['content'];
        
        debugPrint('Raw AI Response: $contentString'); 

        // 1. Sanitize: Remove markdown code blocks if present
        contentString = contentString.replaceAll('```json', '').replaceAll('```', '').trim();

        // 2. Find JSON bounds
        final startIndex = contentString.indexOf('{');
        final endIndex = contentString.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          contentString = contentString.substring(startIndex, endIndex + 1);
        } else {
           throw FormatException('No JSON object found in response');
        }
        
        try {
          final jsonResponse = jsonDecode(contentString) as Map<String, dynamic>;
          return {
            'title': jsonResponse['title']?.toString() ?? 'Journal Entry',
            'enhanced_content': jsonResponse['enhanced_content']?.toString() ?? content,
            'mood': jsonResponse['mood']?.toString() ?? '😐',
          };
        } catch (e) {
          debugPrint('JSON Syntax Error: $e');
          debugPrint('Problematic String: $contentString');
          // Fallback
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

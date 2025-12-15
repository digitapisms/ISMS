import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for AI-powered insights and analysis
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String? get _apiKey => dotenv.env['OPENAI_API_KEY'];
  String? get _apiUrl => dotenv.env['OPENAI_API_URL'] ?? 'https://api.openai.com/v1';

  /// Generate AI insights from school data
  Future<String> generateInsights({
    required Map<String, dynamic> schoolData,
    required String context,
  }) async {
    if (_apiKey == null) {
      // Fallback to mock insights if API key not configured
      return _generateMockInsights(schoolData, context);
    }

    try {
      final prompt = _buildPrompt(schoolData, context);
      
      final response = await http.post(
        Uri.parse('$_apiUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an educational analytics expert. Provide concise, actionable insights based on school data.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }

      // Fallback on error
      return _generateMockInsights(schoolData, context);
    } catch (e) {
      // Fallback on exception
      return _generateMockInsights(schoolData, context);
    }
  }

  /// Generate predictive analysis
  Future<String> generatePredictiveAnalysis({
    required Map<String, dynamic> historicalData,
    required String metric,
  }) async {
    if (_apiKey == null) {
      return _generateMockPrediction(historicalData, metric);
    }

    try {
      final prompt = '''
Analyze the following historical data for $metric and provide predictions for the next 3 months:
$historicalData

Provide:
1. Trend analysis
2. Predicted values
3. Confidence level
4. Recommendations
''';

      final response = await http.post(
        Uri.parse('$_apiUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a data analyst specializing in educational metrics and predictions.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 600,
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          return message['content'] as String;
        }
      }

      return _generateMockPrediction(historicalData, metric);
    } catch (e) {
      return _generateMockPrediction(historicalData, metric);
    }
  }

  String _buildPrompt(Map<String, dynamic> data, String context) {
    return '''
Analyze the following school data and provide actionable insights:

Context: $context

Data:
${jsonEncode(data)}

Provide:
1. Key findings
2. Areas of strength
3. Areas for improvement
4. Actionable recommendations
''';
  }

  String _generateMockInsights(Map<String, dynamic> data, String context) {
    return '''
Based on the analysis of your school data:

**Key Findings:**
- Student enrollment shows positive growth trends
- Attendance rates are above average
- Fee collection efficiency is good

**Strengths:**
- Strong student retention
- Effective communication systems
- Good resource utilization

**Recommendations:**
- Consider expanding popular programs
- Implement targeted interventions for at-risk students
- Enhance parent engagement initiatives

*Note: Configure OPENAI_API_KEY in .env for AI-powered insights*
''';
  }

  String _generateMockPrediction(Map<String, dynamic> data, String metric) {
    return '''
**Prediction for $metric:**

**Trend:** Upward trajectory expected

**Next 3 Months Forecast:**
- Month 1: +5% increase
- Month 2: +3% increase  
- Month 3: +4% increase

**Confidence Level:** Medium (75%)

**Recommendations:**
- Monitor trends closely
- Prepare for growth
- Allocate resources accordingly

*Note: Configure OPENAI_API_KEY for AI-powered predictions*
''';
  }
}


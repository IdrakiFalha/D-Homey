import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'YOUR_GCP_API_KEY_HERE';
  final urlStr = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=' + apiKey;
  final url = Uri.parse(urlStr);
  print('Calling URL: ' + url.toString());
  
  final body = {
    "contents": [
      {
        "role": "user",
        "parts": [{"text": "Hello"}]
      }
    ]
  };

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + response.body);
}

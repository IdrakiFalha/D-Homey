import 'package:google_generative_ai/google_generative_ai.dart';
void main() async {
  try {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: 'YOUR_GCP_API_KEY_HERE');
    final chat = model.startChat();
    final response = await chat.sendMessage(Content.text('Hello'));
    print('Success! $response');
  } catch (e) {
    print('Error: $e');
  }
}

import 'package:kos_hub/services/ai_service.dart';

void main() async {
  final service = AiService();
  print('Sending message...');
  final result = await service.analyzeText('Saya stres dengan tugas akhir dan fasilitas kos banyak yang rusak.');
  print('Result reply: \${result.reply}');
  print('Is stressed: \${result.isStressed}');
  print('Is technical: \${result.isTechnicalIssue}');
  print('Category: \${result.technicalCategory}');
}

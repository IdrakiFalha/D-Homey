import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// INSTRUKSI UNTUK DEVELOPER:
// Ganti string 'ISI_API_KEY_GEMINI_ANDA_DISINI' dengan API Key
// Gemini yang Anda dapatkan dari https://aistudio.google.com
// ============================================================
const String _geminiApiKey = 'AIzaSyB666Gg1s5grMYNlPPCzgBqqxS7M898daI';

class AiResponse {
  final String reply;
  final bool isStressed;
  final bool isTechnicalIssue;
  final String? technicalCategory;

  AiResponse({
    required this.reply,
    required this.isStressed,
    required this.isTechnicalIssue,
    this.technicalCategory,
  });
}

class HangoutPlan {
  final String title;
  final String time;
  final String location;
  final int goingCount;
  final String imageUrl;

  HangoutPlan({
    required this.title,
    required this.time,
    required this.location,
    required this.goingCount,
    required this.imageUrl,
  });
}

class AiService {
  // ============================================================
  // System Instruction: Kita "memprogram" kepribadian dan
  // format output AI sebelum pengguna mulai berbicara.
  // ============================================================
  static const String _systemInstruction = '''
Kamu adalah "Pipip", teman bicara empatik dan hangat di aplikasi D'Homey untuk para anak kos Indonesia.
Tugasmu adalah mendengarkan curhatan penghuni, memahami perasaan mereka, dan memberikan dukungan positif.

ATURAN PENTING:
1. Selalu balas dalam Bahasa Indonesia yang santai, hangat, dan seperti teman sebaya.
2. JANGAN pernah menyebut nama pengguna, karena percakapan ini anonim.
3. Jika pengguna menunjukkan tanda depresi berat atau pikiran menyakiti diri, sarankan menghubungi Into The Light Indonesia di 119 ext 8 dan sampaikan dengan penuh kepedulian.
4. Kamu HARUS selalu membalas dalam format JSON yang valid (dan HANYA JSON, tanpa teks lain di luar JSON). Format JSON harus seperti ini:
{
  "reply": "Teks balasanmu yang empatik dan hangat di sini.",
  "isStressed": true,
  "isTechnicalIssue": false,
  "technicalCategory": null
}

PANDUAN FIELD JSON:
- "reply": Teks balasan empati atau motivasi (WAJIB).
- "isStressed": true JIKA teks mengandung indikasi stres, burnout, sedih, cemas, atau depresi. false jika positif atau netral.
- "isTechnicalIssue": true JIKA teks mengandung keluhan fasilitas kos (bocor, rusak, listrik mati, dll).
- "technicalCategory": Isi dengan salah satu dari ["Listrik", "Air / Pipa", "Perabotan", "Kebersihan", "Lainnya"] JIKA isTechnicalIssue true. Jika tidak, isi null.

PANDUAN RESPON:
- Jika isStressed true: Berikan respon empatik, validasi perasaan mereka, tawarkan teknik sederhana seperti pernapasan 4-7-8, dan jika berat, rujuk ke bantuan profesional.
- Jika isStressed false: Berikan motivasi positif, apresiasi suasana hati mereka, sarankan aktifitas seru bersama penghuni kos lainnya.
''';

  late GenerativeModel _model;
  late ChatSession _chatSession;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
      ),
    );
    _chatSession = _model.startChat();
  }

  Future<List<Map<String, dynamic>>> initChat(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).collection('ai_chats').orderBy('timestamp').get();
    
    List<Content> history = [];
    List<Map<String, dynamic>> messagesUI = [];
    
    for (var doc in snapshot.docs) {
      final isAi = doc['isAi'] as bool;
      final text = doc['text'] as String;
      
      history.add(isAi ? Content.model([TextPart(text)]) : Content.text(text));
      messagesUI.add({
        'text': text,
        'isAi': isAi,
      });
    }

    _chatSession = _model.startChat(history: history);
    return messagesUI;
  }

  Future<void> saveAiMessage(String uid, String text, bool isAi) async {
    await _db.collection('users').doc(uid).collection('ai_chats').add({
      'text': text,
      'isAi': isAi,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<AiResponse> analyzeText(String userInput, {Uint8List? imageBytes}) async {
    try {
      // ChatSession akan otomatis mengirimkan riwayat percakapan sebelumnya
      final content = imageBytes != null
          ? Content.multi([TextPart(userInput), DataPart('image/jpeg', imageBytes)])
          : Content.text(userInput);
      final response = await _chatSession.sendMessage(content);
      final rawText = response.text;
      
      if (rawText != null) {
        // Parsing JSON dari respon Gemini
        final jsonData = jsonDecode(rawText) as Map<String, dynamic>;
        
        return AiResponse(
          reply: jsonData['reply'] as String? ?? '...',
          isStressed: jsonData['isStressed'] as bool? ?? false,
          isTechnicalIssue: jsonData['isTechnicalIssue'] as bool? ?? false,
          technicalCategory: jsonData['technicalCategory'] as String?,
        );
      } else {
        return _fallbackResponse();
      }
    } catch (e) {
      print('Error Exception memanggil Gemini API: $e');
      return _fallbackResponse();
    }
  }

  Future<List<HangoutPlan>> generateHangoutPlans(Map<String, int> communityInterests) async {
    try {
      if (communityInterests.isEmpty) return [];

      final prompt = '''
Buatkan 2 ide aktivitas hangout kreatif dan menarik berdasarkan data agregat hobi penghuni kos berikut:
$communityInterests

Keterangan angka adalah jumlah orang yang menyukai hobi tersebut. Buatlah aktivitas yang bisa diikuti oleh mereka.
Kembalikan HANYA array JSON dengan format:
[
  {
    "title": "Nama Aktivitas",
    "time": "Waktu (misal: Besok, 06:00)",
    "location": "Lokasi",
    "goingCount": <estimasi_jumlah_orang>,
    "imageUrl": "URL gambar (bebas gunakan placeholder misal: https://images.unsplash.com/photo-1529156069898-49953eb1b5ce?auto=format&fit=crop&w=200&q=80)"
  }
]
''';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.8,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text;
      
      if (rawText != null) {
        final List<dynamic> jsonList = jsonDecode(rawText);
        return jsonList.map((e) => HangoutPlan(
          title: e['title'] ?? 'Aktivitas',
          time: e['time'] ?? 'Segera',
          location: e['location'] ?? 'Kos',
          goingCount: e['goingCount'] ?? 1,
          imageUrl: e['imageUrl'] ?? 'https://images.unsplash.com/photo-1529156069898-49953eb1b5ce?auto=format&fit=crop&w=200&q=80',
        )).toList();
      }
      return [];
    } catch (e) {
      print('Error generate hangout plans: $e');
      return [];
    }
  }

  Future<String> generateAdminInsight(int stressed, int positive) async {
    try {
      final total = stressed + positive;
      if (total == 0) return 'Belum ada data percakapan AI minggu ini.';

      final prompt = '''
Kamu adalah asisten analisis data untuk pemilik kos. 
Berdasarkan log interaksi penghuni dengan bot AI minggu ini:
- $stressed percakapan mengindikasikan stres/burnout.
- $positive percakapan mengindikasikan emosi stabil/positif.

Berikan SATU paragraf singkat (maksimal 3 kalimat) berupa saran kebijakan yang bisa dilakukan oleh pemilik kos atau admin untuk meningkatkan atau mempertahankan kesejahteraan penghuni kos. Gunakan bahasa Indonesia yang profesional namun ramah.
''';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Tidak dapat menghasilkan saran saat ini.';
    } catch (e) {
      print('Error generate admin insight: $e');
      return 'Maaf, gagal memuat saran AI karena masalah koneksi atau konfigurasi.';
    }
  }

  AiResponse _fallbackResponse() {
    return AiResponse(
      // Pesan fallback sedikit diubah untuk memberitahu soal API Key
      reply: 'Maaf, aku lagi gangguan koneksi. (Pastikan limit API Key masih tersedia, ya!)',
      isStressed: false,
      isTechnicalIssue: false,
    );
  }
}

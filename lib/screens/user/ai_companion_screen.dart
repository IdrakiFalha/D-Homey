import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../services/ai_service.dart';
import '../../models/report_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class AiCompanionScreen extends StatefulWidget {
  const AiCompanionScreen({super.key});

  @override
  State<AiCompanionScreen> createState() => _AiCompanionScreenState();
}

class _AiCompanionScreenState extends State<AiCompanionScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final AiService _aiService = AiService();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = true;
  String? _uid;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final user = AuthService().currentUser;
    if (user != null) {
      _uid = user.uid;
      final history = await _aiService.initChat(user.uid);
      if (mounted) {
        setState(() {
          _messages = history;
          if (_messages.isEmpty) {
            final introMsg = AppTranslations.t("Halo! Aku Pipip, AI Companion D'Homey. Gimana harimu di kampus hari ini? Kalau ada yang bikin stres atau ada keluhan di kos, cerita aja ya, ini aman dan anonim kok. 😊", AppState().isEnglish);
            _messages.add({'text': introMsg, 'isAi': true});
            _aiService.saveAiMessage(_uid!, introMsg, true);
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _uid == null) return;

    setState(() {
      _messages.add({'text': text, 'isAi': false});
      _isTyping = true;
    });
    
    _chatController.clear();
    _scrollToBottom();
    await _aiService.saveAiMessage(_uid!, text, false);
    
    final aiResponse = await _aiService.analyzeText(text);

    await ReportService().logAnonymousMood(aiResponse.isStressed);
    await ReportService().logPersonalMood(_uid!, aiResponse.isStressed);

    if (aiResponse.isTechnicalIssue) {
      final userData = await AuthService().getUserData(_uid!);
      final report = ReportModel(
        id: '',
        reporterUid: _uid!,
        reporterName: userData?['name'] ?? AppTranslations.t('Penghuni', AppState().isEnglish),
        category: aiResponse.technicalCategory ?? 'Lainnya',
        description: 'Laporan otomatis dari curhatan AI: "\$text"',
        createdAt: DateTime.now(),
      );
      await ReportService().createReport(report);
    }

    if (mounted) {
      setState(() {
        _messages.add({'text': aiResponse.reply, 'isAi': true});
        _aiService.saveAiMessage(_uid!, aiResponse.reply, true);
        
        if (aiResponse.isTechnicalIssue) {
           final sysMsg = AppTranslations.t('🛠️ (Sistem) Keluhan teknis kamu telah diteruskan secara otomatis ke Admin Kos.', AppState().isEnglish);
           _messages.add({'text': sysMsg, 'isAi': true});
           _aiService.saveAiMessage(_uid!, sysMsg, true);
        }
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _shareLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS tidak aktif.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak permanen.')));
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final locationUrl = 'https://www.google.com/maps/dir/?api=1&destination=${position.latitude},${position.longitude}';
    final locationMsg = '${AppTranslations.t("Lokasi saya saat ini:", AppState().isEnglish)}\n$locationUrl';
    
    _chatController.text = locationMsg;
    _sendMessage();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null && _uid != null) {
      try {
        final bytes = await File(path).readAsBytes();
        final base64Audio = base64Encode(bytes);
        final audioMsg = '[AUDIO_BASE64] $base64Audio';
        
        setState(() {
          _messages.add({'text': audioMsg, 'isAi': false});
          _isTyping = true;
        });
        _scrollToBottom();
        await _aiService.saveAiMessage(_uid!, audioMsg, false);
        
        final aiResponse = await _aiService.analyzeText("Pengguna mengirim pesan suara. Beritahu mereka bahwa Anda adalah AI teks dan hanya bisa membaca teks, namun Anda siap mendengarkan curhatan mereka jika diketik.");
        
        setState(() {
          _messages.add({'text': aiResponse.reply, 'isAi': true});
          _isTyping = false;
        });
        _scrollToBottom();
        await _aiService.saveAiMessage(_uid!, aiResponse.reply, true);
        
      } catch (e) {
        print('Error processing voice note: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pesan suara.')));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 70);
      if (image != null && _uid != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final imageMsg = '[IMAGE_BASE64] $base64Image';
        setState(() {
          _messages.add({'text': imageMsg, 'isAi': false});
          _isTyping = true;
        });
        _scrollToBottom();
        await _aiService.saveAiMessage(_uid!, imageMsg, false);
        final aiResponse = await _aiService.analyzeText("Tolong deskripsikan dan berikan pendapatmu mengenai gambar ini secara ramah.", imageBytes: bytes);
        setState(() {
          _messages.add({'text': aiResponse.reply, 'isAi': true});
          _isTyping = false;
        });
        _scrollToBottom();
        await _aiService.saveAiMessage(_uid!, aiResponse.reply, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil gambar.')));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachOption(Icons.camera_alt_rounded, 'Kamera', Colors.blue, () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
                _buildAttachOption(Icons.image_rounded, 'Galeri', Colors.purple, () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                _buildAttachOption(Icons.location_on_rounded, 'Lokasi', Colors.green, () { Navigator.pop(context); _shareLocation(); }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.secondary,
                      radius: 18,
                      child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppTranslations.t('Pipip (AI)', isEnglish), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(_isTyping ? AppTranslations.t('sedang mengetik...', isEnglish) : AppTranslations.t('Selalu online', isEnglish), style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.normal)),
                  ],
                ),
              ],
            ),
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(msg['text'], msg['isAi'], context);
                  },
                ),
              ),
              
              Container(
                padding: EdgeInsets.only(
                  left: 12, 
                  right: 12, 
                  top: 12, 
                  bottom: MediaQuery.of(context).padding.bottom + 12
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textLight),
                      onPressed: _showAttachmentOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendMessage(),
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: _isRecording ? AppTranslations.t('Merekam suara...', isEnglish) : AppTranslations.t('Ketik pesanmu...', isEnglish),
                          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onLongPress: _startRecording,
                      onLongPressUp: _stopRecording,
                      onTap: () {
                        if (_chatController.text.isNotEmpty) {
                          _sendMessage();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.t('Tahan untuk merekam suara', isEnglish))));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.redAccent : AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? Colors.redAccent : AppTheme.primary).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Icon(_chatController.text.isEmpty && !_isRecording ? Icons.mic_rounded : Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildChatBubble(String text, bool isAi, BuildContext context) {
    final isAudio = text.startsWith('[AUDIO]');
    final isAudioBase64 = text.startsWith('[AUDIO_BASE64]');
    final isLocation = text.contains('https://www.google.com/maps/dir/?api=1&destination=');
    final isImageBase64 = text.startsWith('[IMAGE_BASE64]');
    Widget bubbleContent;
    
    if (isImageBase64) {
      final base64String = text.substring(14).trim();
      try {
        final bytes = base64Decode(base64String);
        bubbleContent = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: 200,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        bubbleContent = const Text('Gagal memuat gambar');
      }
    } else if (isAudio) {
      final url = text.substring(7).trim();
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_filled, size: 32, color: isAi ? AppTheme.primary : Colors.white),
            onPressed: () {
              _audioPlayer.play(UrlSource(url));
            },
          ),
          Text('Voice Note (URL)', style: TextStyle(color: isAi ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white)),
        ],
      );
    } else if (isAudioBase64) {
      final base64String = text.substring(14).trim();
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_filled, size: 32, color: isAi ? AppTheme.primary : Colors.white),
            onPressed: () {
              try {
                final bytes = base64Decode(base64String);
                _audioPlayer.play(BytesSource(bytes));
              } catch (e) {
                print("Error playing audio: $e");
              }
            },
          ),
          Text('Voice Note', style: TextStyle(color: isAi ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white)),
        ],
      );
    } else if (isLocation) {
      final urlStartIndex = text.indexOf('https://');
      final url = text.substring(urlStartIndex).trim();
      final textBeforeUrl = text.substring(0, urlStartIndex).trim();
      
      bubbleContent = Column(
        crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (textBeforeUrl.isNotEmpty) Text(textBeforeUrl, style: TextStyle(color: isAi ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white, fontSize: 15)),
          if (textBeforeUrl.isNotEmpty) const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.map, color: isAi ? Colors.white : AppTheme.primary),
            label: Text('Buka di Peta (Rute)', style: TextStyle(color: isAi ? Colors.white : AppTheme.primary)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAi ? AppTheme.primary : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      );
    } else {
      bubbleContent = Text(
        text,
        style: TextStyle(
          color: isAi ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white,
          height: 1.5,
          fontSize: 15,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAi) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.secondary,
              radius: 14,
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isAi ? Theme.of(context).cardColor : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
                  bottomRight: isAi ? const Radius.circular(20) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
                border: isAi ? Border.all(color: Theme.of(context).dividerColor, width: 1) : null,
              ),
              child: bubbleContent,
            ),
          ),
          
          if (!isAi) const SizedBox(width: 22),
        ],
      ),
    );
  }
}

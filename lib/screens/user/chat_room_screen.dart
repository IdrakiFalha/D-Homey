import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import 'call_screen.dart';
import 'video_call_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatRoomScreen extends StatefulWidget {
  final String receiverUserId;
  final String receiverUserName;
  final String? receiverBase64Image;
  final bool isGroup;

  const ChatRoomScreen({
    super.key,
    required this.receiverUserId,
    required this.receiverUserName,
    this.receiverBase64Image,
    this.isGroup = false,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;

  bool _isSearching = false;
  String _searchQuery = '';
  bool _isMuted = false;

  final List<Color> _themeColors = [
    AppTheme.primary, // Default Yellow/Gold
    const Color(0xFF0077B6), // Ocean Blue
    const Color(0xFFD81B60), // Sakura Pink
  ];

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _showProfileDialog() async {
    if (widget.isGroup) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.receiverUserId).get();
    if (!userDoc.exists) return;
    final userData = userDoc.data()!;

    final roomQuery = await FirebaseFirestore.instance.collection('rooms').where('occupantUid', isEqualTo: widget.receiverUserId).get();
    String roomNumber = 'Belum punya kamar';
    if (roomQuery.docs.isNotEmpty) {
      roomNumber = roomQuery.docs.first['roomNumber'];
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(widget.receiverBase64Image, size: 80, themeColor: AppTheme.primary),
            const SizedBox(height: 16),
            Text(widget.receiverUserName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 8),
            Text(userData['email'] ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _buildProfileInfoRow(Icons.meeting_room, 'Kamar', roomNumber),
            const SizedBox(height: 12),
            _buildProfileInfoRow(Icons.phone, 'HP Darurat', userData['emergencyContactPhone'] ?? '-'),
            const SizedBox(height: 12),
            _buildProfileInfoRow(Icons.location_city, 'Asal', userData['origin'] ?? 'Tidak diketahui'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Hobi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (userData['interests'] as List<dynamic>? ?? []).map((hobby) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Text(hobby.toString(), style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            if ((userData['interests'] as List<dynamic>? ?? []).isEmpty)
              const Text('Belum ada hobi yang ditambahkan.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
          ],
        )
      ],
    );
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      if (widget.isGroup) {
        await _chatService.sendGroupMessage(text);
      } else {
        await _chatService.sendMessage(widget.receiverUserId, text);
      }
      _messageController.clear();
      setState(() {});
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
    
    _messageController.text = locationMsg;
    sendMessage();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final imageMsg = '[IMAGE_BASE64] $base64Image';
        
        if (widget.isGroup) {
          await _chatService.sendGroupMessage(imageMsg);
        } else {
          await _chatService.sendMessage(widget.receiverUserId, imageMsg);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil gambar.')));
    }
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
    if (path != null) {
      try {
        final bytes = await File(path).readAsBytes();
        final base64Audio = base64Encode(bytes);
        final audioMsg = '[AUDIO_BASE64] $base64Audio';
        
        _messageController.text = audioMsg;
        sendMessage();
        
      } catch (e) {
        print('Error processing voice note: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memproses pesan suara.')));
      }
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.t('Konfirmasi', AppState().isEnglish)),
        content: Text(AppTranslations.t('Apakah Anda yakin ingin membersihkan obrolan ini?', AppState().isEnglish)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.t('Batal', AppState().isEnglish))),
          TextButton(
            onPressed: () {
              _chatService.clearChat(widget.receiverUserId, isGroup: widget.isGroup);
              Navigator.pop(context);
            },
            child: Text(AppTranslations.t('Ya, Bersihkan', AppState().isEnglish), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmBlock(bool isCurrentlyBlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.t('Konfirmasi', AppState().isEnglish)),
        content: Text(AppTranslations.t(isCurrentlyBlocked ? 'Apakah Anda yakin ingin membuka blokir kontak ini?' : 'Apakah Anda yakin ingin memblokir kontak ini?', AppState().isEnglish)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.t('Batal', AppState().isEnglish))),
          TextButton(
            onPressed: () {
              _chatService.toggleBlockUser(widget.receiverUserId);
              Navigator.pop(context);
            },
            child: Text(AppTranslations.t(isCurrentlyBlocked ? 'Ya, Buka' : 'Ya, Blokir', AppState().isEnglish), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.t('Konfirmasi', AppState().isEnglish)),
        content: Text(AppTranslations.t('Apakah Anda yakin ingin menghapus pesan ini?', AppState().isEnglish)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppTranslations.t('Batal', AppState().isEnglish))),
          TextButton(
            onPressed: () {
              _chatService.deleteMessage(widget.receiverUserId, messageId, isGroup: widget.isGroup);
              Navigator.pop(context);
            },
            child: Text(AppTranslations.t('Ya, Hapus', AppState().isEnglish), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppTranslations.t('Pilih Tema Obrolan', AppState().isEnglish), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(0, Colors.amber),
                  _buildThemeOption(1, const Color(0xFF0077B6)),
                  _buildThemeOption(2, const Color(0xFFD81B60)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(int index, Color color) {
    return GestureDetector(
      onTap: () {
        _chatService.updateChatTheme(widget.receiverUserId, index, isGroup: widget.isGroup);
        Navigator.pop(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, _) {
        return StreamBuilder<DocumentSnapshot>(
          stream: widget.isGroup ? _chatService.getGroupChatStream() : _chatService.getChatRoomStream(widget.receiverUserId),
          builder: (context, roomSnapshot) {
            int currentThemeIndex = 0;
            if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
              var data = roomSnapshot.data!.data() as Map<String, dynamic>;
              currentThemeIndex = data['themeIndex'] ?? 0;
            }
            Color themeColor = _themeColors[currentThemeIndex];

            bool isDefaultTheme = currentThemeIndex == 0;

            return StreamBuilder<bool>(
              stream: widget.isGroup ? Stream.value(false) : _chatService.isUserBlockedStream(widget.receiverUserId),
              builder: (context, blockSnapshot) {
                bool isBlocked = blockSnapshot.data ?? false;
                
                return StreamBuilder<bool>(
                  stream: widget.isGroup ? Stream.value(false) : _chatService.amIBlockedStream(widget.receiverUserId),
                  builder: (context, amIBlockedSnapshot) {
                    bool amIBlocked = amIBlockedSnapshot.data ?? false;

                    return Scaffold(
                      appBar: AppBar(
                        title: _isSearching
                          ? TextField(
                              autofocus: true,
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              decoration: InputDecoration(
                                hintText: AppTranslations.t('Pencarian...', isEnglish),
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val.toLowerCase());
                              },
                            )
                          : InkWell(
                              onTap: _showProfileDialog,
                              child: Row(
                                children: [
                                  _buildAvatar(widget.receiverBase64Image, isGroup: widget.isGroup, themeColor: themeColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.receiverUserName,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isDefaultTheme ? themeColor : Colors.white, fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        backgroundColor: isDefaultTheme ? Theme.of(context).scaffoldBackgroundColor : themeColor,
                        elevation: 1,
                        iconTheme: IconThemeData(color: isDefaultTheme ? themeColor : Colors.white),
                        actions: [
                          if (_isSearching)
                            IconButton(
                              icon: Icon(Icons.close, color: isDefaultTheme ? themeColor : Colors.white),
                              onPressed: () => setState(() { _isSearching = false; _searchQuery = ''; }),
                            )
                          else ...[
                            if (!widget.isGroup) ...[
                              IconButton(
                                icon: Icon(Icons.phone, color: isDefaultTheme ? themeColor : Colors.white),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(userName: widget.receiverUserName, base64Image: widget.receiverBase64Image)));
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.videocam, color: isDefaultTheme ? themeColor : Colors.white),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(userName: widget.receiverUserName, base64Image: widget.receiverBase64Image)));
                                },
                              ),
                            ],
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: isDefaultTheme ? themeColor : Colors.white),
                              onSelected: (value) async {
                                if (value == 'search') {
                                  setState(() => _isSearching = true);
                                } else if (value == 'clear') {
                                  _confirmClearChat();
                                } else if (value == 'block') {
                                  _confirmBlock(isBlocked);
                                } else if (value == 'theme') {
                                  _showThemePicker();
                                } else if (value == 'mute') {
                                  setState(() => _isMuted = !_isMuted); 
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'search', child: Text(AppTranslations.t('Cari Pesan', isEnglish))),
                                PopupMenuItem(value: 'clear', child: Text(AppTranslations.t('Bersihkan Obrolan', isEnglish))),
                                if (!widget.isGroup) PopupMenuItem(value: 'block', child: Text(AppTranslations.t(isBlocked ? 'Buka Blokir Kontak' : 'Blokir Kontak', isEnglish))),
                                PopupMenuItem(value: 'theme', child: Text(AppTranslations.t('Pilih Tema Obrolan', isEnglish))),
                                PopupMenuItem(value: 'mute', child: Text(AppTranslations.t('Senyapkan Notifikasi', isEnglish) + (_isMuted ? ' (On)' : ''))),
                              ],
                            ),
                          ],
                        ],
                      ),
                      backgroundColor: isDefaultTheme 
                          ? Theme.of(context).scaffoldBackgroundColor 
                          : Color.alphaBlend(
                              themeColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.08), 
                              Theme.of(context).scaffoldBackgroundColor
                            ),
                      body: Column(
                        children: [
                          Expanded(child: _buildMessageList(themeColor)),
                          _buildMessageInput(isEnglish, themeColor, isBlocked, amIBlocked),
                        ],
                      ),
                    );
                  }
                );
              }
            );
          }
        );
      }
    );
  }

  Widget _buildAvatar(String? base64, {bool isGroup = false, double size = 40, Color? themeColor}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isGroup ? (themeColor ?? AppTheme.primary) : AppTheme.secondary,
        shape: BoxShape.circle,
        image: !isGroup && base64 != null && base64.isNotEmpty
            ? DecorationImage(
                image: MemoryImage(base64Decode(base64)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: isGroup
          ? Icon(Icons.group, color: Colors.white, size: size * 0.6)
          : (base64 == null || base64.isEmpty)
              ? Icon(Icons.person, color: Colors.white, size: size * 0.7)
              : null,
    );
  }

  Widget _buildMessageList(Color themeColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.isGroup 
          ? _chatService.getGroupMessagesStream() 
          : _chatService.getMessagesStream(widget.receiverUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;
        if (_isSearching && _searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final text = (doc.data() as Map<String, dynamic>)['message'] as String;
            return text.toLowerCase().contains(_searchQuery);
          }).toList();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 20, top: 16),
          children: docs.map((document) => _buildMessageItem(document, themeColor)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document, Color themeColor) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;
    var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
        
    var bgColor = isCurrentUser ? themeColor.withOpacity(0.2) : Theme.of(context).cardColor;
    var textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    final text = data['message'] as String;
    final isAudio = text.startsWith('[AUDIO]');
    final isAudioBase64 = text.startsWith('[AUDIO_BASE64]');
    final isImageBase64 = text.startsWith('[IMAGE_BASE64]');
    final isVideoUrl = text.startsWith('[VIDEO_URL]');
    final isLocation = text.contains('https://www.google.com/maps/dir/?api=1&destination=');
    Widget bubbleContent;
    
    if (isVideoUrl) {
      final url = text.substring(12).trim();
      bubbleContent = Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.video_library, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.play_arrow, color: isCurrentUser ? themeColor : Colors.white),
            label: Text('Tonton Video', style: TextStyle(color: isCurrentUser ? themeColor : Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentUser ? Colors.white : themeColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )
        ],
      );
    } else if (isAudio) {
      final url = text.substring(7).trim();
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_filled, size: 32, color: themeColor),
            onPressed: () {
              _audioPlayer.play(UrlSource(url));
            },
          ),
          Text('Voice Note (URL)', style: TextStyle(color: textColor)),
        ],
      );
    } else if (isAudioBase64) {
      final base64String = text.substring(14).trim();
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_circle_filled, size: 32, color: themeColor),
            onPressed: () {
              try {
                final bytes = base64Decode(base64String);
                _audioPlayer.play(BytesSource(bytes));
              } catch (e) {
                print("Error playing audio: $e");
              }
            },
          ),
          Text('Voice Note', style: TextStyle(color: textColor)),
        ],
      );
    } else if (isImageBase64) {
      final base64String = text.substring(15).trim();
      bubbleContent = GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
            appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
            backgroundColor: Colors.black,
            body: Center(child: InteractiveViewer(child: Image.memory(base64Decode(base64String)))),
          )));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(base64String),
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
          ),
        ),
      );
    } else if (isLocation) {
      final urlStartIndex = text.indexOf('https://');
      final url = text.substring(urlStartIndex).trim();
      final textBeforeUrl = text.substring(0, urlStartIndex).trim();
      
      bubbleContent = Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (textBeforeUrl.isNotEmpty) Text(textBeforeUrl, style: TextStyle(color: textColor, fontSize: 15)),
          if (textBeforeUrl.isNotEmpty) const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.map, color: isCurrentUser ? themeColor : Colors.white),
            label: Text('Buka di Peta (Rute)', style: TextStyle(color: isCurrentUser ? themeColor : Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentUser ? Colors.white : themeColor,
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
        style: TextStyle(color: textColor, fontSize: 15),
      );
    }

    Timestamp? timestamp = data['timestamp'] as Timestamp?;
    String timeStr = '';
    if (timestamp != null) {
      timeStr = DateFormat('HH:mm').format(timestamp.toDate());
    }

    return GestureDetector(
      onLongPress: () {
        if (isCurrentUser) {
          _confirmDelete(document.id);
        }
      },
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              _buildSenderAvatar(data['senderId']),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isCurrentUser ? const Radius.circular(16) : const Radius.circular(4),
                    bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ],
                  border: !isCurrentUser ? Border.all(color: Theme.of(context).dividerColor) : Border.all(color: themeColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    bubbleContent,
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(null, size: 24, themeColor: themeColor), 
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar(String senderId) {
    if (!widget.isGroup && widget.receiverUserId == senderId) {
      return _buildAvatar(widget.receiverBase64Image, size: 28);
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return _buildAvatar(userData['profileImageBase64'], size: 28);
        }
        return _buildAvatar(null, size: 28);
      },
    );
  }

  Widget _buildMessageInput(bool isEnglish, Color themeColor, bool isBlocked, bool amIBlocked) {
    if (isBlocked || amIBlocked) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        color: Theme.of(context).cardColor,
        alignment: Alignment.center,
        child: Text(
          AppTranslations.t('Anda telah memblokir kontak ini. Buka blokir untuk mengirim pesan.', isEnglish),
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ]
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.textLight),
            onSelected: (val) {
              if (val == 'camera') _pickImage(ImageSource.camera);
              else if (val == 'gallery') _pickImage(ImageSource.gallery);
              else if (val == 'location') _shareLocation();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'camera', child: Row(children: [const Icon(Icons.camera_alt), const SizedBox(width: 8), Text(AppTranslations.t('Kamera (Foto)', isEnglish))])),
              PopupMenuItem(value: 'gallery', child: Row(children: [const Icon(Icons.image), const SizedBox(width: 8), Text(AppTranslations.t('Galeri (Foto)', isEnglish))])),
              PopupMenuItem(value: 'location', child: Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Text(AppTranslations.t('Lokasi', isEnglish))])),
            ],
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (val) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: _isRecording ? AppTranslations.t('Merekam suara...', isEnglish) : AppTranslations.t('Ketik pesanmu...', isEnglish),
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: _startRecording,
            onLongPressUp: _stopRecording,
            onTap: () {
              if (_messageController.text.isNotEmpty) {
                sendMessage();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppTranslations.t('Tahan untuk merekam suara', isEnglish))));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.redAccent : themeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.redAccent : themeColor).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              child: Icon(_messageController.text.isEmpty && !_isRecording ? Icons.mic_rounded : Icons.send_rounded, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }
}

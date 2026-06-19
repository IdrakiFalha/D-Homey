import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'ai_companion_screen.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';
import '../../utils/app_theme.dart';

class CommunityChatScreen extends StatefulWidget {
  const CommunityChatScreen({super.key});

  @override
  State<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends State<CommunityChatScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: _buildMainContent(isEnglish, context),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiCompanionScreen()));
            },
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            label: Text(AppTranslations.t('Chat with Pipip', isEnglish), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          ),
        );
      }
    );
  }

  Widget _buildMainContent(bool isEnglish, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Text(
            AppTranslations.t('Chat', isEnglish),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        // Grup Komunitas (Always on top)
        _buildGroupChatTile(isEnglish, context),
        Divider(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), thickness: 1, indent: 24, endIndent: 24),
        // User 1-on-1 Chats
        Expanded(child: _buildUserList(isEnglish, context)),
      ],
    );
  }

  Widget _buildGroupChatTile(bool isEnglish, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatService.getGroupChatStream(),
      builder: (context, snapshot) {
        String lastMessage = AppTranslations.t('Mulai obrolan di grup!', isEnglish);
        int streakCount = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          lastMessage = data['lastMessage'] ?? lastMessage;
          streakCount = data['streakCount'] ?? 0;
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(
                  receiverUserId: 'community_group',
                  receiverUserName: AppTranslations.t('Grup Komunitas Kos', isEnglish),
                  isGroup: true,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.t('Grup Komunitas Kos', isEnglish),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (streakCount > 0) _buildDynamicStreakFlame(streakCount),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserList(bool isEnglish, BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUsersWithChatStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        int onlineCount = snapshot.data?.length ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$onlineCount ${AppTranslations.t('orang terdaftar', isEnglish)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (snapshot.data == null || snapshot.data!.isEmpty)
              Expanded(child: Center(child: Text(AppTranslations.t('Belum ada pengguna lain.', isEnglish), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: snapshot.data!.map<Widget>((userData) => _buildUserListItem(userData, isEnglish, context)).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserListItem(Map<String, dynamic> userData, bool isEnglish, BuildContext context) {
    String? base64Img = userData['profileImageBase64'];
    String lastMessage = userData['lastMessage'] ?? AppTranslations.t('Mulai percakapan baru', isEnglish);
    if (lastMessage.isEmpty) {
      lastMessage = AppTranslations.t('Mulai percakapan baru', isEnglish);
    }
    int streakCount = userData['streakCount'] ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              receiverUserId: userData['uid'],
              receiverUserName: userData['name'],
              receiverBase64Image: base64Img,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            _buildAvatar(base64Img, context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary.withOpacity(0.8), fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (streakCount > 0) _buildDynamicStreakFlame(streakCount),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? base64, BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF374151) : const Color(0xFFDFE5E7),
        shape: BoxShape.circle,
        image: base64 != null && base64.isNotEmpty
            ? DecorationImage(
                image: MemoryImage(base64Decode(base64)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: base64 == null || base64.isEmpty
          ? const Icon(Icons.person, color: Colors.white, size: 36)
          : null,
    );
  }

  Widget _buildDynamicStreakFlame(int streak) {
    Color flameColor;
    if (streak >= 200) {
      flameColor = Colors.purpleAccent; 
    } else if (streak >= 100) {
      flameColor = Colors.pinkAccent;
    } else if (streak >= 10) {
      flameColor = Colors.blueAccent;
    } else {
      flameColor = Colors.deepOrange;
    }

    return Row(
      children: [
        Text(
          '$streak',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: flameColor),
        ),
        Icon(Icons.local_fire_department, color: flameColor, size: 28),
      ],
    );
  }
}

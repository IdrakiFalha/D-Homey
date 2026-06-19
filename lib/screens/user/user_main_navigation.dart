import 'package:flutter/material.dart';
import 'home_agenda_screen.dart';
import 'ai_companion_screen.dart';
import 'community_chat_screen.dart';
import 'profile_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_translations.dart';
import '../../utils/app_state.dart';

class UserMainNavigation extends StatefulWidget {
  const UserMainNavigation({super.key});

  @override
  State<UserMainNavigation> createState() => _UserMainNavigationState();
}

class _UserMainNavigationState extends State<UserMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeAgendaScreen(),
    const CommunityChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState().isEnglishNotifier,
      builder: (context, isEnglish, child) {
        return Scaffold(
          body: _pages[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9CA3AF) : AppTheme.secondary,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            elevation: 10,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_today_outlined),
                activeIcon: const Icon(Icons.calendar_today),
                label: AppTranslations.t('Agenda', isEnglish),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                activeIcon: const Icon(Icons.chat_bubble),
                label: AppTranslations.t('Chat', isEnglish),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: AppTranslations.t('Profil', isEnglish),
              ),
            ],
          ),
        );
      }
    );
  }
}

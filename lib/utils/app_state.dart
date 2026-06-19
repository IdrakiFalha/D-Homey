import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> isEnglishNotifier = ValueNotifier(false); // false = Indonesia, true = English

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final isEnglish = prefs.getBool('isEnglish') ?? false;
    
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    isEnglishNotifier.value = isEnglish;
  }

  Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }

  Future<void> toggleLanguage(bool isEnglish) async {
    isEnglishNotifier.value = isEnglish;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isEnglish', isEnglish);
  }

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;
  bool get isEnglish => isEnglishNotifier.value;
}

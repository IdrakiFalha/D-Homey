import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class CallScreen extends StatefulWidget {
  final String userName;
  final String? base64Image;

  const CallScreen({super.key, required this.userName, this.base64Image});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2B3C), // WA dark background style for calls
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.lock, color: Colors.white54, size: 16),
            const SizedBox(height: 8),
            const Text('Panggilan suara terenkripsi', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 32),
            Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: _controller,
              child: const Text('Berdering...', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ),
            const Spacer(),
            // Avatar
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDFE5E7),
                image: widget.base64Image != null && widget.base64Image!.isNotEmpty
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(widget.base64Image!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.base64Image == null || widget.base64Image!.isEmpty
                  ? const Icon(Icons.person, size: 100, color: Colors.white)
                  : null,
            ),
            const Spacer(),
            // Call Actions
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2B3A4A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.volume_up, Colors.white54, () {}),
                  _buildActionButton(Icons.videocam, Colors.white54, () {}),
                  _buildActionButton(Icons.mic_off, Colors.white54, () {}),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

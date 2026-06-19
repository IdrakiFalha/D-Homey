import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String userName;
  final String? base64Image;

  const VideoCallScreen({super.key, required this.userName, this.base64Image});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await [Permission.camera, Permission.microphone].request();
    if (mounted) {
      setState(() {
        _hasPermissions = status[Permission.camera]!.isGranted && status[Permission.microphone]!.isGranted;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Typical video call background before answering
      body: SafeArea(
        child: Stack(
          children: [
            // Mock background showing local "camera" view (blur simulation)
            Positioned.fill(
              child: _hasPermissions 
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2A2D34), Color(0xFF13151A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const Center(child: Icon(Icons.videocam, color: Colors.white24, size: 120)),
                    )
                  : const Center(child: Text('Meminta Izin Kamera...', style: TextStyle(color: Colors.white54))),
            ),
            
            // Header Info
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDFE5E7),
                      border: Border.all(color: Colors.white24, width: 2),
                      image: widget.base64Image != null && widget.base64Image!.isNotEmpty
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(widget.base64Image!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.base64Image == null || widget.base64Image!.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _controller,
                    child: const Text('Berdering...', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ),
                ],
              ),
            ),
            
            // Call Actions
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.switch_camera, Colors.white, () {}),
                  _buildActionButton(Icons.videocam_off, Colors.white, () {}),
                  _buildActionButton(Icons.mic_off, Colors.white, () {}),
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
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}

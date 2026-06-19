import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  Future<void> _reauthenticateAndSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;
    final oldPassword = _oldPasswordController.text;

    if (oldPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan password lama untuk konfirmasi')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);

      bool isChanged = false;

      // Update Email
      final newEmail = _emailController.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        isChanged = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verifikasi telah dikirim ke email baru.')));
        }
      }

      // Update Password
      final newPassword = _newPasswordController.text;
      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          throw Exception('Password baru minimal 6 karakter');
        }
        await user.updatePassword(newPassword);
        isChanged = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
        }
      }

      if (!isChanged) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada perubahan yang dilakukan.')));
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privasi & Keamanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ubah Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(hintText: 'Email Baru'),
            ),
            const SizedBox(height: 24),
            
            const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Kata Sandi Baru (kosongkan jika tidak ingin diubah)'),
            ),
            const SizedBox(height: 32),
            
            const Divider(),
            const SizedBox(height: 16),
            const Text('Konfirmasi Keamanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Silakan masukkan kata sandi lama Anda untuk memverifikasi perubahan.', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Kata Sandi Saat Ini (Wajib)'),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Simpan Perubahan',
              onPressed: _reauthenticateAndSave,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

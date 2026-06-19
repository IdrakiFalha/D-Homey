import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';

class EditResidentScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> initialData;

  const EditResidentScreen({super.key, required this.uid, required this.initialData});

  @override
  State<EditResidentScreen> createState() => _EditResidentScreenState();
}

class _EditResidentScreenState extends State<EditResidentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _emNameController;
  late TextEditingController _emPhoneController;
  late TextEditingController _originController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _emailController = TextEditingController(text: widget.initialData['email']);
    _emNameController = TextEditingController(text: widget.initialData['emergencyContactName']);
    _emPhoneController = TextEditingController(text: widget.initialData['emergencyContactPhone']);
    _originController = TextEditingController(text: widget.initialData['origin'] ?? 'Tidak diketahui');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emNameController.dispose();
    _emPhoneController.dispose();
    _originController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'name': _nameController.text.trim(),
        'emergencyContactName': _emNameController.text.trim(),
        'emergencyContactPhone': _emPhoneController.text.trim(),
        'origin': _originController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil diperbarui')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Data Penghuni', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Informasi Dasar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                readOnly: true, // Email terkait Auth, sebaiknya tidak diubah sembarangan via Firestore
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(labelText: 'Asal Daerah', prefixIcon: Icon(Icons.location_city)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 32),
              const Text('Kontak Darurat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emNameController,
                decoration: const InputDecoration(labelText: 'Nama Kontak Darurat', prefixIcon: Icon(Icons.family_restroom)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emPhoneController,
                decoration: const InputDecoration(labelText: 'No. HP Darurat', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 48),
              CustomButton(
                text: 'Simpan Perubahan',
                onPressed: _saveData,
                isLoading: _isLoading,
              )
            ],
          ),
        ),
      ),
    );
  }
}

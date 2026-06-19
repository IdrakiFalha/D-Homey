import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _originController = TextEditingController();
  
  String? _base64Image;
  List<String> _selectedInterests = [];
  bool _isLoading = true;
  bool _isSaving = false;
  final AuthService _authService = AuthService();
  
  final List<String> _availableInterests = [
    'Olahraga', 'Gaming', 'Musik', 'Nonton Film', 
    'Belajar Bareng', 'Kuliner', 'Nongkrong', 'Ngoding'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emergencyNameController.text = data['emergencyContactName'] ?? '';
          _emergencyPhoneController.text = data['emergencyContactPhone'] ?? '';
          _emergencyRelationController.text = data['emergencyRelation'] ?? '';
          _bloodTypeController.text = data['bloodType'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _originController.text = data['origin'] ?? '';
          _base64Image = data['profileImageBase64'];
          if (data['interests'] != null) {
            _selectedInterests = List<String>.from(data['interests']);
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source, maxWidth: 400, imageQuality: 70);
      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        setState(() {
          _base64Image = base64Encode(imageBytes);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              title: const Text('Dari Galeri', style: TextStyle(color: AppTheme.primary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Kamera', style: TextStyle(color: AppTheme.primary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final success = await _authService.updateUserProfile(
      name: _nameController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyRelation: _emergencyRelationController.text.trim(),
      profileImageBase64: _base64Image,
      interests: _selectedInterests,
      bloodType: _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.trim(),
      origin: _originController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
      Navigator.pop(context); // Kembali ke pengaturan
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui profil')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Edit Profil')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.secondary)),
      );
    }

    Widget imageWidget;
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      imageWidget = Image.memory(
        base64Decode(_base64Image!),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else {
      // WA-style silhouette
      imageWidget = Container(
        width: 120,
        height: 120,
        color: const Color(0xFFDFE5E7), // Typical WA grey background
        child: const Icon(Icons.person, size: 80, color: Colors.white),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    ClipOval(child: imageWidget),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImagePickerModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Nama lengkap Anda'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('Kontak Darurat (Nama)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(hintText: 'Nama kontak darurat'),
              ),
              const SizedBox(height: 24),
              
              const Text('Asal Daerah', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(hintText: 'Kota Asal (Mis. Jakarta, Bandung)'),
              ),
              const SizedBox(height: 24),
              
              const Text('Kontak Darurat (Telepon)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emergencyPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Nomor telepon darurat'),
              ),
              const SizedBox(height: 24),

              const Text('Hubungan dengan Kontak Darurat', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emergencyRelationController,
                decoration: const InputDecoration(hintText: 'Contoh: Ayah, Ibu, Wali'),
              ),
              const SizedBox(height: 24),
              
              const Text('Info Medis & Kesehatan', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bloodTypeController,
                decoration: const InputDecoration(hintText: 'Golongan Darah (Contoh: A, B, O, AB)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(hintText: 'Alergi / Riwayat Penyakit (Contoh: Debu)'),
              ),
              const SizedBox(height: 24),

              const Text('Hobi / Minat (Matchmaker)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('Pilih hobi yang kamu suka untuk mendapatkan saran teman hangout dari AI!', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    selectedColor: AppTheme.primary.withOpacity(0.2),
                    checkmarkColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(interest);
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),
              
              CustomButton(
                text: 'Simpan Perubahan',
                onPressed: _saveProfile,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

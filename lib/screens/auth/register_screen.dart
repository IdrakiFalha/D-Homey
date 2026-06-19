import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/responsive_layout.dart';
import '../../utils/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Kontak Darurat (Opsional saat daftar)
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  // Info Medis (Opsional)
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _originController = TextEditingController();
  
  String _selectedRole = 'penghuni';
  bool _isLoading = false;
  bool _obscurePassword = true;

  List<RoomModel> _availableRooms = [];
  RoomModel? _selectedRoom;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  Future<void> _fetchAvailableRooms() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'Tersedia')
          .get();
      if (mounted) {
        setState(() {
          _availableRooms = snapshot.docs.map((doc) => RoomModel.fromMap(doc.data(), doc.id)).toList();
        });
      }
    } catch (e) {
      print('Error fetching rooms: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _originController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await AuthService().registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      role: _selectedRole,
      bloodType: _bloodTypeController.text.trim().isEmpty ? '-' : _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.trim().isEmpty ? '-' : _allergiesController.text.trim(),
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyRelation: 'Keluarga',
      origin: _originController.text.trim().isEmpty ? 'Tidak diketahui' : _originController.text.trim(),
    );

    if (user != null && _selectedRole == 'penghuni' && _selectedRoom != null) {
      // Create request on the selected room
      RoomModel updatedRoom = _selectedRoom!.copyWith(
        requestedByUid: user.uid,
        requestedByName: _nameController.text.trim(),
      );
      await RoomService().updateRoom(updatedRoom);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat! Silakan login.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mendaftar. Periksa email & coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: SafeArea(
        child: Center(
          child: ResponsiveLayout(
            mobile: _buildForm(context),
            tablet: SizedBox(width: 500, child: _buildForm(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('Buat Akun', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 6),
                  Text('Bergabung dengan komunitas kos', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                ],
              ),
            ),
            const SizedBox(height: 36),

            _buildSectionTitle(context, 'Identitas Diri'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password (Min. 6 Karakter)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'Min 6 karakter' : null,
            ),

            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Asal Daerah'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _originController,
              decoration: const InputDecoration(hintText: 'Kota Asal (Mis. Jakarta, Bandung)', prefixIcon: Icon(Icons.location_city_rounded)),
              validator: (v) => (v == null || v.isEmpty) ? 'Asal daerah wajib diisi' : null,
            ),

            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Info Medis (Opsional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bloodTypeController,
              decoration: const InputDecoration(hintText: 'Golongan Darah (A/B/AB/O)', prefixIcon: Icon(Icons.bloodtype_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allergiesController,
              decoration: const InputDecoration(hintText: 'Alergi (Obat/Makanan)', prefixIcon: Icon(Icons.coronavirus_outlined)),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Kontak Darurat (Opsional)'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emergencyNameController,
              decoration: const InputDecoration(hintText: 'Nama Wali / Orang Tua', prefixIcon: Icon(Icons.family_restroom_rounded)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'No. HP Darurat', prefixIcon: Icon(Icons.phone_outlined)),
            ),

            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Pilih Kamar (Opsional)'),
            const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoomModel>(
                    value: _selectedRoom,
                    isExpanded: true,
                    hint: const Text('Pilih kamar kos yang diminati'),
                    style: Theme.of(context).textTheme.bodyLarge,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textLight),
                    items: _availableRooms.map((room) {
                      return DropdownMenuItem<RoomModel>(
                        value: room,
                        child: Text('Lantai ${room.floor}, Kamar ${room.roomNumber} - ${_currencyFormat.format(room.price)}/bln'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedRoom = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamar yang dipilih akan direquest ke Admin. Anda baru bisa menempati kamar setelah disetujui.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),

            const SizedBox(height: 48),
            CustomButton(
              text: 'Daftar Sekarang',
              onPressed: _register,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun? ', style: TextStyle(color: AppTheme.textLight)),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Masuk', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
    );
  }
}
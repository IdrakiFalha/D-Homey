import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_state.dart';

class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  final RoomService _roomService = RoomService();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Memastikan 21 kamar (3 lantai x 7 kamar) terbuat jika belum ada
    await _roomService.initializeRooms();
    // Mengalokasikan penghuni lama ke kamar yang tersedia secara otomatis
    await _roomService.assignExistingUsersToRandomRooms();
    
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manajemen Kamar', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).cardColor,
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          elevation: 1,
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppState().themeNotifier,
              builder: (context, theme, child) {
                bool isDark = theme == ThemeMode.dark;
                return IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Theme.of(context).iconTheme.color),
                  onPressed: () => AppState().toggleTheme(!isDark),
                );
              }
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.secondary,
            unselectedLabelColor: AppTheme.textLight,
            indicatorColor: AppTheme.secondary,
            tabs: [
              Tab(text: 'Lantai 1'),
              Tab(text: 'Lantai 2'),
              Tab(text: 'Lantai 3'),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const TabBarView(
          children: [
            FloorTabView(floor: 1),
            FloorTabView(floor: 2),
            FloorTabView(floor: 3),
          ],
        ),
      ),
    );
  }
}

class FloorTabView extends StatelessWidget {
  final int floor;
  const FloorTabView({super.key, required this.floor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: RoomService().getRoomsByFloor(floor),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Data kamar belum tersedia.'));
        }

        final rooms = snapshot.data!;
        rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            return RoomCard(room: rooms[index]);
          },
        );
      },
    );
  }
}

class RoomCard extends StatelessWidget {
  final RoomModel room;
  const RoomCard({super.key, required this.room});

  Color _getStatusColor() {
    switch (room.status) {
      case 'Tersedia':
        return Colors.green;
      case 'Terisi':
        return AppTheme.secondary;
      case 'Perbaikan':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditRoomDialog(room: room),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();

    return InkWell(
      onTap: () => _showEditDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Kamar ${room.roomNumber}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color))),
                if (room.requestedByUid != null)
                  const Icon(Icons.notifications_active, color: Colors.orange, size: 20)
                else
                  Icon(Icons.meeting_room, color: statusColor, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(room.price),
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                room.status,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (room.status == 'Terisi')
              Expanded(
                child: Text(
                  room.occupantName ?? 'Tanpa Nama',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EditRoomDialog extends StatefulWidget {
  final RoomModel room;
  const EditRoomDialog({super.key, required this.room});

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  late String _selectedStatus;
  String? _selectedOccupantUid;
  String? _selectedOccupantName;
  final TextEditingController _priceController = TextEditingController();
  final RoomService _roomService = RoomService();

  final List<String> _statuses = ['Tersedia', 'Terisi', 'Perbaikan'];
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.room.status;
    _selectedOccupantUid = widget.room.occupantUid;
    _selectedOccupantName = widget.room.occupantName;
    _priceController.text = widget.room.price.toString();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'penghuni')
          .get();
      
      final users = snapshot.docs.map((doc) => {
        'uid': doc.id,
        'name': doc.data()['name'] ?? 'Tanpa Nama',
      }).toList();

      if (mounted) {
        setState(() {
          _users = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    String? occupantName = _selectedOccupantName;
    String? occupantUid = _selectedOccupantUid;
    if (_selectedStatus != 'Terisi') {
      occupantName = null;
      occupantUid = null;
    }

    RoomModel updatedRoom = widget.room.copyWith(
      status: _selectedStatus,
      price: int.tryParse(_priceController.text.trim()) ?? 1500000,
      occupantName: occupantName,
      occupantUid: occupantUid,
      clearOccupant: _selectedStatus != 'Terisi',
    );

    await _roomService.updateRoom(updatedRoom);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Kamar ${widget.room.roomNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.room.requestedByUid != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Permintaan dari: ${widget.room.requestedByName}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            // Tolak
                            RoomModel updated = widget.room.copyWith(clearRequest: true);
                            await _roomService.updateRoom(updated);
                            if (mounted) Navigator.pop(context);
                          },
                          child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Terima
                            RoomModel updated = widget.room.copyWith(
                              status: 'Terisi',
                              occupantUid: widget.room.requestedByUid,
                              occupantName: widget.room.requestedByName,
                              clearRequest: true,
                            );
                            await _roomService.updateRoom(updated);
                            if (mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Terima'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: _statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedStatus = val;
                });
              }
            },
            decoration: const InputDecoration(
              labelText: 'Status Kamar',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga Sewa (Rp)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedStatus == 'Terisi')
            _isLoadingUsers
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _users.any((u) => u['uid'] == _selectedOccupantUid) ? _selectedOccupantUid : null,
                    items: _users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['uid'],
                        child: Text(user['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedOccupantUid = val;
                          _selectedOccupantName = _users.firstWhere((u) => u['uid'] == val)['name'];
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Penghuni',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Pilih Penghuni'),
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, foregroundColor: Colors.white),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

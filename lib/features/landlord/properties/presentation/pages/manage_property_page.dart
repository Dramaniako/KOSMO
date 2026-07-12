import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../../../core/theme/app_colors.dart';
import '../../../../tenant/search/data/models/room_model.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../../dashboard/data/models/landlord_property_model.dart';
import '../../../dashboard/presentation/providers/landlord_provider.dart';

class ManagePropertyPage extends ConsumerStatefulWidget {
  final LandlordPropertyModel property;

  const ManagePropertyPage({super.key, required this.property});

  @override
  ConsumerState<ManagePropertyPage> createState() => _ManagePropertyPageState();
}

class _ManagePropertyPageState extends ConsumerState<ManagePropertyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _addressController;
  late TextEditingController _priceController;
  late TextEditingController _totalRoomsController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;

  late String _selectedLocation;
  late bool _isAllInclusive;
  late List<String> _selectedBills;
  late Future<List<RoomModel>> _roomsFuture;

  bool _isLoading = false;

  final List<String> _locations = [
    'Denpasar',
    'Badung',
    'Gianyar',
    'Tabanan',
    'Buleleng',
    'Karangasem',
    'Klungkung',
    'Bangli',
    'Jembrana',
  ];

  final List<String> _availableBills = ['Listrik', 'Air', 'WiFi', 'Kebersihan', 'Keamanan', 'Parkir'];

  bool _isUploadingPropertyPhoto = false;
  double _propertyPhotoUploadProgress = 0.0;

  final List<Map<String, String>> _mockImages = [
    {
      'name': 'Premium Living',
      'url': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400'
    },
    {
      'name': 'Modern Studio',
      'url': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400'
    },
    {
      'name': 'Elegance Suite',
      'url': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&q=80&w=400'
    }
  ];

  final List<Map<String, String>> _mockRoomImages = [
    {
      'name': 'Premium Bedroom',
      'url': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400'
    },
    {
      'name': 'Cozy Space',
      'url': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&q=80&w=400'
    },
    {
      'name': 'Minimalist Desk',
      'url': 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&q=80&w=400'
    }
  ];

  void _pickPropertyPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      _isUploadingPropertyPhoto = true;
      _propertyPhotoUploadProgress = 0.0;
    });

    try {
      final dio = dio_pkg.Dio();
      final formData = dio_pkg.FormData.fromMap({
        'image': await dio_pkg.MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      });

      final response = await dio.post(
        'https://kosmo-landing-page-red.vercel.app/api/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _propertyPhotoUploadProgress = sent / total;
            });
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String;
        setState(() {
          _imageUrlController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto properti berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Gagal mengunggah foto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unggah foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingPropertyPhoto = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleController = TextEditingController(text: p.title);
    _addressController = TextEditingController(text: p.address);
    _priceController = TextEditingController(text: p.price.toInt().toString());
    _totalRoomsController = TextEditingController(text: p.totalRooms.toString());
    _descriptionController = TextEditingController(text: p.description);
    _imageUrlController = TextEditingController(text: p.imageUrl);

    _selectedLocation = _locations.contains(p.address.contains('Denpasar') ? 'Denpasar' : 'Badung')
        ? (p.address.contains('Denpasar') ? 'Denpasar' : 'Badung')
        : 'Denpasar';
        
    // Parse regency from address if possible
    for (var loc in _locations) {
      if (p.address.toLowerCase().contains(loc.toLowerCase())) {
        _selectedLocation = loc;
        break;
      }
    }

    _isAllInclusive = p.allInclusiveBills.isNotEmpty || p.title.toLowerCase().contains('eksklusif') || p.title.toLowerCase().contains('premium') || p.title.toLowerCase().contains('hub');
    _selectedBills = p.allInclusiveBills.isNotEmpty
        ? p.allInclusiveBills.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];
    if (_isAllInclusive && _selectedBills.isEmpty) {
      _selectedBills = ['Listrik', 'Air'];
    }

    _loadRooms();
  }

  void _loadRooms() {
    setState(() {
      _roomsFuture = ref.read(landlordRepositoryProvider).getRoomsForProperty(widget.property.id);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _totalRoomsController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(landlordRepositoryProvider);
       final totalRooms = int.parse(_totalRoomsController.text);
 
       final success = await repository.editProperty(
         id: widget.property.id,
         title: _titleController.text,
         address: _addressController.text,
         location: _selectedLocation,
         imageUrl: _imageUrlController.text,
         totalRooms: totalRooms,
         description: _descriptionController.text,
       );

      if (success) {
        ref.invalidate(landlordProvider);
        ref.invalidate(landlordTenantsProvider);
        ref.invalidate(landlordTransactionsProvider);
        ref.invalidate(landlordReviewsProvider);
        ref.invalidate(searchProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Properti berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Gagal menyimpan perubahan properti.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editRoom(RoomModel room) {
    final descController = TextEditingController(text: room.description);
    final imgController = TextEditingController(text: room.imageUrl);
    final nameController = TextEditingController(text: room.roomNumber);
    final priceController = TextEditingController(text: room.price.toInt().toString());
    bool isAllInclusive = room.isAllInclusive;
    List<String> selectedBills = room.allInclusiveBills != null && room.allInclusiveBills!.isNotEmpty
        ? room.allInclusiveBills!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];
    bool isSavingRoom = false;
    bool isUploadingRoomPhoto = false;
    double roomPhotoUploadProgress = 0.0;

    void pickRoomPhoto(StateSetter setModalState) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheetContext) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                 'Pilih Foto Kamar',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _mockRoomImages.map((img) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setModalState(() {
                        isUploadingRoomPhoto = true;
                        roomPhotoUploadProgress = 0.0;
                      });

                      int tick = 0;
                      void simulateProgress() {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (!mounted) return;
                          tick++;
                          setModalState(() {
                            roomPhotoUploadProgress = tick / 10.0;
                          });
                          if (tick < 10) {
                            simulateProgress();
                          } else {
                            setModalState(() {
                              isUploadingRoomPhoto = false;
                              imgController.text = img['url']!;
                            });
                          }
                        });
                      }
                      simulateProgress();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        img['url']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (statefulContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kelola ${room.roomNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(statefulContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama / Nomor Kamar',
                  hintText: 'Contoh: Kamar 101',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kamar',
                  hintText: 'Fasilitas kamar, tipe kasur, dll.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Kamar per Bulan (Rp)',
                  hintText: 'Contoh: 1500000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('All-Inclusive (Bundling Tagihan)'),
                value: isAllInclusive,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setModalState(() {
                    isAllInclusive = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (isAllInclusive) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pilih Tagihan yang Termasuk:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                ..._availableBills.map((bill) {
                  final isSelected = selectedBills.contains(bill);
                  return CheckboxListTile(
                    title: Text(bill),
                    value: isSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selectedBills.add(bill);
                        } else {
                          selectedBills.remove(bill);
                        }
                      });
                    },
                  );
                }),
              ],
              const SizedBox(height: 16),
              const Text(
                'Foto Kamar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imgController.text.isNotEmpty && !isUploadingRoomPhoto)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imgController.text,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Foto kamar.',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => pickRoomPhoto(setModalState),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Ganti Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    else if (isUploadingRoomPhoto)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengunggah Foto... ${(roomPhotoUploadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: roomPhotoUploadProgress,
                            color: AppColors.primary,
                            backgroundColor: Colors.grey.shade200,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Unggah foto kamar',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => pickRoomPhoto(setModalState),
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('Pilih Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSavingRoom
                      ? null
                      : () async {
                          setModalState(() {
                            isSavingRoom = true;
                          });
                          try {
                            final success = await ref.read(landlordRepositoryProvider).updateRoom(
                                  roomId: room.id,
                                  roomNumber: nameController.text,
                                  description: descController.text,
                                  imageUrl: imgController.text,
                                  price: double.tryParse(priceController.text) ?? 0.0,
                                  isAllInclusive: isAllInclusive,
                                  allInclusiveBills: isAllInclusive ? selectedBills.join(',') : '',
                                );
                            if (success) {
                              _loadRooms();
                              if (!mounted) return;
                              Navigator.pop(statefulContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kamar berhasil diperbarui!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            setModalState(() {
                              isSavingRoom = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSavingRoom
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Perubahan Kamar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewRoomDialog() {
    final nameController = TextEditingController(text: 'Kamar Baru');
    final descController = TextEditingController();
    final imgController = TextEditingController();
    final priceController = TextEditingController(text: '1500000');
    bool isAllInclusive = false;
    List<String> selectedBills = [];
    bool isSavingRoom = false;
    bool isUploadingRoomPhoto = false;
    double roomPhotoUploadProgress = 0.0;

    void pickRoomPhoto(StateSetter setModalState) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheetContext) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                 'Pilih Foto Kamar',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _mockRoomImages.map((img) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setModalState(() {
                        isUploadingRoomPhoto = true;
                        roomPhotoUploadProgress = 0.0;
                      });

                      int tick = 0;
                      void simulateProgress() {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (!mounted) return;
                          tick++;
                          setModalState(() {
                            roomPhotoUploadProgress = tick / 10.0;
                          });
                          if (tick < 10) {
                            simulateProgress();
                          } else {
                            setModalState(() {
                              isUploadingRoomPhoto = false;
                              imgController.text = img['url']!;
                            });
                          }
                        });
                      }
                      simulateProgress();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        img['url']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (statefulContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tambah Kamar Baru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(statefulContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama / Nomor Kamar',
                  hintText: 'Contoh: Kamar 104',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Kamar',
                  hintText: 'Fasilitas kamar, tipe kasur, dll.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Kamar per Bulan (Rp)',
                  hintText: 'Contoh: 1500000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('All-Inclusive (Bundling Tagihan)'),
                value: isAllInclusive,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setModalState(() {
                    isAllInclusive = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (isAllInclusive) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Pilih Tagihan yang Termasuk:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                ..._availableBills.map((bill) {
                  final isSelected = selectedBills.contains(bill);
                  return CheckboxListTile(
                    title: Text(bill),
                    value: isSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (val) {
                      setModalState(() {
                        if (val == true) {
                          selectedBills.add(bill);
                        } else {
                          selectedBills.remove(bill);
                        }
                      });
                    },
                  );
                }),
              ],
              const SizedBox(height: 16),
              const Text(
                'Foto Kamar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imgController.text.isNotEmpty && !isUploadingRoomPhoto)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imgController.text,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Foto kamar.',
                              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => pickRoomPhoto(setModalState),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Ganti Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    else if (isUploadingRoomPhoto)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengunggah Foto... ${(roomPhotoUploadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: roomPhotoUploadProgress,
                            color: AppColors.primary,
                            backgroundColor: Colors.grey.shade200,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Unggah foto kamar',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => pickRoomPhoto(setModalState),
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('Pilih Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSavingRoom
                      ? null
                      : () async {
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama kamar wajib diisi'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          setModalState(() {
                            isSavingRoom = true;
                          });
                          try {
                            final success = await ref.read(landlordRepositoryProvider).addRoom(
                                  propertyId: widget.property.id,
                                  roomNumber: nameController.text,
                                  description: descController.text,
                                  imageUrl: imgController.text,
                                  price: double.tryParse(priceController.text) ?? 0.0,
                                  isAllInclusive: isAllInclusive,
                                  allInclusiveBills: isAllInclusive ? selectedBills.join(',') : '',
                                );
                            if (success) {
                              _loadRooms();
                              final rooms = await ref.read(landlordRepositoryProvider).getRoomsForProperty(widget.property.id);
                              setState(() {
                                _totalRoomsController.text = rooms.length.toString();
                              });
                              if (!mounted) return;
                              Navigator.pop(statefulContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kamar baru berhasil ditambahkan!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            setModalState(() {
                              isSavingRoom = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSavingRoom
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Kamar Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRoom(RoomModel room) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Kamar'),
        content: Text('Apakah Anda yakin ingin menghapus ${room.roomNumber} dari properti ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                _isLoading = true;
              });
              try {
                final success = await ref.read(landlordRepositoryProvider).deleteRoom(
                      roomId: room.id,
                      propertyId: widget.property.id,
                    );
                if (success) {
                  _loadRooms();
                  final rooms = await ref.read(landlordRepositoryProvider).getRoomsForProperty(widget.property.id);
                  setState(() {
                    _totalRoomsController.text = rooms.length.toString();
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kamar berhasil dihapus!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Properti', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Utama Properti',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Properti / Kos',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),


                    // Location dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Wilayah / Kabupaten',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLocation = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Full Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                     // Photo Selector
                     const Text(
                       'Foto Properti',
                       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                     ),
                     const SizedBox(height: 8),
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: AppColors.surface,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: AppColors.border),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           if (_imageUrlController.text.isNotEmpty && !_isUploadingPropertyPhoto)
                             Row(
                               children: [
                                 ClipRRect(
                                   borderRadius: BorderRadius.circular(8),
                                   child: Image.network(
                                     _imageUrlController.text,
                                     width: 64,
                                     height: 64,
                                     fit: BoxFit.cover,
                                     errorBuilder: (context, error, stackTrace) => Container(
                                       width: 64,
                                       height: 64,
                                       color: Colors.grey.shade200,
                                       child: const Icon(Icons.broken_image, color: Colors.grey),
                                     ),
                                   ),
                                 ),
                                 const SizedBox(width: 16),
                                 const Expanded(
                                   child: Text(
                                     'Foto properti utama.',
                                     style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                   ),
                                 ),
                                 ElevatedButton.icon(
                                   onPressed: _pickPropertyPhoto,
                                   icon: const Icon(Icons.edit_rounded, size: 16),
                                   label: const Text('Ganti Foto'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.grey.shade100,
                                     foregroundColor: AppColors.textPrimary,
                                     elevation: 0,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                   ),
                                 ),
                               ],
                             )
                           else if (_isUploadingPropertyPhoto)
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'Mengunggah Foto... ${(_propertyPhotoUploadProgress * 100).toInt()}%',
                                   style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                 ),
                                 const SizedBox(height: 8),
                                 LinearProgressIndicator(
                                   value: _propertyPhotoUploadProgress,
                                   color: AppColors.primary,
                                   backgroundColor: Colors.grey.shade200,
                                   minHeight: 6,
                                   borderRadius: BorderRadius.circular(3),
                                 ),
                               ],
                             )
                           else
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 const Text(
                                   'Unggah foto utama kos',
                                   style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                 ),
                                 ElevatedButton.icon(
                                   onPressed: _pickPropertyPhoto,
                                   icon: const Icon(Icons.image_outlined, size: 16),
                                   label: const Text('Pilih Foto'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.grey.shade100,
                                     foregroundColor: AppColors.textPrimary,
                                     elevation: 0,
                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                   ),
                                 ),
                               ],
                             ),
                         ],
                       ),
                     ),
                     const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Properti',
                        hintText: 'Fasilitas umum, aturan kos, dll.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    // Total Rooms
                    TextFormField(
                      controller: _totalRoomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Jumlah Kamar',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Jumlah kamar wajib diisi';
                        if (int.tryParse(val) == null) return 'Jumlah kamar tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),


                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProperty,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Simpan Perubahan Properti',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Room Management Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kelola Kamar Kos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _addNewRoomDialog,
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          label: const Text('Tambah Kamar'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<List<RoomModel>>(
                      future: _roomsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error memuat kamar: ${snapshot.error}', style: const TextStyle(color: AppColors.error));
                        }

                        final rooms = snapshot.data ?? [];
                        if (rooms.isEmpty) {
                          return const Text('Tidak ada kamar terdaftar.', style: TextStyle(color: AppColors.textSecondary));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            final isOccupied = room.tenantId != null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              room.roomNumber,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOccupied ? AppColors.error.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isOccupied ? 'Terisi' : 'Kosong',
                                                style: TextStyle(
                                                    color: isOccupied ? AppColors.error : Colors.green,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isOccupied) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Penyewa: ${room.tenantName ?? "Budi"}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                        if (room.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            room.description,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                                        onPressed: () => _editRoom(room),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          color: isOccupied ? Colors.grey : AppColors.error,
                                        ),
                                        onPressed: isOccupied
                                            ? () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Kamar ini sedang disewa oleh penyewa dan tidak dapat dihapus.'),
                                                    backgroundColor: AppColors.error,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            : () => _confirmDeleteRoom(room),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../../../../../core/theme/app_colors.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/landlord_provider.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  const AddPropertyPage({super.key});

  @override
  ConsumerState<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends ConsumerState<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _totalRoomsController = TextEditingController(text: '10');
  final _descriptionController = TextEditingController();
  
  String _selectedLocation = 'Denpasar';
  bool _isAllInclusive = true;
  String _selectedImage = 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400';

  final Map<String, bool> _includedBills = {
    'Listrik': true,
    'Air': true,
    'WiFi': true,
    'Kebersihan': false,
    'Keamanan': false,
    'Parkir': false,
  };

  bool _isLoading = false;

  // Bali regencies
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

  // Upload States
  String? _certificateFileName;
  bool _isUploadingCertificate = false;
  double _certificateUploadProgress = 0.0;

  bool _isUploadingPhoto = false;
  double _photoUploadProgress = 0.0;
  String? _uploadedPhotoUrl;

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _totalRoomsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _autofillCoordinates(String location) {
    setState(() {
      _selectedLocation = location;
      // Pre-fill coordinate ranges near chosen Bali regency
      if (location == 'Denpasar') {
        _latitudeController.text = '-8.6500';
        _longitudeController.text = '115.2166';
      } else if (location == 'Badung') {
        _latitudeController.text = '-8.5800';
        _longitudeController.text = '115.1700';
      } else if (location == 'Gianyar') {
        _latitudeController.text = '-8.5400';
        _longitudeController.text = '115.3300';
      } else if (location == 'Tabanan') {
        _latitudeController.text = '-8.5392';
        _longitudeController.text = '115.1234';
      } else if (location == 'Buleleng') {
        _latitudeController.text = '-8.1120';
        _longitudeController.text = '115.0884';
      } else if (location == 'Karangasem') {
        _latitudeController.text = '-8.4485';
        _longitudeController.text = '115.6178';
      } else if (location == 'Klungkung') {
        _latitudeController.text = '-8.5350';
        _longitudeController.text = '115.4020';
      } else if (location == 'Bangli') {
        _latitudeController.text = '-8.4526';
        _longitudeController.text = '115.3533';
      } else if (location == 'Jembrana') {
        _latitudeController.text = '-8.3582';
        _longitudeController.text = '114.6267';
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _autofillCoordinates(_selectedLocation);
  }

  void _pickCertificate() async {
    setState(() {
      _isUploadingCertificate = true;
      _certificateUploadProgress = 0.0;
      _certificateFileName = null;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _certificateUploadProgress = i / 10.0;
      });
    }

    setState(() {
      _isUploadingCertificate = false;
      _certificateFileName = 'SHM_${_titleController.text.isNotEmpty ? _titleController.text.replaceAll(' ', '_') : 'Properti'}.pdf';
    });
  }

  void _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() {
      _isUploadingPhoto = true;
      _photoUploadProgress = 0.0;
      _uploadedPhotoUrl = null;
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
        'http://localhost:5000/api/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _photoUploadProgress = sent / total;
            });
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String;
        setState(() {
          _uploadedPhotoUrl = url;
          _selectedImage = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto berhasil diunggah!'),
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
        _isUploadingPhoto = false;
      });
    }
  }

  void _openMapPicker() {
    showDialog(
      context: context,
      builder: (context) => _MapPickerDial(
        initialLat: double.tryParse(_latitudeController.text) ?? -8.6500,
        initialLng: double.tryParse(_longitudeController.text) ?? 115.2166,
        onConfirm: (lat, lng) {
          setState(() {
            _latitudeController.text = lat.toStringAsFixed(4);
            _longitudeController.text = lng.toStringAsFixed(4);
          });
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_certificateFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah Surat Kepemilikan (sertifikat) terlebih dahulu.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(landlordRepositoryProvider);
      
      final price = double.parse(_priceController.text);
      final latitude = double.parse(_latitudeController.text);
      final longitude = double.parse(_longitudeController.text);
      final totalRooms = int.parse(_totalRoomsController.text);

      final ownerId = ref.read(authProvider).user?.id ?? 2;

      final selectedBillsList = _isAllInclusive
          ? _includedBills.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList()
          : <String>[];
      final allInclusiveBillsString = _isAllInclusive ? selectedBillsList.join(',') : null;

      final success = await repository.addProperty(
        ownerId: ownerId,
        title: _titleController.text,
        address: _addressController.text,
        location: _selectedLocation,
        price: price,
        latitude: latitude,
        longitude: longitude,
        totalRooms: totalRooms,
        occupiedRooms: 0, 
        imageUrl: _selectedImage,
        isAllInclusive: _isAllInclusive,
        description: _descriptionController.text,
        allInclusiveBills: allInclusiveBillsString,
      );

      if (success) {
        final authUser = ref.read(authProvider).user;
        if (authUser != null && authUser.role == 'tenant') {
          await ref.read(authProvider.notifier).upgradeRole('landlord');
        }

        ref.invalidate(landlordProvider);
        ref.invalidate(landlordTenantsProvider);
        ref.invalidate(landlordTransactionsProvider);
        ref.invalidate(landlordReviewsProvider);
        ref.invalidate(searchProvider);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Properti berhasil ditambahkan ke database!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Query insert gagal.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan properti: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Properti', style: TextStyle(color: AppColors.textPrimary)),
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
                      'Formulir Pendaftaran Kos Baru (Wilayah Bali)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Masukkan data kos secara lengkap agar dapat langsung dipublikasikan.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kos / Properti',
                        hintText: 'Contoh: Kos Eksklusif Mawar',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama kos wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Location dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: const InputDecoration(
                        labelText: 'Kabupaten / Kota di Bali',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _locations.map((loc) {
                        return DropdownMenuItem(value: loc, child: Text(loc));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _autofillCoordinates(val);
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
                        hintText: 'Nama jalan, RT/RW, nomor bangunan...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Properti',
                        hintText: 'Tuliskan deskripsi lengkap tentang kos, fasilitas umum, dll...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Price per Month
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Sewa per Bulan (Rp)',
                        hintText: 'Contoh: 2500000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Harga sewa wajib diisi';
                        if (double.tryParse(val) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Coordinates Label & Map Picker Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Koordinat Lokasi',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        TextButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Pilih dari Peta'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Coordinates (Lat, Lng) Display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Koordinat Peta: ${_latitudeController.text}, ${_longitudeController.text}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Document Upload (Sertifikat)
                    const Text(
                      'Dokumen Kepemilikan (Sertifikat)',
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
                          if (_certificateFileName != null)
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _certificateFileName!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                              ],
                            )
                          else if (_isUploadingCertificate)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mengunggah... ${(_certificateUploadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _certificateUploadProgress,
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
                                  'Unggah scan SHM/Surat Kepemilikan',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _pickCertificate,
                                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                                  label: const Text('Pilih File'),
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
                          if (_uploadedPhotoUrl != null)
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                  _uploadedPhotoUrl!,
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
                                    'Foto terunggah dengan sukses.',
                                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _pickPhoto,
                                  icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                                ),
                              ],
                            )
                          else if (_isUploadingPhoto)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mengunggah Foto... ${(_photoUploadProgress * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: _photoUploadProgress,
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
                                  onPressed: _pickPhoto,
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
                        if (int.tryParse(val) == null) return 'Angka tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('All-Inclusive (Termasuk Air & Listrik)'),
                      value: _isAllInclusive,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _isAllInclusive = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_isAllInclusive) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih Fasilitas / Biaya yang Termasuk:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _includedBills.keys.map((bill) {
                          return FilterChip(
                            label: Text(bill),
                            selected: _includedBills[bill] ?? false,
                            onSelected: (selected) {
                              setState(() {
                                _includedBills[bill] = selected;
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Simpan Properti',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom interactive Map Picker for Bali regencies
class _MapPickerDial extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final void Function(double lat, double lng) onConfirm;

  const _MapPickerDial({
    required this.initialLat,
    required this.initialLng,
    required this.onConfirm,
  });

  @override
  State<_MapPickerDial> createState() => _MapPickerDialState();
}

class _MapPickerDialState extends State<_MapPickerDial> {
  late double _selectedLat;
  late double _selectedLng;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat;
    _selectedLng = widget.initialLng;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 500,
          height: 600,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pilih Lokasi Properti',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Real Interactive Map (FlutterMap)
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: latlong.LatLng(_selectedLat, _selectedLng),
                        initialZoom: 12.0,
                        maxZoom: 18.0,
                        minZoom: 9.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedLat = point.latitude;
                            _selectedLng = point.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.kosmo.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: latlong.LatLng(_selectedLat, _selectedLng),
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Display selected LatLng in top corner
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Lat: ${_selectedLat.toStringAsFixed(4)}, Lng: ${_selectedLng.toStringAsFixed(4)}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Help Tip
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                            ],
                          ),
                          child: const Text(
                            'Sentuh peta untuk memindahkan pin lokasi kos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Confirm button
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  children: [
                    // Zoom controls
                    IconButton(
                      icon: const Icon(Icons.zoom_in_rounded),
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out_rounded),
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onConfirm(_selectedLat, _selectedLng);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Konfirmasi Lokasi',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

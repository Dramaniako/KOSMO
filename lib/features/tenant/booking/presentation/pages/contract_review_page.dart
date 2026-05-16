import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import 'signature_pad_page.dart';

class ContractReviewPage extends StatefulWidget {
  const ContractReviewPage({super.key});

  @override
  State<ContractReviewPage> createState() => _ContractReviewPageState();
}

class _ContractReviewPageState extends State<ContractReviewPage> {
  bool _hasScrolledToBottom = false;
  bool _isAgreed = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollPosition();
    });
    _scrollController.addListener(_checkScrollPosition);
  }

  void _checkScrollPosition() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.maxScrollExtent <= 0 || 
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        if (!_hasScrolledToBottom) {
          setState(() {
            _hasScrolledToBottom = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tinjauan Kontrak', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Document Viewer
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'SURAT PERJANJIAN SEWA MENYEWA\nPROPERTI KOS',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text('Pasal 1: Objek Sewa', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Pihak Pertama menyewakan kepada Pihak Kedua sebuah kamar kos di Premium Residence beserta seluruh fasilitas yang melekat padanya.'),
                    SizedBox(height: 16),
                    Text('Pasal 2: Jangka Waktu & Harga', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Sewa menyewa ini dilangsungkan untuk jangka waktu 1 tahun, dengan harga All-Inclusive sebesar Rp 4.500.000,- / bulan.'),
                    SizedBox(height: 16),
                    Text('Pasal 3: Tanggung Jawab', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Pihak Kedua wajib menjaga kebersihan dan fasilitas umum. Kerusakan akibat kelalaian sepenuhnya menjadi tanggung jawab Pihak Kedua.'),
                    SizedBox(height: 16),
                    Text('Pasal 4: Pembatalan & Penalti', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Pembatalan sepihak sebelum masa sewa berakhir akan dikenakan penalti sebesar 1 bulan biaya sewa.'),
                    SizedBox(height: 100), // Fake height to ensure scrolling
                    Center(child: Text('--- Akhir Dokumen ---', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isAgreed,
                        activeColor: AppColors.primary,
                        onChanged: _hasScrolledToBottom ? (val) {
                          setState(() {
                            _isAgreed = val ?? false;
                          });
                        } : null,
                      ),
                      Expanded(
                        child: Text(
                          'Saya telah membaca, memahami, dan menyetujui seluruh syarat dan ketentuan di atas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasScrolledToBottom ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isAgreed ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignaturePadPage()),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Tanda Tangani Kontrak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

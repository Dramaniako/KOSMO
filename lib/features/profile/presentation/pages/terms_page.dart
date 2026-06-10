import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Umum'),
            Tab(text: 'Pembayaran'),
            Tab(text: 'Keamanan (KYC)'),
            Tab(text: 'Pembatalan'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTextContent(
              'Ketentuan Umum Penggunaan Layanan Kosmo',
              [
                '1. Deskripsi Platform',
                'Kosmo adalah platform co-living pintar yang mempertemukan penyewa (tenant) dengan pemilik kos (landlord). Kami memfasilitasi pencarian kos, penandatanganan kontrak digital, penarikan dana, serta pengelolaan tagihan bulanan.',
                '2. Kelayakan Pengguna',
                'Pengguna wajib berusia minimal 17 tahun atau telah memiliki kartu identitas resmi (KTP/ID) untuk mendaftarkan akun di Kosmo. Pengguna bertanggung jawab penuh atas keakuratan data yang diinput ke dalam platform.',
                '3. Pemeliharaan Akun',
                'Anda bertanggung jawab atas kerahasiaan kata sandi akun Anda. Segala aktivitas transaksi yang dilakukan melalui akun Anda dianggap sebagai tindakan sah dari Anda.',
                '4. Hak Milik Intelektual',
                'Seluruh logo, desain, database, dan kode pemrograman dalam platform Kosmo adalah hak milik eksklusif dari tim pengembang Kosmo dan dilindungi oleh undang-undang hak cipta.',
              ],
            ),
            _buildTextContent(
              'Ketentuan Pembayaran & Biaya Layanan',
              [
                '1. Biaya Sewa Bulanan',
                'Biaya sewa kamar kos dibebankan setiap bulan sesuai dengan tarif yang ditetapkan oleh landlord dan tercantum pada halaman kontrak digital.',
                '2. Biaya Admin/Layanan',
                'Setiap transaksi sewa pertama kali (checkout) dikenakan biaya administrasi platform sebesar Rp 50.000 yang ditambahkan langsung ke jumlah pembayaran akhir.',
                '3. Pajak dan Biaya Lainnya',
                'Landlord bertanggung jawab atas pajak penghasilan dari biaya sewa yang diterimanya. Kecuali disepakati sebagai "All-Inclusive", biaya utilitas tambahan (seperti listrik token) dapat ditagihkan terpisah oleh landlord.',
                '4. Keterlambatan Pembayaran',
                'Keterlambatan pembayaran melebihi tanggal jatuh tempo akan memicu perubahan status tagihan menjadi "Arrears" (Dunning) dan penangguhan akses fasilitas kamar.',
              ],
            ),
            _buildTextContent(
              'Ketentuan Keamanan & Verifikasi KYC',
              [
                '1. Kewajiban KYC',
                'Semua penyewa yang ingin menyewa kamar kos dan landlord yang ingin mendaftarkan properti wajib menyelesaikan verifikasi KYC (Know Your Customer) dengan mengunggah foto kartu identitas (KTP/Paspor).',
                '2. Keaslian Dokumen',
                'Dokumen identitas yang diunggah harus asli, masih berlaku, dan terbaca dengan jelas. Menggunakan identitas orang lain atau dokumen palsu merupakan tindak pelanggaran hukum.',
                '3. Privasi Data',
                'Kosmo berkomitmen melindungi privasi dokumen identitas Anda. Data KYC Anda dienkripsi secara aman dan hanya digunakan untuk keperluan verifikasi keamanan di dalam platform.',
                '4. Penolakan Akun',
                'Kosmo berhak menolak verifikasi atau memblokir akun pengguna apabila ditemukan indikasi manipulasi dokumen atau rekam jejak penyalahgunaan platform.',
              ],
            ),
            _buildTextContent(
              'Ketentuan Pembatalan & Penghentian Sewa',
              [
                '1. Berhenti Menyewa (Check-out)',
                'Penyewa dapat mengajukan pemberhentian sewa secara mandiri melalui menu "Berhenti Menyewa" di aplikasi dengan memvalidasi password demi keamanan data.',
                '2. Masa Tenggang Pemberitahuan',
                'Penghentian sewa sebaiknya diajukan minimal 7 hari sebelum siklus pembayaran bulan berikutnya dimulai untuk menghindari pendebetan sewa otomatis.',
                '3. Pengembalian Deposit (Jika Ada)',
                'Kebijakan pengembalian uang deposit diatur sepenuhnya sesuai dengan kesepakatan tertulis di awal antara penyewa dan pemilik properti (landlord). Kosmo tidak menahan uang deposit sewa.',
                '4. Pelanggaran Aturan Kos',
                'Landlord berhak mengajukan penghentian sewa sepihak kepada penyewa melalui platform jika penyewa terbukti melanggar norma sosial atau merusak aset properti secara sengaja.',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(String title, List<String> paragraphs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 16),
          ...paragraphs.map((text) {
            final isHeader = text.startsWith(RegExp(r'^[0-9]'));
            return Padding(
              padding: EdgeInsets.only(bottom: isHeader ? 8.0 : 16.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isHeader ? 14 : 13,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  color: isHeader ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

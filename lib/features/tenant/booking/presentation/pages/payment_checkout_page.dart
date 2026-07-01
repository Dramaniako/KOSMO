import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../search/data/models/room_model.dart';
import '../../../search/domain/entities/property_entity.dart';
import 'payment_gateway_portal_page.dart';

class PaymentCheckoutPage extends StatefulWidget {
  final PropertyEntity property;
  final RoomModel room;
  final List<Offset?>? signaturePoints;

  const PaymentCheckoutPage({
    super.key,
    required this.property,
    required this.room,
    this.signaturePoints,
  });

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  String _selectedMethod = 'va'; // 'va', 'gopay', 'card'
  String _selectedBank = 'bca'; // 'bca', 'mandiri', 'bni'
  
  // Card inputs
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _onPayPressed() {
    if (_selectedMethod == 'card') {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate connecting to payment gateway
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      // Navigate to portal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentGatewayPortalPage(
            property: widget.property,
            room: widget.room,
            amount: widget.room.price + 50000.0,
            paymentMethod: _selectedMethod,
            bankCode: _selectedMethod == 'va' ? _selectedBank : null,
            signaturePoints: widget.signaturePoints,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pembayaran', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkout summary card
                  _buildSummaryCard(),

                  const SizedBox(height: 24),

                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),

                  // Method Selection Rows
                  _buildMethodSelector(
                    id: 'va',
                    title: 'Virtual Account (Transfer VA)',
                    subtitle: 'BCA, Mandiri, BNI (Verifikasi Otomatis)',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  _buildMethodSelector(
                    id: 'gopay',
                    title: 'GoPay / QRIS',
                    subtitle: 'Bayar instan dengan aplikasi Gojek Anda',
                    icon: Icons.qr_code_2_rounded,
                  ),
                  _buildMethodSelector(
                    id: 'card',
                    title: 'Kartu Kredit / Debit',
                    subtitle: 'Visa, MasterCard, JCB',
                    icon: Icons.credit_card_rounded,
                  ),

                  const SizedBox(height: 24),

                  // Selected payment forms
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildDetailsForm(),
                  ),

                  const SizedBox(height: 40),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _onPayPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _selectedMethod == 'gopay' ? 'Tampilkan QRIS' : 'Bayar Sekarang',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final valStr = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < valStr.length; i++) {
      if (i > 0 && (valStr.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(valStr[i]);
    }
    return buffer.toString();
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Tagihan',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.property.title} (${widget.room.roomNumber})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Text(
            'Sewa bulan pertama + deposit admin',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildSummaryRow('Biaya Sewa Bulanan', 'Rp ${_formatCurrency(widget.room.price)}'),
          const SizedBox(height: 8),
          _buildSummaryRow('Biaya Layanan & Administrasi', 'Rp 50.000'),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'Rp ${_formatCurrency(widget.room.price + 50000.0)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMethodSelector({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsForm() {
    if (_selectedMethod == 'va') {
      return Column(
        key: const ValueKey('va'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pilih Bank Transfer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBankLogoBtn('bca', 'BCA'),
              const SizedBox(width: 12),
              _buildBankLogoBtn('mandiri', 'Mandiri'),
              const SizedBox(width: 12),
              _buildBankLogoBtn('bni', 'BNI'),
            ],
          ),
        ],
      );
    } else if (_selectedMethod == 'gopay') {
      return Container(
        key: const ValueKey('gopay'),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          children: const [
            Icon(Icons.qr_code_scanner_rounded, color: Colors.blue, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pembayaran QRIS GoPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(height: 2),
                  Text(
                    'Kode QR dinamis akan dihasilkan untuk Anda scan di portal pembayaran.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Credit Card Form
      return Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('card'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Credit Card Visual Widget
            _buildInteractiveCardLayout(),
            const SizedBox(height: 20),

            // Card inputs
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemilik Kartu',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) => val == null || val.isEmpty ? 'Nama harus diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Kartu Kredit',
                hintText: '4000 1234 5678 9010',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              onChanged: (_) => setState(() {}),
              validator: (val) => val == null || val.length < 16 ? 'Nomor kartu tidak valid' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cardExpiryController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Masa Berlaku',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || !val.contains('/') ? 'Format MM/YY' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cardCvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) => val == null || val.length < 3 ? 'Cvv 3 digit' : null,
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }
  }

  Widget _buildBankLogoBtn(String bankId, String label) {
    final isSelected = _selectedBank == bankId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBank = bankId;
          });
        },
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8)]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveCardLayout() {
    final name = _cardHolderController.text.isEmpty ? 'NAMA PEMILIK' : _cardHolderController.text.toUpperCase();
    var number = _cardNumberController.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberController.text;
    if (number.length > 16) number = number.substring(0, 16);
    // Format card number with spaces
    final buffer = StringBuffer();
    for (int i = 0; i < number.length; i++) {
      buffer.write(number[i]);
      if ((i + 1) % 4 == 0 && i != number.length - 1) {
        buffer.write(' ');
      }
    }
    final formattedNumber = buffer.toString();
    final expiry = _cardExpiryController.text.isEmpty ? 'MM/YY' : _cardExpiryController.text;

    return Container(
      width: double.infinity,
      height: 190,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.credit_card_rounded, color: Colors.white, size: 28),
              Text(
                'KOSMO PAY',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 2),
              ),
            ],
          ),
          Text(
            formattedNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PEMILIK KARTU', style: TextStyle(color: Colors.white30, fontSize: 8)),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BERLAKU S/D', style: TextStyle(color: Colors.white30, fontSize: 8)),
                  const SizedBox(height: 2),
                  Text(expiry, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Menghubungkan ke Gateway...',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WithdrawalModel {
  final int id;
  final int landlordId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String dateStr;
  final String status;

  WithdrawalModel({
    required this.id,
    required this.landlordId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.dateStr,
    required this.status,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] as int,
      landlordId: json['landlord_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bank_name'] as String,
      accountNumber: json['account_number'] as String,
      dateStr: json['date_str'] as String,
      status: json['status'] as String,
    );
  }
}

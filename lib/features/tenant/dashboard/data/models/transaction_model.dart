import '../../presentation/widgets/transaction_card.dart';

class TransactionModel {
  final String date;
  final String invoiceNumber;
  final double amount;
  final TransactionStatus status;
  final String propertyName;
  final int? userId;
  final String transactionType; // 'rental', 'monthly', 'arrears'
  final int? propertyId;
  final int? roomId;

  const TransactionModel({
    required this.date,
    required this.invoiceNumber,
    required this.amount,
    required this.status,
    required this.propertyName,
    this.userId,
    this.transactionType = 'rental',
    this.propertyId,
    this.roomId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String;
    TransactionStatus status;
    switch (statusStr) {
      case 'success':
        status = TransactionStatus.success;
        break;
      case 'failed':
        status = TransactionStatus.failed;
        break;
      case 'pending':
      default:
        status = TransactionStatus.pending;
        break;
    }

    return TransactionModel(
      date: json['date'] as String,
      invoiceNumber: json['invoiceNumber'] as String? ?? json['invoice_number'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: status,
      propertyName: json['propertyName'] as String? ?? json['property_name'] as String,
      userId: json['userId'] as int? ?? json['user_id'] as int?,
      transactionType: json['transactionType'] as String? ?? json['transaction_type'] as String? ?? 'rental',
      propertyId: json['propertyId'] as int? ?? json['property_id'] as int?,
      roomId: json['roomId'] as int? ?? json['room_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case TransactionStatus.success:
        statusStr = 'success';
        break;
      case TransactionStatus.failed:
        statusStr = 'failed';
        break;
      case TransactionStatus.pending:
        statusStr = 'pending';
        break;
    }

    return {
      'date': date,
      'invoiceNumber': invoiceNumber,
      'amount': amount,
      'status': statusStr,
      'propertyName': propertyName,
      'userId': userId,
      'transactionType': transactionType,
      'propertyId': propertyId,
      'roomId': roomId,
    };
  }
}

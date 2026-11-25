import 'package:cloud_firestore/cloud_firestore.dart';

class QuoteItem {
  final String articleId;
  final String name;
  final String brand;
  final double unitPrice;
  int quantity;
  bool isSorted; // Surtido / pendiente

  QuoteItem({
    required this.articleId,
    required this.name,
    required this.brand,
    required this.unitPrice,
    required this.quantity,
    this.isSorted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'articleId': articleId,
      'name': name,
      'brand': brand,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'isSorted': isSorted,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      articleId: map['articleId'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      isSorted: map['isSorted'] ?? false,
    );
  }
}

class QuoteModel {
  final String id;
  final String clientName;
  final String clientPhone;
  final String studentOrGrade;
  final DateTime deliveryDate;
  final List<QuoteItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final double advancePayment; // Abono
  final double remainingBalance; // Saldo
  final String status; // 'Cotización', 'Por surtir', 'Surtida / Lista', 'Entregada'
  final DateTime createdAt;

  QuoteModel({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.studentOrGrade,
    required this.deliveryDate,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.advancePayment,
    required this.remainingBalance,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientName': clientName,
      'clientPhone': clientPhone,
      'studentOrGrade': studentOrGrade,
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'advancePayment': advancePayment,
      'remainingBalance': remainingBalance,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory QuoteModel.fromMap(String id, Map<String, dynamic> map) {
    var rawItems = map['items'] as List<dynamic>? ?? [];
    List<QuoteItem> parsedItems = rawItems.map((i) => QuoteItem.fromMap(i as Map<String, dynamic>)).toList();

    DateTime delivery = (map['deliveryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime created = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return QuoteModel(
      id: id,
      clientName: map['clientName'] ?? '',
      clientPhone: map['clientPhone'] ?? '',
      studentOrGrade: map['studentOrGrade'] ?? '',
      deliveryDate: delivery,
      items: parsedItems,
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      advancePayment: (map['advancePayment'] ?? 0.0).toDouble(),
      remainingBalance: (map['remainingBalance'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Cotización',
      createdAt: created,
    );
  }
}

class CanteenCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  CanteenCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CanteenCategory.fromJson(Map<String, dynamic> json) {
    return CanteenCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }
}

class CanteenProduct {
  final int id;
  final String sku;
  final String name;
  final int? categoryId;
  final String categoryName;
  final String? imageUrl;
  final String? description;
  final double priceEmployee;
  final double priceRetail;
  final bool hasDiscount;
  final bool trackStock;
  final double stockAvailable;
  final bool isReady;
  final bool isConsignment;
  final int baseUnitId;
  final String baseUnitName;

  CanteenProduct({
    required this.id,
    required this.sku,
    required this.name,
    this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.description,
    required this.priceEmployee,
    required this.priceRetail,
    required this.hasDiscount,
    required this.trackStock,
    required this.stockAvailable,
    required this.isReady,
    required this.isConsignment,
    required this.baseUnitId,
    required this.baseUnitName,
  });

  factory CanteenProduct.fromJson(Map<String, dynamic> json) {
    final baseUnit = json['base_unit'] is Map ? json['base_unit'] as Map : {};
    final employeePrice = (baseUnit['price_employee'] is num)
        ? (baseUnit['price_employee'] as num).toDouble()
        : double.tryParse(baseUnit['price_employee']?.toString() ?? '0') ?? 0.0;
    final retailPrice = (baseUnit['price_retail'] is num)
        ? (baseUnit['price_retail'] as num).toDouble()
        : double.tryParse(baseUnit['price_retail']?.toString() ?? '0') ?? 0.0;

    return CanteenProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? 'Lain-lain',
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
      priceEmployee: employeePrice > 0 ? employeePrice : retailPrice,
      priceRetail: retailPrice,
      hasDiscount: employeePrice < retailPrice && retailPrice > 0,
      trackStock: json['track_stock'] == true || json['track_stock'] == 1,
      stockAvailable: (json['stock_available'] is num)
          ? (json['stock_available'] as num).toDouble()
          : double.tryParse(json['stock_available']?.toString() ?? '0') ?? 0.0,
      isReady: json['is_ready'] == true || json['is_ready'] == 1,
      isConsignment: json['is_consignment'] == true || json['is_consignment'] == 1,
      baseUnitId: baseUnit['id'] is int ? baseUnit['id'] : int.tryParse(baseUnit['id']?.toString() ?? '0') ?? 0,
      baseUnitName: baseUnit['unit_name']?.toString() ?? 'Pcs',
    );
  }
}

class CanteenCartItem {
  final CanteenProduct product;
  final int unitId;
  final String unitName;
  final double price;
  int qty;
  String? notes;

  CanteenCartItem({
    required this.product,
    required this.unitId,
    required this.unitName,
    required this.price,
    this.qty = 1,
    this.notes,
  });

  double get subtotal => price * qty;

  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'product_unit_id': unitId,
      'qty': qty,
      'notes': notes,
    };
  }
}

class CanteenOrderItemModel {
  final int id;
  final String productName;
  final String unitName;
  final double qty;
  final double unitPrice;
  final double subtotal;
  final String? notes;

  CanteenOrderItemModel({
    required this.id,
    required this.productName,
    required this.unitName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
  });

  factory CanteenOrderItemModel.fromJson(Map<String, dynamic> json) {
    return CanteenOrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      qty: (json['qty'] is num) ? (json['qty'] as num).toDouble() : double.tryParse(json['qty']?.toString() ?? '1') ?? 1.0,
      unitPrice: (json['unit_price'] is num) ? (json['unit_price'] as num).toDouble() : double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      subtotal: (json['subtotal'] is num) ? (json['subtotal'] as num).toDouble() : double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }
}

class CanteenOrderModel {
  final int id;
  final String orderNumber;
  final String orderType; // 'delivery' or 'pickup'
  final String? deliveryLocation;
  final String? recipientName;
  final String? recipientPhone;
  final String paymentMethod; // 'bon', 'qris', 'cash'
  final String paymentStatus;
  final String status;
  final String statusLabel;
  final double totalAmount;
  final int totalItems;
  final String? notes;
  final DateTime? createdAt;
  final List<CanteenOrderItemModel> items;

  CanteenOrderModel({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    this.deliveryLocation,
    this.recipientName,
    this.recipientPhone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.statusLabel,
    required this.totalAmount,
    required this.totalItems,
    this.notes,
    this.createdAt,
    required this.items,
  });

  factory CanteenOrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    return CanteenOrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      orderType: json['order_type']?.toString() ?? 'delivery',
      deliveryLocation: json['delivery_location']?.toString(),
      recipientName: json['recipient_name']?.toString(),
      recipientPhone: json['recipient_phone']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'qris',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Menunggu Konfirmasi',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      totalItems: json['total_items'] is int ? json['total_items'] : int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      items: rawItems.map((item) => CanteenOrderItemModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

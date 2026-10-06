import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rsia_employee_app/screen/menu/kantin/models/canteen_model.dart';

class CanteenProductCard extends StatelessWidget {
  final CanteenProduct product;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const CanteenProductCard({
    super.key,
    required this.product,
    required this.cartQty,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _getFoodEmoji() {
    final cat = product.categoryName.toLowerCase();
    final name = product.name.toLowerCase();
    if (name.contains('kopi')) return '☕';
    if (name.contains('teh') || name.contains('jus') || cat.contains('minuman')) return '🥤';
    if (name.contains('mie') || name.contains('bakso')) return '🍜';
    if (name.contains('nasi') || name.contains('soto') || cat.contains('makanan')) return '🍛';
    if (name.contains('roti') || name.contains('risol') || name.contains('snack')) return '🥐';
    return '🍱';
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.hasDiscount;
    final isOutOfStock = !product.isReady;

    final isSelected = cartQty > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFEA580C).withOpacity(0.08)
                : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Visual Area
            Container(
              height: 78,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isOutOfStock ? const Color(0xFFF1F5F9) : const Color(0xFFFFF7ED),
              ),
              child: Stack(
              children: [
                Center(
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorWidget: (_, __, ___) => Text(
                            _getFoodEmoji(),
                            style: const TextStyle(fontSize: 32),
                          ),
                        )
                      : Text(
                          _getFoodEmoji(),
                          style: TextStyle(
                            fontSize: 34,
                            color: isOutOfStock ? Colors.grey : null,
                          ),
                        ),
                ),

                // Category pill top left
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.categoryName,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),

                // Discount / Employee Badge top right
                if (hasDiscount && !isOutOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Text(
                        'Harga Karyawan',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ),

                // Out of stock overlay
                if (isOutOfStock)
                  Container(
                    color: Colors.white.withOpacity(0.75),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Stok Habis',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),

                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatRupiah(product.priceEmployee),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '/${product.baseUnitName}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),

                if (hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      _formatRupiah(product.priceRetail),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF94A3B8),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Action: Add or Stepper
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: _buildActionButton(isOutOfStock),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionButton(bool isOutOfStock) {
    if (isOutOfStock) {
      return Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Habis',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (cartQty > 0) {
      return Container(
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.remove_rounded, size: 16, color: Color(0xFFEA580C)),
              ),
            ),
            Text(
              '$cartQty',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEA580C),
              ),
            ),
            InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(Icons.add_rounded, size: 16, color: Color(0xFFEA580C)),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 30,
      child: OutlinedButton(
        onPressed: onAdd,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEA580C), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 14, color: Color(0xFFEA580C)),
            SizedBox(width: 3),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEA580C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

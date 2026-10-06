import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/screen/menu/kantin/models/canteen_model.dart';
import 'package:rsia_employee_app/screen/menu/kantin/services/canteen_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CanteenOrderDetailSheet extends StatefulWidget {
  final CanteenOrderModel order;
  final VoidCallback onRefreshNeeded;

  const CanteenOrderDetailSheet({
    super.key,
    required this.order,
    required this.onRefreshNeeded,
  });

  @override
  State<CanteenOrderDetailSheet> createState() => _CanteenOrderDetailSheetState();
}

class _CanteenOrderDetailSheetState extends State<CanteenOrderDetailSheet> {
  bool _isCancelling = false;

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  int _getStatusStepIndex(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'preparing':
        return 1;
      case 'on_delivery':
      case 'ready_for_pickup':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('Pesanan yang dibatalkan tidak akan diproses oleh kantin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isCancelling = true);
      final success = await CanteenService.cancelOrder(widget.order.orderNumber);
      setState(() => _isCancelling = false);

      if (mounted) {
        if (success) {
          Msg.success(context, 'Pesanan berhasil dibatalkan');
          Navigator.pop(context);
          widget.onRefreshNeeded();
        } else {
          Msg.error(context, 'Gagal membatalkan pesanan. Pesanan mungkin sudah disiapkan.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = widget.order.status == 'cancelled';
    final currentStep = _getStatusStepIndex(widget.order.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${widget.order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      widget.order.createdAt != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(widget.order.createdAt!)
                          : 'Baru saja',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Timeline Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCancelled ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCancelled ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: isCancelled
                        ? const Row(
                            children: [
                              Icon(Icons.cancel_rounded, color: Color(0xFFE11D48), size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pesanan Dibatalkan',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF9F1239)),
                                    ),
                                    Text(
                                      'Pesanan ini tidak diproses oleh kantin.',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFFBE123C)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : _buildTimeline(currentStep),
                  ),

                  const SizedBox(height: 20),

                  // Delivery Location
                  const Text(
                    'TUJUAN PENGANTARAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            widget.order.orderType == 'delivery' ? Icons.moped_rounded : Icons.storefront_rounded,
                            color: const Color(0xFFEA580C),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.order.orderType == 'delivery' ? 'Antar ke Ruangan' : 'Ambil Sendiri di Kantin',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                widget.order.deliveryLocation ?? 'Kantin RSIA',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment method badge
                  const Text(
                    'METODE PEMBAYARAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.order.paymentMethod == 'bon'
                              ? Icons.account_balance_wallet_rounded
                              : (widget.order.paymentMethod == 'qris' ? Icons.qr_code_2_rounded : Icons.payments_rounded),
                          size: 18,
                          color: const Color(0xFFEA580C),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.order.paymentMethod == 'bon'
                              ? 'Bon Karyawan (Potong Gaji)'
                              : (widget.order.paymentMethod == 'qris' ? 'QRIS' : 'Tunai COD'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.order.paymentStatus == 'paid' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.order.paymentStatus == 'paid' ? 'LUNAS' : 'BELUM DIBAYAR',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: widget.order.paymentStatus == 'paid' ? const Color(0xFF15803D) : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ordered Items
                  const Text(
                    'DETAIL PESANAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...widget.order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.qty.toInt()}x',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty)
                                  Text(
                                    'Catatan: "${item.notes}"',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRupiah(item.subtotal),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Text(
                        _formatRupiah(widget.order.totalAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEA580C)),
                      ),
                    ],
                  ),

                  if (widget.order.status == 'pending') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _isCancelling ? null : _handleCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE11D48)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isCancelling
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text(
                                'Batalkan Pesanan',
                                style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int currentStep) {
    final steps = [
      'Menunggu',
      'Disiapkan',
      widget.order.orderType == 'delivery' ? 'Diantar' : 'Siap Ambil',
      'Selesai',
    ];

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connecting line
              final stepBefore = index ~/ 2;
              final isPassed = currentStep > stepBefore;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                ),
              );
            }

            // Circle step
            final stepIndex = index ~/ 2;
            final isCurrent = currentStep == stepIndex;
            final isDone = currentStep > stepIndex;

            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (isCurrent ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: steps.map((s) {
            return SizedBox(
              width: 60,
              child: Text(
                s,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

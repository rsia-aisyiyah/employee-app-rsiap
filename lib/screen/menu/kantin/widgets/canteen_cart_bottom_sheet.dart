import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/screen/menu/kantin/models/canteen_model.dart';
import 'package:rsia_employee_app/screen/menu/kantin/services/canteen_service.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class CanteenCartBottomSheet extends StatefulWidget {
  final List<CanteenCartItem> cartItems;
  final List<String> availableLocations;
  final Function(CanteenCartItem item, int newQty) onUpdateQty;
  final Function(CanteenCartItem item, String note) onUpdateItemNote;
  final Function(CanteenOrderModel createdOrder) onOrderSuccess;

  const CanteenCartBottomSheet({
    super.key,
    required this.cartItems,
    required this.availableLocations,
    required this.onUpdateQty,
    required this.onUpdateItemNote,
    required this.onOrderSuccess,
  });

  @override
  State<CanteenCartBottomSheet> createState() => _CanteenCartBottomSheetState();
}

class _CanteenCartBottomSheetState extends State<CanteenCartBottomSheet> {
  String _orderType = 'delivery'; // 'delivery' or 'pickup'
  String _selectedLocation = 'Ruang Rawat Inap (Ranap)';
  final _roomDetailController = TextEditingController();
  final _orderNotesController = TextEditingController();
  String _paymentMethod = 'qris'; // 'qris', 'cash'
  bool _isSubmitting = false;

  List<String> get _cleanLocations {
    const fallbackList = [
      'Ruang Rawat Inap (Ranap)',
      'Poli Rawat Jalan',
      'IGD',
      'VK / Kamar Bersalin',
      'Ruang Operasi (OK)',
      'Ruang Perinatologi',
      'Farmasi',
      'Laboratorium',
      'Radiologi',
      'Kantor SDI / Manajemen',
      'Ruang IT',
      'Dapur Gizi',
      'Pos Satpam',
      'Lainnya',
    ];

    final filtered = widget.availableLocations
        .where((loc) => !loc.toLowerCase().contains('mess'))
        .map((loc) => loc.replaceAll('(Ranapp)', '(Ranap)').replaceAll('(Rana)', '(Ranap)'))
        .toList();

    return filtered.isNotEmpty ? filtered : fallbackList;
  }

  @override
  void initState() {
    super.initState();
    final locs = _cleanLocations;
    if (locs.isNotEmpty) {
      _selectedLocation = locs.first;
    }
  }

  @override
  void dispose() {
    _roomDetailController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  double get _totalAmount {
    return widget.cartItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _handleSubmitOrder() async {
    if (widget.cartItems.isEmpty) {
      Msg.warning(context, 'Keranjang belanja masih kosong');
      return;
    }

    String fullLocation = '';
    if (_orderType == 'delivery') {
      if (_roomDetailController.text.trim().isEmpty) {
        Msg.warning(context, 'Mohon isi detail kamar/ruangan pengantaran (misal: Kamar 3)');
        return;
      }
      fullLocation = '$_selectedLocation - ${_roomDetailController.text.trim()}';
    } else {
      fullLocation = 'Ambil Sendiri di Kantin';
    }

    setState(() => _isSubmitting = true);

    final res = await CanteenService.submitOrder(
      orderType: _orderType,
      deliveryLocation: fullLocation,
      paymentMethod: _paymentMethod,
      items: widget.cartItems,
      notes: _orderNotesController.text.trim().isNotEmpty ? _orderNotesController.text.trim() : null,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (res['success'] == true && res['order'] != null) {
        Navigator.pop(context);
        widget.onOrderSuccess(res['order'] as CanteenOrderModel);
      } else {
        Msg.error(context, res['message'] ?? 'Gagal membuat pesanan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    const Text(
                      'Keranjang Pesanan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${widget.cartItems.length} item dipilih',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List of Items
                  const Text(
                    'DAFTAR MENU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...widget.cartItems.map((item) => _buildItemRow(item)),

                  const SizedBox(height: 20),

                  // Delivery Mode Selector (Pill Segment)
                  const Text(
                    'PILIHAN PENGANTARAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _orderType = 'delivery'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _orderType == 'delivery' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _orderType == 'delivery'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.moped_rounded,
                                    size: 16,
                                    color: _orderType == 'delivery' ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Antar ke Ruang',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _orderType == 'delivery' ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _orderType = 'pickup'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _orderType == 'pickup' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _orderType == 'pickup'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 16,
                                    color: _orderType == 'pickup' ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ambil Sendiri',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: _orderType == 'pickup' ? const Color(0xFFEA580C) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Location Details if Delivery
                  if (_orderType == 'delivery') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFED7AA).withOpacity(0.7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tujuan Ruangan / Unit:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDBA74)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _cleanLocations.contains(_selectedLocation)
                                    ? _selectedLocation
                                    : _cleanLocations.first,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFEA580C)),
                                items: _cleanLocations.map((loc) {
                                  return DropdownMenuItem(
                                    value: loc,
                                    child: Text(loc, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedLocation = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nomor Kamar / Detail Ruangan:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _roomDetailController,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Contoh: Kamar 3 (Lantai 2)',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              fillColor: Colors.white,
                              filled: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFFDBA74)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFFDBA74)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Payment Method
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

                  _buildPaymentCard(
                    id: 'qris',
                    title: 'QRIS Dinamis',
                    subtitle: 'Scan QRIS saat pesanan diantar atau via kasir',
                    icon: Icons.qr_code_2_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentCard(
                    id: 'cash',
                    title: 'Tunai (COD)',
                    subtitle: 'Bayar tunai kepada petugas saat pesanan diterima',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF059669),
                  ),

                  const SizedBox(height: 18),

                  // General Order Note
                  const Text(
                    'CATATAN TAMBAHAN (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _orderNotesController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Titip di meja perawat / pos jika sedang tindakan...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      _formatRupiah(_totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Kirim Pesanan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(CanteenCartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _formatRupiah(item.price),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFEA580C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Mini Stepper
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => widget.onUpdateQty(item, item.qty - 1),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.remove, size: 14, color: Color(0xFF475569)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () => widget.onUpdateQty(item, item.qty + 1),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              Text(
                _formatRupiah(item.subtotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          // Optional Note textfield on tap
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showItemNoteDialog(item),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 15, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.notes != null && item.notes!.isNotEmpty
                        ? 'Catatan: "${item.notes}"'
                        : '+ Tambah catatan (pedas, manis, dll)',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: item.notes != null && item.notes!.isNotEmpty ? const Color(0xFFEA580C) : Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showItemNoteDialog(CanteenCartItem item) {
    final noteController = TextEditingController(text: item.notes ?? '');
    final quickSuggestions = [
      '🧊 Tanpa Es',
      '🧊 Es Sedikit',
      '🍯 Sedikit Manis',
      '🌶️ Tidak Pedas',
      '🌶️ Pedas Sedang',
      '🥢 Sambal Dipisah',
      '🥡 Bungkus Rapi',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header with Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFFEA580C),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan Pesanan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA580C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              item.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Quick Suggestions Chips
                  const Text(
                    'Saran Cepat:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickSuggestions.map((suggestion) {
                      final isSelected = noteController.text.contains(suggestion);
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            final current = noteController.text.trim();
                            if (current.isEmpty) {
                              noteController.text = suggestion;
                            } else if (!current.contains(suggestion)) {
                              noteController.text = '$current, $suggestion';
                            } else {
                              noteController.text = current.replaceAll(', $suggestion', '').replaceAll('$suggestion, ', '').replaceAll(suggestion, '').trim();
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.2 : 1,
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Custom Input Box
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    autofocus: false,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Tulis permintaan khusus lainnya di sini...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFEA580C), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      if (noteController.text.isNotEmpty) ...[
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                noteController.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onUpdateItemNote(item, noteController.text.trim());
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                          icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Simpan Catatan',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _paymentMethod == id;

    return InkWell(
      onTap: () => setState(() => _paymentMethod = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCBD5E1),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check, size: 12, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

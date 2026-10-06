import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/screen/menu/kantin/models/canteen_model.dart';
import 'package:rsia_employee_app/screen/menu/kantin/services/canteen_service.dart';
import 'package:rsia_employee_app/screen/menu/kantin/widgets/canteen_product_card.dart';
import 'package:rsia_employee_app/screen/menu/kantin/widgets/canteen_cart_bottom_sheet.dart';
import 'package:rsia_employee_app/screen/menu/kantin/widgets/canteen_order_detail_sheet.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class KantinScreen extends StatefulWidget {
  const KantinScreen({super.key});

  @override
  State<KantinScreen> createState() => _KantinScreenState();
}

class _KantinScreenState extends State<KantinScreen> {
  bool _isLoading = true;
  List<CanteenCategory> _categories = [];
  List<CanteenProduct> _products = [];
  List<String> _locations = [];
  List<CanteenOrderModel> _myOrders = [];

  int _selectedCategoryId = 0; // 0 = Semua
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Keranjang
  final Map<int, CanteenCartItem> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        CanteenService.fetchMenu(),
        CanteenService.fetchLocations(),
        CanteenService.fetchMyOrders(),
      ]);

      final menuData = results[0] as Map<String, dynamic>;
      _categories = menuData['categories'] as List<CanteenCategory>? ?? [];
      _products = menuData['products'] as List<CanteenProduct>? ?? [];
      _locations = (results[1] as List<String>)
          .where((l) => !l.toLowerCase().contains('mess'))
          .map((l) => l.replaceAll('(Ranapp)', '(Ranap)').replaceAll('(Rana)', '(Ranap)'))
          .toList();
      _myOrders = results[2] as List<CanteenOrderModel>;
    } catch (e) {
      debugPrint('KantinScreen::_loadData error: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<CanteenProduct> get _filteredProducts {
    return _products.where((p) {
      final matchCategory = _selectedCategoryId == 0 || p.categoryId == _selectedCategoryId;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  int get _totalCartItems {
    return _cart.values.fold(0, (sum, item) => sum + item.qty);
  }

  double get _totalCartAmount {
    return _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  }

  void _addToCart(CanteenProduct product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.qty++;
      } else {
        _cart[product.id] = CanteenCartItem(
          product: product,
          unitId: product.baseUnitId,
          unitName: product.baseUnitName,
          price: product.priceEmployee,
          qty: 1,
        );
      }
    });
  }

  void _updateCartQty(CanteenCartItem item, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _cart.remove(item.product.id);
      } else {
        item.qty = newQty;
      }
    });
  }

  void _updateCartItemNote(CanteenCartItem item, String note) {
    setState(() {
      item.notes = note;
    });
  }

  void _openCartBottomSheet() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CanteenCartBottomSheet(
        cartItems: _cart.values.toList(),
        availableLocations: _locations,
        onUpdateQty: (item, newQty) {
          _updateCartQty(item, newQty);
        },
        onUpdateItemNote: (item, note) {
          _updateCartItemNote(item, note);
        },
        onOrderSuccess: (order) {
          setState(() {
            _cart.clear();
          });
          Msg.success(context, 'Pesanan ${order.orderNumber} berhasil dikirim!');
          _loadData();
          _openOrderDetail(order);
        },
      ),
    );
  }

  void _openOrderDetail(CanteenOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CanteenOrderDetailSheet(
        order: order,
        onRefreshNeeded: _loadData,
      ),
    );
  }

  void _showMyOrdersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
              child: Row(
                children: [
                  const Text('Riwayat Pesanan Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: _myOrders.isEmpty
                  ? const Center(
                      child: Text('Belum ada pesanan aktif.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _myOrders.length,
                      itemBuilder: (c, i) {
                        final order = _myOrders[i];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openOrderDetail(order);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
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
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFEA580C), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${order.orderNumber}',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        order.deliveryLocation ?? 'Ambil Sendiri',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      order.statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: order.status == 'completed' ? const Color(0xFF15803D) : const Color(0xFFEA580C),
                                      ),
                                    ),
                                    Text(
                                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.totalAmount),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersCount = _myOrders.where((o) => !['completed', 'cancelled'].contains(o.status)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Kantin RSIA',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // My Orders Button with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showMyOrdersSheet,
                tooltip: 'Pesanan Saya',
                icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF475569)),
              ),
              if (activeOrdersCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$activeOrdersCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEA580C)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFEA580C),
              child: CustomScrollView(
                slivers: [
                  // Top Banner: Hospitality Greeting & Info
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFED7AA).withOpacity(0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEA580C).withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text('🍱', style: TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Order Mandiri Kantin',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Antar ke Ruangan',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Pesan praktis langsung diantar ke ruangan kerja Anda.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari makanan, minuman, atau snack...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[400]),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category Filter Horizontal Pills
                  SliverToBoxAdapter(
                    child: Container(
                      height: 48,
                      margin: const EdgeInsets.only(top: 8),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        children: [
                          _buildCategoryPill(id: 0, title: 'Semua Menu'),
                          ..._categories.map((c) => _buildCategoryPill(id: c.id, title: c.name)),
                        ],
                      ),
                    ),
                  ),

                  // Product Grid or Empty State
                  _filteredProducts.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🍽️', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 12),
                                const Text(
                                  'Menu Tidak Ditemukan',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'Tidak ada menu yang sesuai dengan "$_searchQuery".'
                                      : 'Belum ada menu pada kategori ini.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(16, 6, 16, _cart.isNotEmpty ? 90 : 20),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.82,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = _filteredProducts[index];
                                final cartItem = _cart[product.id];
                                final qty = cartItem?.qty ?? 0;

                                return CanteenProductCard(
                                  product: product,
                                  cartQty: qty,
                                  onAdd: () => _addToCart(product),
                                  onIncrement: () => _updateCartQty(cartItem!, qty + 1),
                                  onDecrement: () => _updateCartQty(cartItem!, qty - 1),
                                );
                              },
                              childCount: _filteredProducts.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),

      // Floating Cart Action Pill
      bottomNavigationBar: _cart.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openCartBottomSheet,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_totalCartItems item',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Pesanan',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                                Text(
                                  _formatRupiah(_totalCartAmount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Row(
                            children: [
                              Text(
                                'Lihat Pesanan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryPill({required int id, required String title}) {
    final isSelected = _selectedCategoryId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedCategoryId = id),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEA580C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFEA580C) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

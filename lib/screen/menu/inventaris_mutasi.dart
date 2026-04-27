import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class InventarisMutasi extends StatefulWidget {
  const InventarisMutasi({super.key});

  @override
  State<InventarisMutasi> createState() => _InventarisMutasiState();
}

class _InventarisMutasiState extends State<InventarisMutasi> {
  bool isLoading = true;
  List assets = [];
  List filteredAssets = [];
  List rooms = [];
  TextEditingController searchController = TextEditingController();
  TextEditingController roomSearchController = TextEditingController();
  
  String? selectedRoom;
  String? selectedRoomName;
  String? _selectedTargetRoomInModal;
  final TextEditingController _mutationNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchAssets(),
      _fetchRooms(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchAssets({String? search, String? roomId}) async {
    setState(() => isLoading = true);
    try {
      String query = "/aset/inventaris?limit=100";
      if (search != null && search.isNotEmpty) query += "&search=$search";
      if (roomId != null) query += "&id_ruang=$roomId";

      var res = await Api().getData(query);
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          assets = body['data']['data'] ?? [];
          filteredAssets = assets;
        });
      }
    } catch (e) {
      debugPrint("Error fetching assets: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchRooms() async {
    try {
      var res = await Api().getData('/aset/ruang?limit=200');
      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        setState(() {
          rooms = body['data']['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
  }

  void _onSearchChanged(String query) {
    _fetchAssets(search: query, roomId: selectedRoom);
  }

  void _showRoomFilter() {
    roomSearchController.clear();
    List filteredRooms = rooms;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: Column(
              children: [
                _buildModalHandle(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Expanded(child: Text("Pilih Ruangan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                      if (selectedRoom != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedRoom = null;
                              selectedRoomName = null;
                              _onSearchChanged(searchController.text);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Reset", style: TextStyle(color: Colors.red)),
                        )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: roomSearchController,
                    onChanged: (val) {
                      setModalState(() {
                        filteredRooms = rooms.where((r) => r['nama_ruang'].toString().toLowerCase().contains(val.toLowerCase())).toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari ruangan...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      bool isSelected = selectedRoom == room['id_ruang'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                          child: Icon(Icons.meeting_room, color: isSelected ? primaryColor : Colors.grey, size: 20),
                        ),
                        title: Text(room['nama_ruang'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? primaryColor : Colors.black87)),
                        trailing: isSelected ? Icon(Icons.check_circle, color: primaryColor) : null,
                        onTap: () {
                          setState(() {
                            selectedRoom = room['id_ruang'];
                            selectedRoomName = room['nama_ruang'];
                            _onSearchChanged(searchController.text);
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : filteredAssets.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildAssetCard(filteredAssets[index]),
                          childCount: filteredAssets.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: false,
      title: const Text("Mutasi & Riwayat Aset", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withBlue(150)],
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: "Cari nama atau nomor aset...",
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _showRoomFilter,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedRoom != null ? primaryColor : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(Icons.filter_list, color: selectedRoom != null ? Colors.white : Colors.grey[600], size: 20),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetCard(Map asset) {
    String status = asset['status_barang'] ?? 'Ada';
    Color statusColor = _getStatusColor(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => _showAssetDetails(asset),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(asset['no_inventaris'] ?? '-', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            _buildStatusBadge(status, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(asset['barang']?['nama_barang'] ?? '-', 
                             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(asset['ruang']?['nama_ruang'] ?? 'Tanpa Ruangan', 
                                       style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }

  void _showAssetDetails(Map asset) {
    setState(() {
      _selectedTargetRoomInModal = null;
      _mutationNoteController.clear();
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildModalHandle(),
                  _buildDetailedHeader(asset),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: TabBar(
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey[400],
                      indicatorColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [Tab(text: "Riwayat"), Tab(text: "Mutasi")],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLogTab(asset['no_inventaris']),
                        _buildMutationTab(asset, setModalState),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildDetailedHeader(Map asset) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Icon(Icons.inventory_rounded, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset['barang']?['nama_barang'] ?? 'Aset', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A))),
                Text(asset['no_inventaris'] ?? '-', style: TextStyle(color: Colors.grey[500], fontSize: 13, letterSpacing: 1)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLogTab(String noInventaris) {
    return FutureBuilder(
      future: Api().getData('/aset/inventaris/log/$noInventaris'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final response = snapshot.data as http.Response?;
        if (!snapshot.hasData || response?.statusCode != 200) return const Center(child: Text("Gagal memuat riwayat"));

        List logs = json.decode(response!.body)['data'] ?? [];
        if (logs.isEmpty) return _buildEmptyLog();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: logs.length,
          itemBuilder: (context, index) => _buildTimelineItem(logs[index], index == logs.length - 1),
        );
      },
    );
  }

  Widget _buildTimelineItem(Map log, bool isLast) {
    Color color = _getCategoryColor(log['kategori']);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(_getCategoryIcon(log['kategori']), size: 14, color: color),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[200], margin: const EdgeInsets.symmetric(vertical: 4))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(log['kategori'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color, letterSpacing: 0.5)),
                      Text(DateFormat('dd MMM yyyy').format(DateTime.parse(log['tanggal'])), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[100]!)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['aktivitas'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text(log['detail'], style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4)),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Icon(Icons.person_pin, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(log['petugas']?['nama'] ?? log['nip'], style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutationTab(Map asset, Function setModalState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildLocationCard("Asal", asset['ruang']?['nama_ruang'] ?? 'N/A', Icons.outbox_rounded, Colors.orange),
            const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Center(child: Icon(Icons.arrow_downward_rounded, color: Colors.grey, size: 20))),
            _buildTargetRoomSelector(asset, setModalState),
            const SizedBox(height: 16),
            const Text("Keterangan Tambahan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            TextField(
              controller: _mutationNoteController,
              maxLines: 2,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Tuliskan alasan mutasi...",
                hintStyle: TextStyle(color: Colors.grey[300], fontSize: 12),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _handleMutation(asset['no_inventaris']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("PROSES MUTASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[400])),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
          ]),
        ],
      ),
    );
  }

  Widget _buildTargetRoomSelector(Map asset, Function setModalState) {
    return InkWell(
      onTap: () => _showRoomPickerForMutation(asset, setModalState),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedTargetRoomInModal != null ? primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _selectedTargetRoomInModal != null ? primaryColor : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.move_to_inbox_rounded, color: primaryColor, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Tujuan", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[400])),
                Text(_getTargetRoomName(_selectedTargetRoomInModal) ?? "Pilih Ruangan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _selectedTargetRoomInModal != null ? primaryColor : Colors.grey[300])),
              ]),
            ),
            Icon(Icons.unfold_more_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showRoomPickerForMutation(Map asset, Function setModalState) {
    List filteredRooms = rooms.where((r) => r['id_ruang'] != asset['id_ruang']).toList();
    TextEditingController pickerSearch = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setPickerState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
            child: Column(
              children: [
                _buildModalHandle(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: pickerSearch,
                    autofocus: true,
                    onChanged: (val) {
                      setPickerState(() {
                        filteredRooms = rooms.where((r) => r['id_ruang'] != asset['id_ruang'] && r['nama_ruang'].toString().toLowerCase().contains(val.toLowerCase())).toList();
                      });
                    },
                    decoration: InputDecoration(hintText: "Cari ruangan tujuan...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final r = filteredRooms[index];
                      return ListTile(
                        title: Text(r['nama_ruang'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          setModalState(() { _selectedTargetRoomInModal = r['id_ruang']; });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  String? _getTargetRoomName(String? id) {
    if (id == null) return null;
    try { return rooms.firstWhere((r) => r['id_ruang'] == id)['nama_ruang']; } catch (_) { return null; }
  }

  void _handleMutation(String noInventaris) async {
    if (_selectedTargetRoomInModal == null) {
      Msg.warning(context, "Silakan pilih ruang tujuan");
      return;
    }

    _showLoading(context);
    try {
      var res = await Api().postData({
        'no_inventaris': noInventaris,
        'id_ruang_tujuan': _selectedTargetRoomInModal,
        'keterangan': _mutationNoteController.text,
      }, '/aset/inventaris-mutasi');

      Navigator.pop(context);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        Navigator.pop(context);
        Msg.success(context, "Mutasi berhasil diproses");
        _fetchInitialData();
      } else {
        var body = json.decode(res.body);
        Msg.error(context, "Gagal: ${body['message']}");
      }
    } catch (e) {
      Navigator.pop(context);
      Msg.error(context, "Terjadi kesalahan: $e");
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => Center(child: CircularProgressIndicator(color: primaryColor)));
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Ada': return Colors.green;
      case 'Rusak': return Colors.red;
      case 'Hilang': return Colors.orange;
      case 'Perbaikan': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Mutasi': return Colors.blue;
      case 'Perbaikan': return Colors.red;
      case 'Pemeliharaan': return Colors.green;
      default: return Colors.indigo;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Mutasi': return Icons.move_up_rounded;
      case 'Perbaikan': return Icons.build_circle_rounded;
      case 'Pemeliharaan': return Icons.verified_user_rounded;
      default: return Icons.history_rounded;
    }
  }

  Widget _buildModalHandle() {
    return Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[200]), const SizedBox(height: 16), Text("Aset tidak ditemukan", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))]));
  }

  Widget _buildEmptyLog() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_rounded, size: 50, color: Colors.grey[100]), const SizedBox(height: 12), Text("Belum ada riwayat", style: TextStyle(color: Colors.grey[300], fontSize: 13))]));
  }
}

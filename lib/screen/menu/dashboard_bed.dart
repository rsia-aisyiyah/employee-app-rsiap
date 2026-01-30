import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';

class DashboardBed extends StatefulWidget {
  const DashboardBed({super.key});

  @override
  State<DashboardBed> createState() => _DashboardBedState();
}

class _DashboardBedState extends State<DashboardBed> {
  bool _isLoading = true;
  List _beds = [];
  Map _summary = {
    'total': 0,
    'tersedia': 0,
    'terisi': 0,
    'dibersihkan': 0,
  };

  final List<Map<String, String>> _categories = [
    {'id': 'ANAK', 'name': 'Anak'},
    {'id': 'KANDUNGAN', 'name': 'Kandungan'},
    {'id': 'KAMAR BERSALIN', 'name': 'Kamar Bersalin'},
    {'id': 'ICU', 'name': 'ICU'},
    {'id': 'ISOLASI', 'name': 'Isolasi'},
  ];

  List _classes = [];

  String _selectedCategory = '';
  String _selectedClass = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    // Load static filters first
    await Future.wait([
      _loadClasses(),
    ]);
    // Then load beds and calculate summary
    await _loadBeds();
    setState(() => _isLoading = false);
  }

  void _calculateSummary() {
    int total = 0;
    int tersedia = 0;
    int terisi = 0;
    int dibersihkan = 0;

    List filtered = _beds;
    if (_selectedCategory.isNotEmpty) {
      filtered =
          _beds.where((b) => _getBedCategory(b) == _selectedCategory).toList();
    }

    // We calculate based on the current filtered or whole list
    for (var bed in filtered) {
      total += (bed['kapasitas'] as num? ?? 0).toInt();
      tersedia += (bed['tersedia'] as num? ?? 0).toInt();
      terisi += (bed['terisi'] as num? ?? 0).toInt();
      dibersihkan += (bed['dibersihkan'] as num? ?? 0).toInt();
    }

    setState(() {
      _summary = {
        'total': total,
        'tersedia': tersedia,
        'terisi': terisi,
        'dibersihkan': dibersihkan,
      };
    });
  }

  Future<void> _loadClasses() async {
    try {
      final res = await Api().getData("/bed-availability/classes");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _classes = (body['data'] as List).map((c) {
            if (c is Map) return c;
            return {'id': c.toString(), 'name': c.toString()};
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Classes error: $e");
    }
  }

  Future<void> _loadBeds() async {
    try {
      String params = "?";
      if (_selectedClass.isNotEmpty) params += "kelas=$_selectedClass&";
      if (_selectedStatus.isNotEmpty) params += "status=$_selectedStatus&";

      final res = await Api().getData("/bed-availability$params");
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        _beds = body['data'];
        _calculateSummary();
      }
    } catch (e) {
      debugPrint("Beds error: $e");
    }
  }

  String _getBedCategory(Map bed) {
    String kdKamar = (bed['kd_kamar'] ?? '').toString().toUpperCase();
    String nmBangsal = (bed['nm_bangsal'] ?? '').toString().toUpperCase();

    if (kdKamar.contains('ISOLASI') || kdKamar.contains('ISO')) {
      return 'ISOLASI';
    } else if (kdKamar.contains('ICU') ||
        kdKamar.contains('ICCU') ||
        kdKamar.contains('PICU') ||
        kdKamar.contains('NICU')) {
      return 'ICU';
    } else if (kdKamar.contains('VK') || kdKamar.contains('BERSALIN')) {
      return 'KAMAR BERSALIN';
    } else if (kdKamar.contains('ANAK') ||
        kdKamar.contains('BAYI') ||
        kdKamar.contains('PERINA')) {
      return 'ANAK';
    } else if (kdKamar.contains('KANDUNGAN') || kdKamar.contains('KEBIDANAN')) {
      return 'KANDUNGAN';
    }

    return nmBangsal.replaceAll(RegExp(r'\s*\d+\s*$'), '').trim();
  }

  // Hierarchical grouping: Category -> Class -> List of Beds
  Map<String, Map<String, List<Map<String, dynamic>>>> _getGroupedBeds() {
    Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

    List filtered = _beds;
    if (_selectedCategory.isNotEmpty) {
      filtered =
          _beds.where((b) => _getBedCategory(b) == _selectedCategory).toList();
    }

    for (var bed in filtered) {
      String category = _getBedCategory(bed);
      String kelas = bed['kelas'] ?? 'Tanpa Kelas';

      if (!grouped.containsKey(category)) {
        grouped[category] = {};
      }
      if (!grouped[category]!.containsKey(kelas)) {
        grouped[category]![kelas] = [];
      }
      grouped[category]![kelas]!.add(Map<String, dynamic>.from(bed));
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        title: const Text(
          "Ketersediaan Kamar",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () {
              // Show legend or info
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background Blue Area (Top Summary)
          Column(
            children: [
              _buildTopSummary(),
              const Spacer(),
            ],
          ),

          // 2. Content Layer (Filters + Bed Grid)
          Positioned.fill(
            top: 140, // Pull up more to overlap the blue header
            child: Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: Container(
                    color: bgWhite, // Changed to White as requested
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                            onRefresh: _initData,
                            child: _beds.isEmpty
                                ? _buildEmptyState()
                                : _buildBedGrid(),
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

  Widget _buildTopSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 80),
      decoration: BoxDecoration(
        color: primaryColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.9],
          colors: [
            primaryColor,
            primaryColor.withAlpha(200),
          ],
        ),
      ),
      child: Row(
        children: [
          _buildSummaryBox(
            "Total",
            "${_summary['total'] ?? 0}",
            Colors.white.withOpacity(0.12),
            Icons.hotel_rounded,
            const [Color(0xFF64748B), Color(0xFF475569)],
          ),
          const SizedBox(width: 10),
          _buildSummaryBox(
            "Tersedia",
            "${_summary['tersedia'] ?? 0}",
            const Color(0xFF10B981).withOpacity(0.2),
            Icons.check_circle_outline_rounded,
            const [Color(0xFF10B981), Color(0xFF059669)],
          ),
          const SizedBox(width: 10),
          _buildSummaryBox(
            "Terisi",
            "${_summary['terisi'] ?? 0}",
            const Color(0xFFF43F5E).withOpacity(0.2),
            Icons.person_pin_rounded,
            const [Color(0xFFF43F5E), Color(0xFFE11D48)],
          ),
          const SizedBox(width: 10),
          _buildSummaryBox(
            "Cleaning",
            "${_summary['dibersihkan'] ?? 0}",
            Colors.orange.withOpacity(0.2),
            Icons.cleaning_services_rounded,
            const [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
      String label, String value, Color color, IconData icon, List<Color> bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
                fontSize: 8,
                letterSpacing: 0.5,
                textBaseline: TextBaseline.alphabetic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 25),
      decoration: BoxDecoration(
        color: bgWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip("Semua Kategori", _categories, _selectedCategory,
                (val) {
              setState(() {
                _selectedCategory = val;
                _calculateSummary();
              });
            }),
            const SizedBox(width: 8),
            _buildFilterChip("Semua Kelas", _classes, _selectedClass, (val) {
              setState(() {
                _selectedClass = val;
                _loadBeds();
              });
            }),
            const SizedBox(width: 8),
            _buildFilterChip(
                "Status",
                [
                  {'id': 'KOSONG', 'name': 'Tersedia'},
                  {'id': 'ISI', 'name': 'Terisi'},
                  {'id': 'DIBERSIHKAN', 'name': 'Dibersihkan'},
                  {'id': 'DIBOOKING', 'name': 'Dibooking'},
                ],
                _selectedStatus, (val) {
              setState(() {
                _selectedStatus = val;
                _loadBeds();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, List items, String current, Function(String) onSelect) {
    bool isActive = current.isNotEmpty;
    String displayLabel = label;
    if (isActive) {
      dynamic found;
      for (var i in items) {
        if (i is Map) {
          if ((i['kd_bangsal'] ?? i['id'] ?? i['kelas'] ?? i.toString()) ==
              current) {
            found = i;
            break;
          }
        } else if (i.toString() == current) {
          found = i;
          break;
        }
      }

      if (found != null) {
        if (found is Map) {
          displayLabel = found['nm_bangsal'] ??
              found['name'] ??
              found['kelas'] ??
              found.toString();
        } else {
          displayLabel = found.toString();
        }
      }
    }

    return GestureDetector(
      onTap: () => _showFilterModal(label, items, (val) => onSelect(val)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            if (isActive)
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
          border: Border.all(
            color: isActive ? primaryColor : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: isActive ? Colors.white70 : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(String title, List items, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text("Semua"),
              onTap: () {
                onSelect("");
                Navigator.pop(context);
              },
            ),
            ...items.map((item) {
              String name = "";
              String id = "";

              if (item is Map) {
                name = item['nm_bangsal'] ??
                    item['name'] ??
                    item['kelas'] ??
                    item.toString();
                id = item['kd_bangsal'] ??
                    item['id'] ??
                    item['kelas'] ??
                    item.toString();
              } else {
                name = item.toString();
                id = item.toString();
              }

              return ListTile(
                title: Text(name),
                onTap: () {
                  onSelect(id);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bed_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Tidak ada tempat tidur ditemukan",
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBedGrid() {
    final grouped = _getGroupedBeds();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        String categoryName = grouped.keys.elementAt(index);
        Map<String, List<Map<String, dynamic>>> classes =
            grouped[categoryName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 0, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_rounded,
                      size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 10),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),

            // Sub-sections for each Class (Level 2)
            ...classes.entries.map((entry) {
              String className = entry.key;
              List beds = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 4, top: 18, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          className,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.grey[800],
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "•",
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${beds.length} Bed",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: beds.length,
                    itemBuilder: (context, bIdx) {
                      var bed = beds[bIdx];
                      return _buildBedCard(bed);
                    },
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildBedCard(Map bed) {
    String status = bed['status_kamar'] ?? 'KOSONG';
    String displayStatus = 'TERSEDIA';
    Color color = const Color(0xFF10B981);
    IconData icon = Icons.check_circle_rounded;

    if (status == 'ISI') {
      displayStatus = 'TERISI';
      color = const Color(0xFFF43F5E);
      icon = Icons.cancel_rounded;
    } else if (status == 'DIBERSIHKAN') {
      displayStatus = 'CLEANING';
      color = Colors.orange[700]!;
      icon = Icons.cleaning_services_rounded;
    } else if (status == 'DIBOOKING') {
      displayStatus = 'BOOKED';
      color = Colors.blue[600]!;
      icon = Icons.bookmark_rounded;
    }

    return InkWell(
      onTap: () => _showBedDetail(bed),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.grey[300]!, width: 1.5), // Softer, visible border
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withOpacity(0.08), // Increased shadow opacity
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bed['kd_kamar'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bed['kelas'] ?? '-',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    bed['status_kamar'] == 'ISI' ? "X" : "V",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 6,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 10, color: color),
                  const SizedBox(width: 4),
                  Text(
                    displayStatus,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Status Kamar",
              style: TextStyle(
                fontSize: 6,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBedDetail(Map bed) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Detail Tempat Tidur",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.meeting_room, "Kamar/Bed", bed['kd_kamar']),
              _buildDetailRow(
                  Icons.local_hospital, "Bangsal", bed['nm_bangsal']),
              _buildDetailRow(Icons.star_outline, "Kelas", bed['kelas']),
              _buildDetailRow(
                  Icons.info_outline, "Status", bed['status_kamar']),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value ?? '-',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

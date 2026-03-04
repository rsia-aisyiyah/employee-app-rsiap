import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class SuratInternalAddScreen extends StatefulWidget {
  const SuratInternalAddScreen({super.key});

  @override
  State<SuratInternalAddScreen> createState() => _SuratInternalAddScreenState();
}

class _SuratInternalAddScreenState extends State<SuratInternalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  bool isSaving = false;

  // Form Controllers
  TextEditingController perihalCtrl = TextEditingController();
  TextEditingController tanggalCtrl = TextEditingController(); // Tgl Terbit
  TextEditingController catatanCtrl = TextEditingController();

  // Undangan Controllers
  bool withUndangan = false;
  TextEditingController undanganTglwaktuCtrl = TextEditingController();
  TextEditingController undanganLokasiCtrl = TextEditingController();
  TextEditingController undanganDeskripsiCtrl =
      TextEditingController(); // Agenda

  String? selectedPj; // NIK Penanggung Jawab
  String? selectedPjNama; // Nama Penanggung Jawab
  List<Map<String, dynamic>> selectedPenerima = [];
  bool isLoadingPegawai = false;

  @override
  void initState() {
    super.initState();
    tanggalCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _showPegawaiPicker() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PegawaiSearchModal(),
    );

    if (result != null && result is Map) {
      setState(() {
        selectedPj = result['nik'];
        selectedPjNama = result['nama'];
      });
    }
  }

  void _showPenerimaPicker() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PenerimaSearchModal(
        initialSelected: List<Map<String, dynamic>>.from(selectedPenerima),
      ),
    );

    if (result != null && result is List) {
      setState(() {
        selectedPenerima = List<Map<String, dynamic>>.from(result);
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller,
      {bool withTime = false}) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (withTime) {
        if (!mounted) return;
        TimeOfDay? timePicked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (timePicked != null) {
          final dt = DateTime(picked.year, picked.month, picked.day,
              timePicked.hour, timePicked.minute);
          controller.text = DateFormat('yyyy-MM-dd HH:mm').format(dt);
        }
      } else {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }
  }

  Future<void> _saveSurat() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedPj == null) {
      Msg.warning(context, "Silakan pilih Penanggung Jawab");
      return;
    }

    setState(() => isSaving = true);

    var payload = <String, dynamic>{
      "perihal": perihalCtrl.text,
      "tgl_terbit": tanggalCtrl.text,
      "pj": selectedPj,
      "catatan": catatanCtrl.text,
      "status": "pengajuan"
    };

    if (withUndangan) {
      payload["undangan"] = {
        "tanggal": undanganTglwaktuCtrl.text,
        "lokasi": undanganLokasiCtrl.text,
        "deskripsi": undanganDeskripsiCtrl.text,
      };
    }

    try {
      var res = await Api().postData(payload, '/surat/internal');
      var body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Save penerima if withUndangan and penerima is not empty
        if (withUndangan &&
            selectedPenerima.isNotEmpty &&
            body['data'] != null) {
          int savedSuratId = body['data']['id'];
          // Fetch the detail to get the undangan ID
          var detailRes = await Api()
              .getData('/surat/internal/$savedSuratId?include=undangan');
          if (detailRes.statusCode == 200) {
            var detailBody = json.decode(detailRes.body);
            var undangan = detailBody['data']['undangan'];
            if (undangan != null && undangan['id'] != null) {
              List<String> niks =
                  selectedPenerima.map((e) => e['nik'].toString()).toList();
              var penerimaPayload = {
                "undangan_id": undangan['id'],
                "penerima": niks
              };
              await Api().postData(penerimaPayload, '/undangan/penerima');
            }
          }
        }

        if (mounted) {
          Msg.success(context, "Surat berhasil diajukan");
          Navigator.pop(context, true); // Return true to refresh list
        }
      } else {
        Msg.error(context, body['message'] ?? "Gagal menyimpan surat");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan koneksi");
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 10,
          bottom: 20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 5),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Buat Surat Internal",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "Pengajuan surat baru",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Form Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Perihal"),
                          TextFormField(
                            controller: perihalCtrl,
                            decoration:
                                _inputDecoration("Masukkan perihal surat"),
                            validator: (v) =>
                                v!.isEmpty ? "Perihal wajib diisi" : null,
                          ),
                          const SizedBox(height: 20),
                          _buildInputLabel("Tanggal Terbit"),
                          TextFormField(
                            controller: tanggalCtrl,
                            readOnly: true,
                            onTap: () => _selectDate(tanggalCtrl),
                            decoration:
                                _inputDecoration("Pilih tanggal").copyWith(
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 20),
                            ),
                            validator: (v) =>
                                v!.isEmpty ? "Tanggal wajib diisi" : null,
                          ),
                          const SizedBox(height: 20),
                          _buildInputLabel("Penanggung Jawab"),
                          InkWell(
                            onTap: _showPegawaiPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_search,
                                      color: primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedPjNama != null
                                          ? "$selectedPjNama ($selectedPj)"
                                          : "Klik untuk mencari PJ",
                                      style: TextStyle(
                                        color: selectedPjNama != null
                                            ? Colors.black
                                            : Colors.grey[500],
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInputLabel("Catatan"),
                          TextFormField(
                            controller: catatanCtrl,
                            maxLines: 3,
                            decoration:
                                _inputDecoration("Catatan tambahan (opsional)"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Undangan Toggle Section
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeColor: primaryColor,
                            title: const Text(
                              "Sertakan Undangan Rapat",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            subtitle: const Text(
                                "Aktifkan jika surat ini memuat agenda pertemuan",
                                style: TextStyle(fontSize: 12)),
                            value: withUndangan,
                            onChanged: (val) {
                              setState(() => withUndangan = val);
                            },
                          ),
                          if (withUndangan)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  _buildInputLabel("Waktu Pertemuan"),
                                  TextFormField(
                                    controller: undanganTglwaktuCtrl,
                                    readOnly: true,
                                    onTap: () => _selectDate(
                                        undanganTglwaktuCtrl,
                                        withTime: true),
                                    decoration: _inputDecoration(
                                            "Pilih tanggal & waktu")
                                        .copyWith(
                                      suffixIcon: const Icon(Icons.access_time,
                                          size: 20),
                                    ),
                                    validator: (v) => withUndangan && v!.isEmpty
                                        ? "Waktu wajib diisi"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputLabel("Lokasi"),
                                  TextFormField(
                                    controller: undanganLokasiCtrl,
                                    decoration: _inputDecoration(
                                        "Ex: Ruang Rapat Lt. 2"),
                                    validator: (v) => withUndangan && v!.isEmpty
                                        ? "Lokasi wajib diisi"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputLabel("Agenda Pokok"),
                                  TextFormField(
                                    controller: undanganDeskripsiCtrl,
                                    maxLines: 3,
                                    decoration: _inputDecoration(
                                        "Deskripsi agenda kegiatan..."),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInputLabel("Penerima Undangan"),
                                  if (selectedPenerima.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: selectedPenerima
                                            .map((p) => Chip(
                                                  label: Text(p['nama'],
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white)),
                                                  backgroundColor: primaryColor,
                                                  deleteIcon: const Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white),
                                                  onDeleted: () {
                                                    setState(() {
                                                      selectedPenerima
                                                          .removeWhere((item) =>
                                                              item['nik'] ==
                                                              p['nik']);
                                                    });
                                                  },
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: OutlinedButton.icon(
                                      onPressed: _showPenerimaPicker,
                                      icon: const Icon(Icons.person_add,
                                          size: 18),
                                      label: const Text("Tambah Penerima",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryColor,
                                        side: BorderSide(
                                            color: primaryColor, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar Action
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveSurat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text(
                        "AJUKAN SURAT INTERNAL",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PegawaiSearchModal extends StatefulWidget {
  const _PegawaiSearchModal({Key? key}) : super(key: key);

  @override
  State<_PegawaiSearchModal> createState() => _PegawaiSearchModalState();
}

class _PegawaiSearchModalState extends State<_PegawaiSearchModal> {
  TextEditingController searchCtrl = TextEditingController();
  List pegawaiList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData([String query = '']) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final box = GetStorage();
      String? depCode = box.read('dep');

      String endpoint = '/pegawai';
      if (query.isNotEmpty) {
        endpoint += '/search?q=$query';
      }

      if (depCode != null && depCode.isNotEmpty && depCode != 'null') {
        endpoint += endpoint.contains('?') ? '&' : '?';
        endpoint += 'filter[departemen]=$depCode';
      }

      var res = await Api().getData(endpoint);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (mounted) {
          setState(() {
            pegawaiList = body['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Gagal memuat data pegawai';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan jaringan';
          isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchCtrl.text == val && mounted) {
        _fetchData(val);
      }
    });
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: searchCtrl,
          decoration: InputDecoration(
            hintText: "Cari nama atau NIK...",
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            isDense: true,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Pilih Penanggung Jawab",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : RefreshIndicator(
                        onRefresh: () => _fetchData(searchCtrl.text),
                        child: pegawaiList.isEmpty
                            ? Center(
                                child: Text(
                                  searchCtrl.text.isEmpty
                                      ? "Daftar pegawai kosong"
                                      : "Pegawai tidak ditemukan",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: pegawaiList.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  var emp = pegawaiList[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          primaryColor.withOpacity(0.1),
                                      child: Text(
                                        emp['nama']?[0] ?? '?',
                                        style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      emp['nama'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      "${emp['nik']} • ${emp['departemen'] ?? '-'}",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context, {
                                        'nik': emp['nik'],
                                        'nama': emp['nama']
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PenerimaSearchModal extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelected;
  const _PenerimaSearchModal({Key? key, required this.initialSelected})
      : super(key: key);

  @override
  State<_PenerimaSearchModal> createState() => _PenerimaSearchModalState();
}

class _PenerimaSearchModalState extends State<_PenerimaSearchModal> {
  TextEditingController searchCtrl = TextEditingController();
  List pegawaiList = [];
  bool isLoading = true;
  String errorMessage = '';
  List<Map<String, dynamic>> currentSelected = [];

  @override
  void initState() {
    super.initState();
    currentSelected = List<Map<String, dynamic>>.from(widget.initialSelected);
    _fetchData();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData([String query = '']) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String endpoint = query.isEmpty ? '/pegawai' : '/pegawai/search?q=$query';
      var res = await Api().getData(endpoint);

      if (res.statusCode == 200) {
        var body = json.decode(res.body);
        if (mounted) {
          setState(() {
            pegawaiList = body['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => errorMessage = 'Gagal memuat data pegawai');
      }
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Terjadi kesalahan jaringan');
    }
  }

  void _onSearchChanged(String val) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchCtrl.text == val && mounted) {
        _fetchData(val);
      }
    });
  }

  bool _isSelected(String nik) {
    return currentSelected.any((element) => element['nik'] == nik);
  }

  void _toggleSelection(Map<String, dynamic> emp) {
    setState(() {
      if (_isSelected(emp['nik'])) {
        currentSelected.removeWhere((element) => element['nik'] == emp['nik']);
      } else {
        currentSelected.add({'nik': emp['nik'], 'nama': emp['nama']});
      }
    });
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: searchCtrl,
          decoration: InputDecoration(
            hintText: "Cari nama atau NIK...",
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            isDense: true,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tambah Penerima",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${currentSelected.length} dipilih",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 15),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : RefreshIndicator(
                        onRefresh: () => _fetchData(searchCtrl.text),
                        child: pegawaiList.isEmpty
                            ? Center(
                                child: Text(
                                  searchCtrl.text.isEmpty
                                      ? "Daftar pegawai kosong"
                                      : "Pegawai tidak ditemukan",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: pegawaiList.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  var emp = pegawaiList[index];
                                  bool selected = _isSelected(emp['nik']);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.all(8),
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: selected
                                          ? primaryColor
                                          : primaryColor.withOpacity(0.1),
                                      child: Text(
                                        emp['nama']?[0] ?? '?',
                                        style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : primaryColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(
                                      emp['nama'] ?? '-',
                                      style: TextStyle(
                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      "${emp['nik']} • ${emp['departemen'] ?? '-'}",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    trailing: selected
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : const Icon(Icons.add_circle_outline,
                                            color: Colors.grey),
                                    onTap: () => _toggleSelection(emp),
                                  );
                                },
                              ),
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, currentSelected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "KONFIRMASI PENERIMA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

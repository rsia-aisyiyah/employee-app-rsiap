import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class SuratEksternalAddScreen extends StatefulWidget {
  final Map? data;
  const SuratEksternalAddScreen({super.key, this.data});

  @override
  State<SuratEksternalAddScreen> createState() =>
      _SuratEksternalAddScreenState();
}

class _SuratEksternalAddScreenState extends State<SuratEksternalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();

  late TextEditingController _perihalController;
  late TextEditingController _alamatController;
  late TextEditingController _tglTerbitController;
  late TextEditingController _pjController;
  late TextEditingController _catatanController;

  String _status = "pengajuan";
  String? _pjName;
  bool _isEdit = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.data != null;

    _perihalController =
        TextEditingController(text: widget.data?['perihal'] ?? "");
    _alamatController =
        TextEditingController(text: widget.data?['alamat'] ?? "");

    String tgl = widget.data?['tgl_terbit'] ?? DateTime.now().toString();
    _tglTerbitController = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(DateTime.parse(tgl)));

    _pjController = TextEditingController(text: widget.data?['pj'] ?? "");
    _pjName = widget.data?['penanggung_jawab']?['nama'];

    _status = widget.data?['status'] ?? "pengajuan";
    _catatanController =
        TextEditingController(text: widget.data?['catatan'] ?? "");
  }

  @override
  void dispose() {
    _perihalController.dispose();
    _alamatController.dispose();
    _tglTerbitController.dispose();
    _pjController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Map<String, dynamic> payload = {
      'perihal': _perihalController.text,
      'alamat': _alamatController.text,
      'tgl_terbit': _tglTerbitController.text,
      'pj': _pjController.text,
      'status': _status,
      'catatan': _catatanController.text,
      'tanggal': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    try {
      var res;
      if (_isEdit) {
        String encodedNo = base64.encode(utf8.encode(widget.data!['no_surat']));
        res = await Api()
            .postData(payload, "/surat/eksternal/$encodedNo?_method=PUT");
      } else {
        res = await Api().postData(payload, "/surat/eksternal/store");
      }

      var body = json.decode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Msg.success(context, body['message'] ?? "Berhasil menyimpan data");
        Navigator.pop(context, true);
      } else {
        Msg.error(context, body['message'] ?? "Gagal menyimpan data");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _openPjPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PegawaiSearchModal(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _pjController.text = value['nik'];
          _pjName = value['nama'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title:
            Text(_isEdit ? "Edit Surat Eksternal" : "Tambah Surat Eksternal"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel("Perihal"),
              TextFormField(
                controller: _perihalController,
                decoration: _inputDecoration("Masukkan perihal surat"),
                validator: (v) =>
                    v!.isEmpty ? "Perihal tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              _buildInputLabel("Alamat / Instansi Tujuan"),
              TextFormField(
                controller: _alamatController,
                maxLines: 3,
                decoration:
                    _inputDecoration("Masukkan alamat atau instansi tujuan"),
                validator: (v) =>
                    v!.isEmpty ? "Alamat tidak boleh kosong" : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    flex: _isEdit ? 1 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Tanggal Terbit"),
                        TextFormField(
                          controller: _tglTerbitController,
                          readOnly: true,
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.parse(_tglTerbitController.text),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _tglTerbitController.text =
                                    DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                          decoration:
                              _inputDecoration("Pilih tanggal").copyWith(
                            suffixIcon:
                                const Icon(Icons.calendar_today, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEdit) const SizedBox(width: 15),
                  if (_isEdit)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Status"),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: _inputDecoration("Pilih status"),
                            items:
                                ["pengajuan", "disetujui", "ditolak"].map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child:
                                    Text(s[0].toUpperCase() + s.substring(1)),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              _buildInputLabel("Penanggung Jawab"),
              InkWell(
                onTap: _openPjPicker,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_search, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pjName != null
                              ? "$_pjName (${_pjController.text})"
                              : "Klik untuk mencari PJ",
                          style: TextStyle(
                            color: _pjName != null
                                ? Colors.black
                                : Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              // Hidden field only for validation
              Container(
                height: 0,
                child: TextFormField(
                  controller: _pjController,
                  validator: (v) => v!.isEmpty ? "PJ wajib dipilih" : null,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 20),

              _buildInputLabel("Catatan"),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: _inputDecoration("Tambahkan catatan opsional"),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEdit ? "SIMPAN PERUBAHAN" : "SIMPAN SURAT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class _PegawaiSearchModal extends StatefulWidget {
  const _PegawaiSearchModal();

  @override
  State<_PegawaiSearchModal> createState() => _PegawaiSearchModalState();
}

class _PegawaiSearchModalState extends State<_PegawaiSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData("");
  }

  Future<void> _fetchData(String query) async {
    setState(() => _isLoading = true);
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
        setState(() {
          _results = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error searching PJ: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Cari Penanggung Jawab",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                // Debounce simple
                _fetchData(v);
              },
              decoration: InputDecoration(
                hintText: "Cari nama atau NIK...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      var p = _results[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Text(p['nama'][0],
                              style: TextStyle(color: primaryColor)),
                        ),
                        title: Text(p['nama']),
                        subtitle: Text(p['nik']),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

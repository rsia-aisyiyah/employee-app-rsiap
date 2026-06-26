import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class DiklatPengajuanForm extends StatefulWidget {
  const DiklatPengajuanForm({super.key});

  @override
  State<DiklatPengajuanForm> createState() => _DiklatPengajuanFormState();
}

class _DiklatPengajuanFormState extends State<DiklatPengajuanForm> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  bool isSubmitting = false;

  // Form Controllers
  final TextEditingController _namaKegiatanController = TextEditingController();
  final TextEditingController _tempatController = TextEditingController();
  final TextEditingController _penyelenggaraController = TextEditingController();
  final TextEditingController _jplController = TextEditingController();
  final TextEditingController _skpController = TextEditingController();
  final TextEditingController _nomorController = TextEditingController();
  final TextEditingController _materiController = TextEditingController();

  DateTime? _tglMulai;
  DateTime? _tglAkhir;
  String _selectedPeran = 'Peserta';
  File? _selectedFile;
  String? _selectedFileName;
  int _selectedFileSize = 0;

  @override
  void dispose() {
    _namaKegiatanController.dispose();
    _tempatController.dispose();
    _penyelenggaraController.dispose();
    _jplController.dispose();
    _skpController.dispose();
    _nomorController.dispose();
    _materiController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        int size = await file.length();
        int maxSize = 5 * 1024 * 1024; // 5MB

        if (size > maxSize) {
          if (mounted) {
            Msg.warning(context, "Ukuran file sertifikat maksimal adalah 5MB");
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = size;
        });
      }
    } catch (e) {
      if (mounted) {
        Msg.error(context, "Gagal memilih file: $e");
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _selectedFileSize = 0;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }

  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tglMulai = picked;
          // Reset tgl akhir jika tgl akhir berada sebelum tgl mulai baru
          if (_tglAkhir != null && _tglAkhir!.isBefore(_tglMulai!)) {
            _tglAkhir = null;
          }
        } else {
          _tglAkhir = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      Msg.warning(context, "Dokumen Sertifikat wajib diunggah sebagai bukti");
      return;
    }

    if (_tglMulai == null) {
      Msg.warning(context, "Tanggal mulai pelatihan wajib diisi");
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      var sub = box.read('sub');
      var resUser = await Api().getData("/pegawai/$sub");

      if (resUser.statusCode != 200) {
        throw "Gagal memverifikasi akun karyawan";
      }

      var bodyUser = json.decode(resUser.body);
      String nik = bodyUser['data']['nik'];

      // Fields parameters
      Map<String, String> fields = {
        'nik': nik,
        'nama_kegiatan': _namaKegiatanController.text.trim(),
        'tempat': _tempatController.text.trim(),
        'tgl_mulai': DateFormat('yyyy-MM-dd').format(_tglMulai!),
        'peserta': _selectedPeran,
      };

      if (_tglAkhir != null) {
        fields['tgl_akhir'] = DateFormat('yyyy-MM-dd').format(_tglAkhir!);
      }
      if (_penyelenggaraController.text.isNotEmpty) {
        fields['penyelenggara'] = _penyelenggaraController.text.trim();
      }
      if (_jplController.text.isNotEmpty) {
        fields['jpl'] = _jplController.text.trim();
      }
      if (_skpController.text.isNotEmpty) {
        fields['skp'] = _skpController.text.trim();
      }
      if (_nomorController.text.isNotEmpty) {
        fields['nomor'] = _nomorController.text.trim();
      }
      if (_materiController.text.isNotEmpty) {
        fields['materi'] = _materiController.text.trim();
      }

      var res = await Api().postMultipart(
        fields,
        _selectedFile!,
        '/diklat/pengajuan/store',
        fieldName: 'file',
      );

      var body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          Msg.success(context, "Pengajuan sertifikat berhasil dikirim!");
          Navigator.pop(context, true);
        }
      } else {
        throw body['message'] ?? "Terjadi kesalahan di server";
      }
    } catch (e) {
      if (mounted) {
        Msg.error(context, "Gagal kirim pengajuan: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Form Pengajuan Sertifikat",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Formulir ini khusus untuk mengajukan verifikasi sertifikat pelatihan eksternal (seminar, diklat, workshop) yang Anda ikuti secara mandiri.",
                        style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nama Kegiatan
              _buildSectionTitle("Informasi Pelatihan"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _namaKegiatanController,
                label: "Nama Kegiatan / Pelatihan *",
                hint: "Contoh: Pelatihan Basic Life Support",
                validator: (v) => v!.isEmpty ? "Nama kegiatan wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // Penyelenggara
              _buildTextField(
                controller: _penyelenggaraController,
                label: "Penyelenggara *",
                hint: "Contoh: PPNI DPD Kabupaten Pekalongan",
                validator: (v) => v!.isEmpty ? "Penyelenggara wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // Tempat & Peran
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tempatController,
                      label: "Tempat / Kota *",
                      hint: "Contoh: Aula RSIAP / Online",
                      validator: (v) => v!.isEmpty ? "Tempat wajib diisi" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeran,
                      decoration: _buildInputDecoration("Peran Anda *"),
                      items: ['Peserta', 'Pemateri', 'Panitia'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPeran = val!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Waktu Pelatihan
              _buildSectionTitle("Waktu & Nilai JPL / SKP"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: "Mulai Pelatihan *",
                      date: _tglMulai,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDatePicker(
                      label: "Selesai Pelatihan",
                      date: _tglAkhir,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // JPL & SKP
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _jplController,
                      label: "Jumlah JPL",
                      hint: "Jam Pelajaran",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _skpController,
                      label: "Jumlah Poin SKP",
                      hint: "Poin IDI/PPNI/dll",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Detail Sertifikat
              _buildSectionTitle("Detail Administrasi"),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nomorController,
                label: "Nomor Sertifikat",
                hint: "Contoh: 123/SER/PPNI/VI/2026",
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _materiController,
                label: "Ringkasan Materi Pelatihan (Opsional)",
                hint: "Tulis ringkasan kompetensi yang didapatkan...",
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Upload Sertifikat
              _buildSectionTitle("Dokumen Bukti Sertifikat *"),
              const SizedBox(height: 8),
              _buildFileUploadZone(),
              const SizedBox(height: 36),

              // Submit Button
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shadowColor: primaryColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Kirim Pengajuan",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: _buildInputDecoration(label).copyWith(hintText: hint),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      floatingLabelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null ? DateFormat('d MMM yyyy').format(date) : "Pilih Tanggal",
                  style: TextStyle(
                    fontSize: 13,
                    color: date != null ? Colors.black87 : Colors.grey[400],
                    fontWeight: date != null ? FontWeight.bold : FontWeight.w400,
                  ),
                ),
                Icon(Icons.calendar_today_rounded, size: 16, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileUploadZone() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _selectedFile == null
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_upload_outlined, size: 36, color: primaryColor),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Pilih Berkas Sertifikat",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Format: PDF, JPG, PNG (Maks 5MB)",
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedFileName!.toLowerCase().endsWith('.pdf')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedFileName!.toLowerCase().endsWith('.pdf')
                              ? Icons.picture_as_pdf_rounded
                              : Icons.image_rounded,
                          color: _selectedFileName!.toLowerCase().endsWith('.pdf')
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatBytes(_selectedFileSize),
                              style: TextStyle(color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _removeFile,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

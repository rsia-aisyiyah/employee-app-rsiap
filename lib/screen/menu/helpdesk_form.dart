import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/config/colors.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class HelpdeskFormScreen extends StatefulWidget {
  const HelpdeskFormScreen({super.key});

  @override
  State<HelpdeskFormScreen> createState() => _HelpdeskFormScreenState();
}

class _HelpdeskFormScreenState extends State<HelpdeskFormScreen> {
  final TextEditingController _isiController = TextEditingController();
  bool isLoading = false;

  Future<void> _submitReport() async {
    if (_isiController.text.isEmpty) {
      Msg.warning(context, "Mohon isi keluhan atau masalah anda.");
      return;
    }

    setState(() => isLoading = true);

    try {
      var res = await Api().postData({
        'isi_laporan': _isiController.text,
      }, '/helpdesk/tiket');

      var body = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _showSuccessDialog();
      } else {
        Msg.error(context, body['message'] ?? "Gagal mengirim laporan");
      }
    } catch (e) {
      Msg.error(context, "Terjadi kesalahan: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            const Text("Berhasil"),
          ],
        ),
        content: const Text(
            "Laporan anda berhasil dikirim. Tim IT akan segera memeriksa."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("OK",
                style: TextStyle(
                    color: primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionCard(),
                  const SizedBox(height: 30),
                  _buildInputLabel("Detail Masalah"),
                  const SizedBox(height: 10),
                  _buildInputField(),
                  const SizedBox(height: 40),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withBlue(210).withGreen(180)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            "Lapor Kendala",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: primaryColor, size: 24),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Jelaskan kendala IT yang anda alami secara detail agar kami dapat membantu lebih cepat.",
              style: TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _isiController,
        maxLines: 8,
        style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)),
        decoration: InputDecoration(
          hintText:
              "Contoh: Printer di Poli Anak tidak bisa mencetak rincian biaya...",
          hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 20), // Add padding so it's not full edge-to-edge
      child: SizedBox(
        height: 48, // Reduced height from 55
        child: ElevatedButton(
          onPressed: isLoading ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  15), // Slightly sharper corners for a cleaner look
            ),
            elevation: 2,
            shadowColor: primaryColor.withOpacity(0.3),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "KIRIM LAPORAN",
                      style: TextStyle(
                        fontSize: 14, // Slightly smaller font
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

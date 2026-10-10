import 'package:flutter/material.dart';

class GameOverDialog extends StatelessWidget {
  final int finalScore;
  final int stage;
  final int virusesDefeated;
  final bool isPersonalBest;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GameOverDialog({
    Key? key,
    required this.finalScore,
    required this.stage,
    required this.virusesDefeated,
    required this.isPersonalBest,
    required this.onRestart,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Medis / Defeated
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEE2E2),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Icon(Icons.healing_rounded, color: Color(0xFFDC2626), size: 34),
            ),
            const SizedBox(height: 14),

            const Text(
              'MISI BELUM SELESAI',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terima kasih atas perjuangan menjaga kesehatan dan kesterilan area RSIA!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Stat Cards Bento Clean Tone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('SKOR AKHIR', '$finalScore', Icons.stars_rounded, const Color(0xFFD97706)),
                  Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                  _buildStatItem('STAGE', '$stage', Icons.flag_rounded, const Color(0xFF0284C7)),
                  Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                  _buildStatItem('VIRUS DIBASMI', '$virusesDefeated', Icons.coronavirus_rounded, const Color(0xFF16A34A)),
                ],
              ),
            ),

            if (isPersonalBest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'REKOR TERBAIK BARU!',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('KEMBALI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('COBA LAGI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class StageClearedDialog extends StatelessWidget {
  final int clearedStage;
  final int currentScore;
  final VoidCallback onNextStage;

  const StageClearedDialog({
    Key? key,
    required this.clearedStage,
    required this.currentScore,
    required this.onNextStage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF99F6E4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A896).withValues(alpha: 0.15),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCCFBF1),
                border: Border.all(color: const Color(0xFF5EEAD4)),
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF0D9488), size: 36),
            ),
            const SizedBox(height: 14),

            const Text(
              'AREA STERIL DIBERSIHKAN!',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stage $clearedStage sukses disterilkan! Virus patogen berbahaya berhasil dimurnikan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Skor Saat Ini: $currentScore',
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNextStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  clearedStage == 2 ? 'LANJUT KE AREA FINAL (STAGE 3) ➔' : 'LANJUT KE AREA BERIKUTNYA ➔',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameVictoryDialog extends StatelessWidget {
  final int totalScore;
  final int virusesDefeated;
  final bool isPersonalBest;
  final VoidCallback onFinishAndExit;
  final VoidCallback onContinueEndless;

  const GameVictoryDialog({
    Key? key,
    required this.totalScore,
    required this.virusesDefeated,
    required this.isPersonalBest,
    required this.onFinishAndExit,
    required this.onContinueEndless,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Trophy Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),

            // Victory Title
            const Text(
              'SELAMAT! MISI TUNTAS!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Seluruh 3 area (IGD, Poliklinik, & Nurse Station) sukses disterilkan dari wabah virus! Anda resmi dinobatkan sebagai Pahlawan Medis RSIA.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Badge Gelar Clean Tone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5EEAD4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E), size: 15),
                  SizedBox(width: 6),
                  Text(
                    'GELAR: PAHLAWAN STERILISASI RSIA',
                    style: TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stats summary container Clean Tone
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL SKOR',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$totalScore',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (isPersonalBest) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'REKOR BARU!',
                            style: TextStyle(
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'VIRUS DIMURNIKAN',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.coronavirus_rounded, color: Color(0xFF0D9488), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$virusesDefeated',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
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
            const SizedBox(height: 18),

            // Tombol 1: Selesai & Kembali ke Menu (Primary)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onFinishAndExit,
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text('SELESAI & SIMPAN REKOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A896),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tombol 2: Lanjut Mode Endless (Secondary Clean Tone)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onContinueEndless,
                icon: const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
                label: const Text(
                  'TANTANG MODE ENDLESS (LOOP 2) ➔',
                  style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFFBEB),
                  side: const BorderSide(color: Color(0xFFFCD34D)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GamePauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const GamePauseDialog({
    Key? key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME DIJEDA',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            _buildBtn('LANJUTKAN BERMAIN', const Color(0xFF00A896), Colors.white, onResume),
            const SizedBox(height: 10),
            _buildBtn('MULAI ULANG', const Color(0xFFF1F5F9), const Color(0xFF1E293B), onRestart, hasBorder: true),
            const SizedBox(height: 10),
            _buildBtn('KELUAR KE MENU', Colors.transparent, const Color(0xFF64748B), onExit, isOutlined: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String text, Color bg, Color textCol, VoidCallback onTap, {bool isOutlined = false, bool hasBorder = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textCol,
          elevation: 0,
          side: isOutlined
              ? const BorderSide(color: Color(0xFFCBD5E1))
              : (hasBorder ? const BorderSide(color: Color(0xFFE2E8F0)) : null),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
      ),
    );
  }
}

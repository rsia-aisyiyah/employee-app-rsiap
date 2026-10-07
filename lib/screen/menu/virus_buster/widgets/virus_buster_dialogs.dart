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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                color: const Color(0xFFEF4444).withOpacity(0.15),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: const Icon(Icons.healing_rounded, color: Color(0xFFEF4444), size: 34),
            ),
            const SizedBox(height: 14),

            const Text(
              'MISI BELUM SELESAI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Terima kasih atas perjuangan Dokter Spesialis menjaga kesehatan RSIA!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Stat Cards Bento
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('SKOR AKHIR', '$finalScore', Icons.stars_rounded, const Color(0xFFFFD54F)),
                  Container(width: 1, height: 28, color: Colors.white10),
                  _buildStatItem('STAGE', '$stage', Icons.flag_rounded, const Color(0xFF38BDF8)),
                  Container(width: 1, height: 28, color: Colors.white10),
                  _buildStatItem('VIRUS DIBASMI', '$virusesDefeated', Icons.coronavirus_rounded, const Color(0xFF22C55E)),
                ],
              ),
            ),

            if (isPersonalBest) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'REKOR TERBAIK BARU!',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
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
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
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
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 9, fontWeight: FontWeight.bold),
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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00A896).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A896).withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
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
                color: const Color(0xFF00A896).withOpacity(0.15),
                border: Border.all(color: const Color(0xFF00A896)),
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF00E5FF), size: 36),
            ),
            const SizedBox(height: 14),

            const Text(
              'AREA STERIL DIBERSIHKAN!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stage $clearedStage sukses ditangani oleh Dokter Spesialis! Virus mutasi berhasil dimurnikan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Skor Saat Ini: $currentScore',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                ),
                child: const Text('LANJUT KE AREA BERIKUTNYA ➔', style: TextStyle(fontWeight: FontWeight.bold)),
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
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME DIJEDA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 20),
            _buildBtn('LANJUTKAN BERMAIN', const Color(0xFF00A896), Colors.white, onResume),
            const SizedBox(height: 10),
            _buildBtn('MULAI ULANG', const Color(0xFF1E293B), Colors.white, onRestart),
            const SizedBox(height: 10),
            _buildBtn('KELUAR KE MENU', Colors.transparent, Colors.white60, onExit, isOutlined: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(String text, Color bg, Color textCol, VoidCallback onTap, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textCol,
          elevation: 0,
          side: isOutlined ? BorderSide(color: Colors.white.withOpacity(0.15)) : null,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

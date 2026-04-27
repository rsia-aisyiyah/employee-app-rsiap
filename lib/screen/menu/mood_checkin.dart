import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rsia_employee_app/api/request.dart';
import 'package:rsia_employee_app/utils/msg.dart';

class MoodCheckinScreen extends StatefulWidget {
  const MoodCheckinScreen({super.key});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen>
    with TickerProviderStateMixin {
  final box = GetStorage();

  int _step = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  // Step 1
  String? _selectedMood;
  List<Map> _allTags = [];
  List<int> _selectedTagIds = [];
  final TextEditingController _catatanCtl = TextEditingController();

  // Step 2
  double _energi = 5;
  double _stres = 3;
  double _fokus = 8;

  // Step 3
  String? _kesiapan;
  String? _notifTim;

  // Step 4
  Map? _resultData;
  Map? _teamStats;
  int _streak = 0;

  late AnimationController _fadeCtl;
  late Animation<double> _fadeAnim;

  static const _blue   = Color(0xFF3BC8ED);
  static const _sky    = Color(0xFF0EA5E9);
  static const _green  = Color(0xFF10B981);
  static const _yellow = Color(0xFFEAB308);
  static const _red    = Color(0xFFEF4444);

  final List<Map<String, dynamic>> _moodOptions = [
    {'label': 'Berat',      'emoji': '😔', 'value': 'berat',      'color': _red},
    {'label': 'Kurang oke', 'emoji': '😐', 'value': 'kurang_oke', 'color': _yellow},
    {'label': 'Baik',       'emoji': '😊', 'value': 'baik',       'color': _sky},
    {'label': 'Luar biasa!','emoji': '🤩', 'value': 'luar_biasa', 'color': _green},
  ];

  final List<Map<String, String>> _kesiapanOptions = [
    {'label': 'Belum siap',     'value': 'belum_siap'},
    {'label': 'Cukup siap',     'value': 'cukup_siap'},
    {'label': 'Siap penuh',     'value': 'siap_penuh'},
    {'label': 'Super semangat!','value': 'super_semangat'},
  ];

  final List<Map<String, String>> _notifOptions = [
    {'label': 'Tidak ada',    'value': 'tidak_ada'},
    {'label': 'Ada sedikit',  'value': 'ada_sedikit'},
    {'label': 'Perlu bantuan','value': 'perlu_bantuan'},
    {'label': 'Minta 1-on-1', 'value': 'minta_1on1'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeIn);
    _init();
  }

  @override
  void dispose() {
    _fadeCtl.dispose();
    _catatanCtl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([_fetchTags(), _checkToday()]);
    if (mounted) setState(() => _isLoading = false);
    _fadeCtl.forward();
  }

  Future<void> _fetchTags() async {
    try {
      final res = await Api().getData('/sdi/mood/tags');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => _allTags = List<Map>.from(body['data']));
      }
    } catch (_) {}
  }

  Future<void> _checkToday() async {
    try {
      final nik = box.read('sub');
      final res = await Api().getData('/sdi/mood/today?nik=$nik');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['already_done'] == true) {
          setState(() {
            _resultData = body['data'];
            _streak = body['streak'] ?? 0;
            _step = 3;
          });
        }
        _streak = body['streak'] ?? 0;
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final nik = box.read('sub');
      final res = await Api().postData({
        'nik': nik,
        'mood': _selectedMood,
        'tag_ids': _selectedTagIds,
        'catatan': _catatanCtl.text.trim(),
        'energi': _energi.round(),
        'stres': _stres.round(),
        'fokus': _fokus.round(),
        'kesiapan': _kesiapan,
        'notif_tim': _notifTim ?? 'tidak_ada',
      }, '/sdi/mood/checkin');

      if (res.statusCode == 201) {
        final body = jsonDecode(res.body);
        setState(() {
          _resultData = body['data'];
          _teamStats = body['team_stats'];
          _streak = body['streak'] ?? 1;
          _step = 3;
        });
        _fadeCtl
          ..reset()
          ..forward();
      } else {
        final body = jsonDecode(res.body);
        if (mounted) Msg.error(context, body['message'] ?? 'Gagal check-in');
      }
    } catch (e) {
      if (mounted) Msg.error(context, 'Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    setState(() => _step++);
    _fadeCtl
      ..reset()
      ..forward();
  }

  void _prevStep() {
    setState(() => _step--);
    _fadeCtl
      ..reset()
      ..forward();
  }

  bool get _canNext {
    if (_step == 0) return _selectedMood != null;
    if (_step == 2) return _kesiapan != null && _notifTim != null;
    return true;
  }

  // ─── Colours ─────────────────────────────────────────────────────────────

  Color get _stepColor {
    switch (_step) {
      case 1: return _yellow;
      case 2: return _green;
      case 3: return _blue;
      default: return _blue;
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EF),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: _buildStep(),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final stepLabels = ['Mood', 'Energi', 'Pulse', 'Hasil'];
    final label = _step < stepLabels.length ? stepLabels[_step] : 'Hasil';
    return AppBar(
      title: Text('Check-in · $label',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildProgressBar() {
    final steps = ['Mood', 'Energi', 'Pulse', 'Hasil'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done   = i < _step;
          final active = i == _step;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              decoration: BoxDecoration(
                color: done
                    ? _blue
                    : active
                        ? _blue.withOpacity(0.5)
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildMoodStep();
      case 1: return _buildEnergiStep();
      case 2: return _buildPulseStep();
      case 3: return _buildHasilStep();
      default: return const SizedBox();
    }
  }

  // ─── Step 1 : Mood ───────────────────────────────────────────────────────

  Widget _buildMoodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Selamat pagi!', 'Check-in hari ini — 3 langkah cepat'),
        const SizedBox(height: 24),

        _buildSectionLabel('LANGKAH 1 · PERASAAN HARI INI'),
        const SizedBox(height: 14),

        // Mood grid 2x2
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: _moodOptions.map((opt) {
            final selected = _selectedMood == opt['value'];
            final col = opt['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = opt['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? _blue.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? col : Colors.grey[200]!,
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: col.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(opt['emoji'] as String, style: const TextStyle(fontSize: 30)),
                    const SizedBox(height: 6),
                    Text(opt['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? col : Colors.grey[700],
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        _buildSectionLabel('TANDAI YANG KAMU RASAKAN'),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allTags.map((tag) {
            final id     = tag['id'] as int;
            final active = _selectedTagIds.contains(id);
            return GestureDetector(
              onTap: () => setState(() =>
                  active ? _selectedTagIds.remove(id) : _selectedTagIds.add(id)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? _blue.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: active ? _blue : Colors.grey[300]!,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Text(tag['nama'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? _blue : Colors.grey[700],
                    )),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: TextField(
            controller: _catatanCtl,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: '💬  Ceritakan lebih lanjut... (opsional)',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── Step 2 : Energi ─────────────────────────────────────────────────────

  Widget _buildEnergiStep() {
    final analisis = _buildAnalisis();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Ukur kondisimu', 'Geser slider sesuai kondisimu saat ini'),
        const SizedBox(height: 24),
        _buildSectionLabel('LANGKAH 2 · KONDISI FISIK & MENTAL'),
        const SizedBox(height: 20),

        _buildSliderCard('⚡', 'Energi',  _energi, (v) => setState(() => _energi = v), _yellow),
        const SizedBox(height: 14),
        _buildSliderCard('🌀', 'Stres',   _stres,  (v) => setState(() => _stres = v),  _red),
        const SizedBox(height: 14),
        _buildSliderCard('🎯', 'Fokus',   _fokus,  (v) => setState(() => _fokus = v),  _blue),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_blue.withOpacity(0.07), _green.withOpacity(0.07)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _blue.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Text(analisis['icon']!, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ANALISIS CEPAT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                            color: Colors.grey, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Text(analisis['text']!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Map<String, String> _buildAnalisis() {
    if (_energi >= 7 && _stres <= 4 && _fokus >= 7) {
      return {'icon': '💪', 'text': 'Energi tinggi, stres rendah — kondisi optimal!'};
    } else if (_stres >= 7 || _energi <= 3) {
      return {'icon': '🌙', 'text': 'Kondisi perlu perhatian — jaga istirahat ya!'};
    } else if (_fokus >= 7) {
      return {'icon': '🎯', 'text': 'Fokus tinggi — manfaatkan waktu produktifmu!'};
    } else {
      return {'icon': '⭐', 'text': 'Kondisi moderat — tetap semangat hari ini!'};
    }
  }

  Widget _buildSliderCard(
      String icon, String label, double val, ValueChanged<double> onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${val.round()}/10',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: color,
                    )),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.15),
              thumbColor: color,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: val,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 3 : Pulse ──────────────────────────────────────────────────────

  Widget _buildPulseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Hampir selesai!', '2 pertanyaan singkat untuk tim'),
        const SizedBox(height: 24),
        _buildSectionLabel('LANGKAH 3 · PULSE CHECK'),
        const SizedBox(height: 16),

        _buildQuestionCard(
          question: '🎯  Seberapa siap kamu menghadapi hari ini?',
          options: _kesiapanOptions,
          selected: _kesiapan,
          onSelect: (v) => setState(() => _kesiapan = v),
          color: _green,
        ),

        const SizedBox(height: 16),

        _buildQuestionCard(
          question: '🤝  Ada yang perlu diketahui tim?',
          options: _notifOptions,
          selected: _notifTim,
          onSelect: (v) => setState(() => _notifTim = v),
          color: _blue,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuestionCard({
    required String question,
    required List<Map<String, String>> options,
    required String? selected,
    required ValueChanged<String?> onSelect,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.4)),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.8,
            children: options.map((opt) {
              final isSelected = selected == opt['value'];
              return GestureDetector(
                onTap: () => onSelect(opt['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey[200]!,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(opt['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? color : Colors.grey[700],
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 4 : Hasil ──────────────────────────────────────────────────────

  Widget _buildHasilStep() {
    final moodOpt = _moodOptions.firstWhere(
      (o) => o['value'] == (_resultData?['mood'] ?? _selectedMood),
      orElse: () => _moodOptions[2],
    );
    final moodColor = moodOpt['color'] as Color;

    final tags = (_resultData?['tags'] as List?)
            ?.map((t) => t['nama'].toString())
            .join(' · ') ??
        '';

    final kesiapanLabel = _kesiapanOptions.firstWhere(
      (o) => o['value'] == (_resultData?['kesiapan'] ?? _kesiapan),
      orElse: () => {'label': '-'},
    )['label']!;

    final baikPct    = _teamStats?['baik_pct']          ?? 0;
    final okePct     = _teamStats?['oke_pct']            ?? 0;
    final supportPct = _teamStats?['perlu_support_pct']  ?? 0;
    final totalTeam  = _teamStats?['total']              ?? 0;

    return Column(
      children: [
        // Hero result card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [moodColor.withOpacity(0.8), moodColor.withOpacity(0.4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: moodColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              const Text('Check-in selesai!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
              const SizedBox(height: 4),
              Text('Terima kasih. Datamu dicatat secara aman.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Summary rows
        _buildResultRow('Mood', '${moodOpt['emoji']} ${moodOpt['label']}${tags.isNotEmpty ? '  ·  $tags' : ''}', bold: true),
        const SizedBox(height: 8),
        _buildResultRow(
          'Kondisi',
          '⚡ ${(_resultData?['energi'] ?? _energi.round())}  ·  '
          '🌀 ${(_resultData?['stres'] ?? _stres.round())}  ·  '
          '🎯 ${(_resultData?['fokus'] ?? _fokus.round())}',
        ),
        const SizedBox(height: 8),
        _buildResultRow('Kesiapan', kesiapanLabel),

        // Team stats
        if (_teamStats != null && (totalTeam as int) > 0) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mood tim hari ini (anonim, $totalTeam orang)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      if ((baikPct as int) > 0)
                        Expanded(flex: baikPct, child: Container(height: 12, color: _green)),
                      if ((okePct as int) > 0)
                        Expanded(flex: okePct, child: Container(height: 12, color: _yellow)),
                      if ((supportPct as int) > 0)
                        Expanded(flex: supportPct, child: Container(height: 12, color: _red)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegend(_green,  '$baikPct% baik'),
                    const SizedBox(width: 12),
                    _buildLegend(_yellow, '$okePct% oke'),
                    const SizedBox(width: 12),
                    _buildLegend(_red,    '$supportPct% support'),
                  ],
                ),
              ],
            ),
          ),
        ],

        if (_streak > 0) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Streak $_streak hari berturut-turut!',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.black87,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isHasil = _step == 3;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))],
        ),
        child: Row(
          children: [
            // Back button (not on step 0 and hasil)
            if (_step > 0 && !isHasil) ...[
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: const Text('Kembali'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Main button
            Expanded(
              flex: isHasil || _step == 0 ? 1 : 3,
              child: isHasil
                  ? OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Lihat ulang →',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    )
                  : _step < 2
                      ? _buildNextBtn()
                      : _buildSubmitBtn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBtn() {
    return ElevatedButton(
      onPressed: _canNext ? _nextStep : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _blue,
        disabledBackgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Lanjut', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          SizedBox(width: 4),
          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _buildSubmitBtn() {
    return ElevatedButton(
      onPressed: (_canNext && !_isSaving) ? _submit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _green,
        disabledBackgroundColor: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Kirim Check-in',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildHeader(String title, String subtitle) {
    final nik = box.read('sub')?.toString() ?? '';
    final initial = nik.isNotEmpty ? nik[0].toUpperCase() : 'U';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 22,
          backgroundColor: _blue,
          child: Text(initial,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: Colors.grey, letterSpacing: 0.8));
  }
}

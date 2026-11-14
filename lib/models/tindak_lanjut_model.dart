class TindakLanjutItem {
  final int id;
  final String suratNomor;
  final int? timelineProgramId;
  final String deskripsi;
  final String picNik;
  final String? targetSelesai;
  final int progressPercent;
  final String status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? pic;
  final Map<String, dynamic>? creator;
  final Map<String, dynamic>? undangan;
  final Map<String, dynamic>? timeline;
  final int feedbacksCount;
  final List<TindakLanjutFeedbackItem> feedbacks;

  TindakLanjutItem({
    required this.id,
    required this.suratNomor,
    this.timelineProgramId,
    required this.deskripsi,
    required this.picNik,
    this.targetSelesai,
    this.progressPercent = 0,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.pic,
    this.creator,
    this.undangan,
    this.timeline,
    this.feedbacksCount = 0,
    this.feedbacks = const [],
  });

  factory TindakLanjutItem.fromJson(Map<String, dynamic> json) {
    var rawFeedbacks = json['feedbacks'];
    List<TindakLanjutFeedbackItem> fbList = [];
    if (rawFeedbacks is List) {
      fbList = rawFeedbacks
          .map((e) => TindakLanjutFeedbackItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return TindakLanjutItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      suratNomor: json['surat_nomor']?.toString() ??
          json['undangan']?['surat']?['no_surat']?.toString() ??
          json['undangan']?['surat_nomor']?.toString() ??
          '',
      timelineProgramId: json['timeline_program_id'] != null
          ? int.tryParse(json['timeline_program_id'].toString())
          : null,
      deskripsi: (json['deskripsi'] ?? json['tugas'])?.toString() ?? '',
      picNik: json['pic_nik']?.toString() ?? '',
      targetSelesai: (json['target_selesai'] ?? json['deadline'])?.toString(),
      progressPercent: int.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      pic: json['pic'] is Map ? Map<String, dynamic>.from(json['pic']) : null,
      creator: json['creator'] is Map ? Map<String, dynamic>.from(json['creator']) : null,
      undangan: json['undangan'] is Map ? Map<String, dynamic>.from(json['undangan']) : null,
      timeline: json['timeline'] is Map ? Map<String, dynamic>.from(json['timeline']) : null,
      feedbacksCount: int.tryParse(json['feedbacks_count']?.toString() ?? '0') ?? fbList.length,
      feedbacks: fbList,
    );
  }

  String get picNama => pic?['nama'] ?? picNik;
  String get creatorNama => creator?['nama'] ?? createdBy ?? '-';
  String get perihalRapat => undangan?['perihal'] ?? 'Rapat';

  DateTime? get deadlineDate {
    if (targetSelesai == null || targetSelesai!.isEmpty) return null;
    return DateTime.tryParse(targetSelesai!);
  }

  bool get isOverdue {
    if (status.toLowerCase() == 'selesai') return false;
    final dt = deadlineDate;
    if (dt == null) return false;
    return DateTime.now().isAfter(dt.add(const Duration(days: 1)));
  }
}

class TindakLanjutFeedbackItem {
  final int id;
  final int tindakLanjutId;
  final String userNik;
  final String tipe;
  final String pesan;
  final int? progressPercent;
  final String? berkas;
  final String? namaBerkas;
  final int? ukuranBerkas;
  final String? createdAt;
  final Map<String, dynamic>? user;

  TindakLanjutFeedbackItem({
    required this.id,
    required this.tindakLanjutId,
    required this.userNik,
    required this.tipe,
    required this.pesan,
    this.progressPercent,
    this.berkas,
    this.namaBerkas,
    this.ukuranBerkas,
    this.createdAt,
    this.user,
  });

  factory TindakLanjutFeedbackItem.fromJson(Map<String, dynamic> json) {
    return TindakLanjutFeedbackItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      tindakLanjutId: int.tryParse(json['tindak_lanjut_id']?.toString() ?? '0') ?? 0,
      userNik: json['user_nik']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? 'komentar',
      pesan: json['pesan']?.toString() ?? '',
      progressPercent: json['progress_percent'] != null
          ? int.tryParse(json['progress_percent'].toString())
          : null,
      berkas: json['berkas']?.toString(),
      namaBerkas: json['nama_berkas']?.toString(),
      ukuranBerkas: json['ukuran_berkas'] != null
          ? int.tryParse(json['ukuran_berkas'].toString())
          : null,
      createdAt: json['created_at']?.toString(),
      user: json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null,
    );
  }

  String get userNama => user?['nama'] ?? userNik;
  bool get hasFile => berkas != null && berkas!.isNotEmpty;

  String get formattedFileSize {
    if (ukuranBerkas == null || ukuranBerkas == 0) return '';
    final kb = ukuranBerkas! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }
}

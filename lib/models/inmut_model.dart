class InmutUnitItem {
  final String depId;
  final String namaRuang;
  final String roleInUnit;
  final bool isValidator;
  final bool isPic;
  final String? nikPic;
  final String? namaPic;
  final String? nikValidator;
  final String? namaValidator;
  final int totalIndicators;
  final int filledIndicators;
  final int unfilledIndicators;
  final bool isAllFilled;
  final int verifiedIndicators;
  final int pendingIndicators;
  final int analyzedIndicators;
  final int pendingAnalyses;
  final String submissionStatus; // 'draft' | 'requested' | 'revision' | 'verified'
  final String? requestedAt;
  final String? requestedBy;
  final String? requestNote;
  final String? revisionNote;
  final bool canRequest;
  final bool canCancel;
  final bool isPremature;

  InmutUnitItem({
    required this.depId,
    required this.namaRuang,
    required this.roleInUnit,
    required this.isValidator,
    required this.isPic,
    this.nikPic,
    this.namaPic,
    this.nikValidator,
    this.namaValidator,
    this.totalIndicators = 0,
    this.filledIndicators = 0,
    this.unfilledIndicators = 0,
    this.isAllFilled = false,
    this.verifiedIndicators = 0,
    this.pendingIndicators = 0,
    this.analyzedIndicators = 0,
    this.pendingAnalyses = 0,
    this.submissionStatus = 'draft',
    this.requestedAt,
    this.requestedBy,
    this.requestNote,
    this.revisionNote,
    this.canRequest = false,
    this.canCancel = false,
    this.isPremature = false,
  });

  factory InmutUnitItem.fromJson(Map<String, dynamic> json) {
    return InmutUnitItem(
      depId: json['dep_id']?.toString() ?? '',
      namaRuang: json['nama_ruang']?.toString() ?? '',
      roleInUnit: json['role_in_unit']?.toString() ?? 'viewer',
      isValidator: json['is_validator'] == true,
      isPic: json['is_pic'] == true,
      nikPic: json['nik_pic']?.toString(),
      namaPic: json['nama_pic']?.toString(),
      nikValidator: json['nik_validator']?.toString(),
      namaValidator: json['nama_validator']?.toString(),
      totalIndicators: int.tryParse(json['total_indicators']?.toString() ?? '0') ?? 0,
      filledIndicators: int.tryParse(json['filled_indicators']?.toString() ?? '0') ?? 0,
      unfilledIndicators: int.tryParse(json['unfilled_indicators']?.toString() ?? '0') ?? 0,
      isAllFilled: json['is_all_filled'] == true,
      verifiedIndicators: int.tryParse(json['verified_indicators']?.toString() ?? '0') ?? 0,
      pendingIndicators: int.tryParse(json['pending_indicators']?.toString() ?? '0') ?? 0,
      analyzedIndicators: int.tryParse(json['analyzed_indicators']?.toString() ?? '0') ?? 0,
      pendingAnalyses: int.tryParse(json['pending_analyses']?.toString() ?? '0') ?? 0,
      submissionStatus: json['submission_status']?.toString() ?? 'draft',
      requestedAt: json['requested_at']?.toString(),
      requestedBy: json['requested_by']?.toString(),
      requestNote: json['request_note']?.toString(),
      revisionNote: json['revision_note']?.toString(),
      canRequest: json['can_request'] == true,
      canCancel: json['can_cancel'] == true,
      isPremature: json['is_premature'] == true,
    );
  }
}

class InmutValidationItem {
  final int idInmut;
  final String namaInmut;
  final String? namaJenis;
  final String? kategoriUtama;
  final double standar;
  final String satuan;
  final String rumus;
  final int sumNum;
  final int sumDenum;
  final int daysFilled;
  final int? validationId;
  final int numAwal;
  final int denumAwal;
  int numValidasi;
  int denumValidasi;
  String status;
  String? catatan;
  final String? verifiedBy;
  final String? validatorNama;
  final String? verifiedAt;
  final String? requestedAt;
  final String? requestedBy;
  final String? requesterNama;
  final String? requestNote;
  final String? revisionNote;
  final bool hasAnalisa;
  final int? idAnalisa;
  String? analisa;
  String? tindakLanjut;

  InmutValidationItem({
    required this.idInmut,
    required this.namaInmut,
    this.namaJenis,
    this.kategoriUtama,
    this.standar = 0.0,
    this.satuan = '%',
    this.rumus = '4',
    this.sumNum = 0,
    this.sumDenum = 0,
    this.daysFilled = 0,
    this.validationId,
    this.numAwal = 0,
    this.denumAwal = 0,
    this.numValidasi = 0,
    this.denumValidasi = 0,
    this.status = 'pending',
    this.catatan,
    this.verifiedBy,
    this.validatorNama,
    this.verifiedAt,
    this.requestedAt,
    this.requestedBy,
    this.requesterNama,
    this.requestNote,
    this.revisionNote,
    this.hasAnalisa = false,
    this.idAnalisa,
    this.analisa,
    this.tindakLanjut,
  });

  factory InmutValidationItem.fromJson(Map<String, dynamic> json) {
    return InmutValidationItem(
      idInmut: int.tryParse(json['id_inmut']?.toString() ?? '0') ?? 0,
      namaInmut: json['nama_inmut']?.toString() ?? '',
      namaJenis: json['nama_jenis']?.toString(),
      kategoriUtama: json['kategori_utama']?.toString(),
      standar: double.tryParse(json['standar']?.toString() ?? '0') ?? 0.0,
      satuan: json['satuan']?.toString() ?? '%',
      rumus: json['rumus']?.toString() ?? '4',
      sumNum: int.tryParse(json['sum_num']?.toString() ?? '0') ?? 0,
      sumDenum: int.tryParse(json['sum_denum']?.toString() ?? '0') ?? 0,
      daysFilled: int.tryParse(json['days_filled']?.toString() ?? '0') ?? 0,
      validationId: json['validation_id'] != null ? int.tryParse(json['validation_id'].toString()) : null,
      numAwal: int.tryParse(json['num_awal']?.toString() ?? '0') ?? 0,
      denumAwal: int.tryParse(json['denum_awal']?.toString() ?? '0') ?? 0,
      numValidasi: int.tryParse(json['num_validasi']?.toString() ?? '0') ?? 0,
      denumValidasi: int.tryParse(json['denum_validasi']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      catatan: json['catatan']?.toString(),
      verifiedBy: json['verified_by']?.toString(),
      validatorNama: json['validator_nama']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      requestedAt: json['requested_at']?.toString(),
      requestedBy: json['requested_by']?.toString(),
      requesterNama: json['requester_nama']?.toString(),
      requestNote: json['request_note']?.toString(),
      revisionNote: json['revision_note']?.toString(),
      hasAnalisa: json['has_analisa'] == true,
      idAnalisa: json['id_analisa'] != null ? int.tryParse(json['id_analisa'].toString()) : null,
      analisa: json['analisa']?.toString(),
      tindakLanjut: json['tindak_lanjut']?.toString(),
    );
  }

  double get p1 {
    if (sumDenum <= 0) return 0.0;
    final val = (sumNum / sumDenum) * 100.0;
    return double.parse(val.toStringAsFixed(2));
  }

  double get p2 {
    if (denumValidasi <= 0) return 0.0;
    final val = (numValidasi / denumValidasi) * 100.0;
    return double.parse(val.toStringAsFixed(2));
  }

  bool get hasSample => sumDenum > 0;
  bool get hasValidationSample => denumValidasi > 0;

  double? get agreementRate {
    if (sumDenum <= 0 && denumValidasi <= 0) return null;
    final a = p1;
    final b = p2;
    if (a == 0 && b == 0) return 100.0;
    final minP = a < b ? a : b;
    final maxP = a > b ? a : b;
    if (maxP == 0) return 100.0;
    final ar = (minP / maxP) * 100.0;
    return double.parse(ar.toStringAsFixed(2));
  }

  bool get isAgreementValid => (agreementRate != null) && (agreementRate! >= 90.0);

  String get targetSymbol {
    switch (rumus) {
      case '1':
        return '=';
      case '2':
        return '≤';
      case '3':
        return '<';
      case '4':
        return '≥';
      case '5':
        return '>';
      default:
        return '≥';
    }
  }

  bool get isTargetAchieved {
    final score = p2;
    switch (rumus) {
      case '1':
        return (score - standar).abs() < 0.01;
      case '2':
        return score <= standar;
      case '3':
        return score < standar;
      case '4':
        return score >= standar;
      case '5':
        return score > standar;
      default:
        return score >= standar;
    }
  }
}

class InmutAnalisaItem {
  final int? idAnalisa;
  final int idInmut;
  final String depId;
  final String analisa;
  final String tindakLanjut;
  final int jmlNum;
  final int jmlDenum;
  final double score;
  final String? tglFeedback;
  final String? supervisi;
  final String? rekomendasi;

  InmutAnalisaItem({
    this.idAnalisa,
    required this.idInmut,
    required this.depId,
    required this.analisa,
    required this.tindakLanjut,
    this.jmlNum = 0,
    this.jmlDenum = 0,
    this.score = 0.0,
    this.tglFeedback,
    this.supervisi,
    this.rekomendasi,
  });

  factory InmutAnalisaItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? feedback = json['feedback'] is Map ? Map<String, dynamic>.from(json['feedback']) : null;
    return InmutAnalisaItem(
      idAnalisa: json['id_analisa'] != null ? int.tryParse(json['id_analisa'].toString()) : null,
      idInmut: int.tryParse(json['id_inmut']?.toString() ?? '0') ?? 0,
      depId: json['dep_id']?.toString() ?? '',
      analisa: json['analisa']?.toString() ?? '',
      tindakLanjut: json['tindak_lanjut']?.toString() ?? '',
      jmlNum: int.tryParse(json['jml_num']?.toString() ?? '0') ?? 0,
      jmlDenum: int.tryParse(json['jml_denum']?.toString() ?? '0') ?? 0,
      score: double.tryParse(json['score']?.toString() ?? '0') ?? 0.0,
      tglFeedback: feedback?['tgl_feedback']?.toString(),
      supervisi: feedback?['supervisi']?.toString(),
      rekomendasi: feedback?['rekomendasi']?.toString(),
    );
  }
}

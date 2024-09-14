class JasaPelayanan {
  List<JPData>? data;
  JPLinks? links;
  JPMeta? meta;

  JasaPelayanan({this.data, this.links, this.meta});

  factory JasaPelayanan.fromJson(Map<String, dynamic> json) {
    return JasaPelayanan(
      data: json['data'] != null
          ? List<JPData>.from(json['data'].map((v) => JPData.fromJson(v)))
          : null,
      links: json['links'] != null ? JPLinks.fromJson(json['links']) : null,
      meta: json['meta'] != null ? JPMeta.fromJson(json['meta']) : null,
    );
  }

  // Method toJson
  Map<String, dynamic> toJson() {
    return {
      'data': data?.map((v) => v.toJson()).toList(),
      'links': links?.toJson(),
      'meta': meta?.toJson(),
    };
  }
}

class JPData {
  String? bulan;
  String? tahun;
  String? nik;
  String? departemen;
  String? departemenJm;
  String? sttsKerja;
  String? pendidikan;
  String? jnjJabatan;
  String? resiko;
  String? mulaiKerja;
  String? masaKerja;
  num? ptPendidikan;
  num? ptMasaKerja;
  num? ptJnjJabatan;
  num? ptDepartemen;
  num? ptResiko;
  num? ptTotal;
  num? grandTotalPoint;
  num? ptPendidikanJmRuang;
  num? ptMasaKerjaJmRuang;
  num? ptJnjJabatanJmRuang;
  num? ptTotalJmRuang;
  num? gtPointJmRuang;
  num? lebihJam;
  num? tambahan;
  num? oncallOk;
  num? jmRuangFull;
  num? jmRuangShare;
  num? jmAsistenOk;
  num? uangMakan;
  num? potonganJaspel;
  num? potonganLain;
  num? potonganObat;
  num? jmBersamaFull;
  num? jmBersamaShare;
  num? jmTotalFull;
  num? jmTotalShare;
  num? jmBersihFull;
  num? jmBersihShare;
  String? namaUser;
  String? tglGenerate;
  String? statusPayroll;
  String? statusBuka;
  JPPegawai? pegawai;
  JasaPelayananAkun? jasaPelayananAkun;

  JPData({
    this.bulan,
    this.tahun,
    this.nik,
    this.departemen,
    this.departemenJm,
    this.sttsKerja,
    this.pendidikan,
    this.jnjJabatan,
    this.resiko,
    this.mulaiKerja,
    this.masaKerja,
    this.ptPendidikan,
    this.ptMasaKerja,
    this.ptJnjJabatan,
    this.ptDepartemen,
    this.ptResiko,
    this.ptTotal,
    this.grandTotalPoint,
    this.ptPendidikanJmRuang,
    this.ptMasaKerjaJmRuang,
    this.ptJnjJabatanJmRuang,
    this.ptTotalJmRuang,
    this.gtPointJmRuang,
    this.lebihJam,
    this.tambahan,
    this.oncallOk,
    this.jmRuangFull,
    this.jmRuangShare,
    this.jmAsistenOk,
    this.uangMakan,
    this.potonganJaspel,
    this.potonganLain,
    this.potonganObat,
    this.jmBersamaFull,
    this.jmBersamaShare,
    this.jmTotalFull,
    this.jmTotalShare,
    this.jmBersihFull,
    this.jmBersihShare,
    this.namaUser,
    this.tglGenerate,
    this.statusPayroll,
    this.statusBuka,
    this.pegawai,
    this.jasaPelayananAkun
  });

  // From JSON
  factory JPData.fromJson(Map<String, dynamic> json) {
    return JPData(
      bulan: json['bulan'],
      tahun: json['tahun'],
      nik: json['nik'],
      departemen: json['departemen'],
      departemenJm: json['departemen_jm'],
      sttsKerja: json['stts_kerja'],
      pendidikan: json['pendidikan'],
      jnjJabatan: json['jnj_jabatan'],
      resiko: json['resiko'],
      mulaiKerja: json['mulai_kerja'],
      masaKerja: json['masa_kerja'],
      ptPendidikan: json['pt_pendidikan'],
      ptMasaKerja: json['pt_masa_kerja'],
      ptJnjJabatan: json['pt_jnj_jabatan'],
      ptDepartemen: json['pt_departemen'],
      ptResiko: json['pt_resiko'],
      ptTotal: json['pt_total'],
      grandTotalPoint: json['grand_total_point'],
      ptPendidikanJmRuang: json['pt_pendidikan_jm_ruang'],
      ptMasaKerjaJmRuang: json['pt_masa_kerja_jm_ruang'],
      ptJnjJabatanJmRuang: json['pt_jnj_jabatan_jm_ruang'],
      ptTotalJmRuang: json['pt_total_jm_ruang'],
      gtPointJmRuang: json['gt_point_jm_ruang'],
      lebihJam: json['lebih_jam'],
      tambahan: json['tambahan'],
      oncallOk: json['oncall_ok'],
      jmRuangFull: json['jm_ruang_full'],
      jmRuangShare: json['jm_ruang_share'],
      jmAsistenOk: json['jm_asisten_ok'],
      uangMakan: json['uang_makan'],
      potonganJaspel: json['potongan_jaspel'],
      potonganLain: json['potongan_lain'],
      potonganObat: json['potongan_obat'],
      jmBersamaFull: json['jm_bersama_full'],
      jmBersamaShare: json['jm_bersama_share'],
      jmTotalFull: json['jm_total_full'],
      jmTotalShare: json['jm_total_share'],
      jmBersihFull: json['jm_bersih_full'],
      jmBersihShare: json['jm_bersih_share'],
      namaUser: json['nama_user'],
      tglGenerate: json['tgl_generate'],
      statusPayroll: json['status_payroll'],
      statusBuka: json['status_buka'],
      pegawai: json['pegawai'] != null ? JPPegawai.fromJson(json['pegawai']) : null,
      jasaPelayananAkun: json['jasa_pelayanan_akun'] != null
          ? JasaPelayananAkun.fromJson(json['jasa_pelayanan_akun'])
          : null,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'bulan': bulan,
      'tahun': tahun,
      'nik': nik,
      'departemen': departemen,
      'departemen_jm': departemenJm,
      'stts_kerja': sttsKerja,
      'pendidikan': pendidikan,
      'jnj_jabatan': jnjJabatan,
      'resiko': resiko,
      'mulai_kerja': mulaiKerja,
      'masa_kerja': masaKerja,
      'pt_pendidikan': ptPendidikan,
      'pt_masa_kerja': ptMasaKerja,
      'pt_jnj_jabatan': ptJnjJabatan,
      'pt_departemen': ptDepartemen,
      'pt_resiko': ptResiko,
      'pt_total': ptTotal,
      'grand_total_point': grandTotalPoint,
      'pt_pendidikan_jm_ruang': ptPendidikanJmRuang,
      'pt_masa_kerja_jm_ruang': ptMasaKerjaJmRuang,
      'pt_jnj_jabatan_jm_ruang': ptJnjJabatanJmRuang,
      'pt_total_jm_ruang': ptTotalJmRuang,
      'gt_point_jm_ruang': gtPointJmRuang,
      'lebih_jam': lebihJam,
      'tambahan': tambahan,
      'oncall_ok': oncallOk,
      'jm_ruang_full': jmRuangFull,
      'jm_ruang_share': jmRuangShare,
      'jm_asisten_ok': jmAsistenOk,
      'uang_makan': uangMakan,
      'potongan_jaspel': potonganJaspel,
      'potongan_lain': potonganLain,
      'potongan_obat': potonganObat,
      'jm_bersama_full': jmBersamaFull,
      'jm_bersama_share': jmBersamaShare,
      'jm_total_full': jmTotalFull,
      'jm_total_share': jmTotalShare,
      'jm_bersih_full': jmBersihFull,
      'jm_bersih_share': jmBersihShare,
      'nama_user': namaUser,
      'tgl_generate': tglGenerate,
      'status_payroll': statusPayroll,
      'status_buka': statusBuka,
      'pegawai': pegawai?.toJson(),
      'jasa_pelayanan_akun': jasaPelayananAkun?.toJson(),
    };
  }
}

class JPPegawai {
  String? nik;
  String? nama;

  JPPegawai({this.nik, this.nama});

  JPPegawai.fromJson(Map<String, dynamic> json) {
    nik = json['nik'] as String?;
    nama = json['nama'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['nik'] = this.nik;
    data['nama'] = this.nama;
    return data;
  }
}

class JasaPelayananAkun {
  num? id;
  String? tahun;
  String? bulan;
  num? idAkun;
  num? nominal;
  num? nominalShare;
  num? nominalJmRuang;
  num? nominalJmBersama;
  num? nominalJmRuangShare;
  num? nominalJmBersamaShare;
  num? jmRs;
  num? jmRuang;
  num? jmBersama;
  num? jmOkMitra; // Ganti dari Null? menjadi num? untuk tipe data yang lebih sesuai
  String? status;
  String? namaUser;
  String? tglGenerate;

  JasaPelayananAkun({
    this.id,
    this.tahun,
    this.bulan,
    this.idAkun,
    this.nominal,
    this.nominalShare,
    this.nominalJmRuang,
    this.nominalJmBersama,
    this.nominalJmRuangShare,
    this.nominalJmBersamaShare,
    this.jmRs,
    this.jmRuang,
    this.jmBersama,
    this.jmOkMitra,
    this.status,
    this.namaUser,
    this.tglGenerate,
  });

  JasaPelayananAkun.fromJson(Map<String, dynamic> json) {
    id = json['id'] as num?;
    tahun = json['tahun'] as String?;
    bulan = json['bulan'] as String?;
    idAkun = json['id_akun'] as num?;
    nominal = json['nominal'] as num?;
    nominalShare = json['nominal_share'] as num?;
    nominalJmRuang = json['nominal_jm_ruang'] as num?;
    nominalJmBersama = json['nominal_jm_bersama'] as num?;
    nominalJmRuangShare = json['nominal_jm_ruang_share'] as num?;
    nominalJmBersamaShare = json['nominal_jm_bersama_share'] as num?;
    jmRs = json['jm_rs'] as num?;
    jmRuang = json['jm_ruang'] as num?;
    jmBersama = json['jm_bersama'] as num?;
    jmOkMitra = json['jm_ok_mitra'] as num?; // Ganti dari Null? menjadi num? untuk tipe data yang lebih sesuai
    status = json['status'] as String?;
    namaUser = json['nama_user'] as String?;
    tglGenerate = json['tgl_generate'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['tahun'] = tahun;
    data['bulan'] = bulan;
    data['id_akun'] = idAkun;
    data['nominal'] = nominal;
    data['nominal_share'] = nominalShare;
    data['nominal_jm_ruang'] = nominalJmRuang;
    data['nominal_jm_bersama'] = nominalJmBersama;
    data['nominal_jm_ruang_share'] = nominalJmRuangShare;
    data['nominal_jm_bersama_share'] = nominalJmBersamaShare;
    data['jm_rs'] = jmRs;
    data['jm_ruang'] = jmRuang;
    data['jm_bersama'] = jmBersama;
    data['jm_ok_mitra'] = jmOkMitra;
    data['status'] = status;
    data['nama_user'] = namaUser;
    data['tgl_generate'] = tglGenerate;
    return data;
  }
}

class JPLinks {
  String? first;
  String? last;
  String? prev; // Ganti dari Null? menjadi String? untuk konsistensi tipe data
  String? next; // Ganti dari Null? menjadi String? untuk konsistensi tipe data

  JPLinks({this.first, this.last, this.prev, this.next});

  JPLinks.fromJson(Map<String, dynamic> json) {
    first = json['first'] as String?;
    last = json['last'] as String?;
    prev = json['prev'] as String?; // Ganti dari Null? menjadi String? untuk konsistensi tipe data
    next = json['next'] as String?; // Ganti dari Null? menjadi String? untuk konsistensi tipe data
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['first'] = this.first;
    data['last'] = this.last;
    data['prev'] = this.prev;
    data['next'] = this.next;
    return data;
  }
}

class JPMeta {
  num? currentPage;
  num? from;
  num? lastPage;
  List<JPLinks>? links;
  String? path;
  num? perPage;
  num? to;
  num? total;

  JPMeta({
    this.currentPage,
    this.from,
    this.lastPage,
    this.links,
    this.path,
    this.perPage,
    this.to,
    this.total,
  });

  JPMeta.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'] as num?;
    from = json['from'] as num?;
    lastPage = json['last_page'] as num?;
    if (json['links'] != null) {
      links = (json['links'] as List<dynamic>).map((v) => JPLinks.fromJson(v as Map<String, dynamic>)).toList();
    }
    path = json['path'] as String?;
    perPage = json['per_page'] as num?;
    to = json['to'] as num?;
    total = json['total'] as num?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = this.currentPage;
    data['from'] = this.from;
    data['last_page'] = this.lastPage;
    if (this.links != null) {
      data['links'] = this.links!.map((v) => v.toJson()).toList();
    }
    data['path'] = this.path;
    data['per_page'] = this.perPage;
    data['to'] = this.to;
    data['total'] = this.total;
    return data;
  }
}

class JPMetaLinks {
  String? url;
  String? label;
  bool? active;

  JPMetaLinks({
    this.url,
    this.label,
    this.active,
  });

  JPMetaLinks.fromJson(Map<String, dynamic> json) {
    url = json['url'] as String?;
    label = json['label'] as String?;
    active = json['active'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['url'] = this.url;
    data['label'] = this.label;
    data['active'] = this.active;
    return data;
  }
}

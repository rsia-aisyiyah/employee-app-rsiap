class JasaPelayanan {
  List<JPData>? data;
  JPLinks? links;
  JPMeta? meta;

  JasaPelayanan({this.data, this.links, this.meta});

  JasaPelayanan.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <JPData>[];
      json['data'].forEach((v) {
        data!.add(new JPData.fromJson(v));
      });
    }
    links = json['links'] != null ? new JPLinks.fromJson(json['links']) : null;
    meta = json['meta'] != null ? new JPMeta.fromJson(json['meta']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    if (this.links != null) {
      data['links'] = this.links!.toJson();
    }
    if (this.meta != null) {
      data['meta'] = this.meta!.toJson();
    }
    return data;
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

  JPData(
      {this.bulan,
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
        this.jasaPelayananAkun});

  JPData.fromJson(Map<String, dynamic> json) {
    bulan = json['bulan'];
    tahun = json['tahun'];
    nik = json['nik'];
    departemen = json['departemen'];
    departemenJm = json['departemen_jm'];
    sttsKerja = json['stts_kerja'];
    pendidikan = json['pendidikan'];
    jnjJabatan = json['jnj_jabatan'];
    resiko = json['resiko'];
    mulaiKerja = json['mulai_kerja'];
    masaKerja = json['masa_kerja'];
    ptPendidikan = json['pt_pendidikan'];
    ptMasaKerja = json['pt_masa_kerja'];
    ptJnjJabatan = json['pt_jnj_jabatan'];
    ptDepartemen = json['pt_departemen'];
    ptResiko = json['pt_resiko'];
    ptTotal = json['pt_total'];
    grandTotalPoint = json['grand_total_point'];
    ptPendidikanJmRuang = json['pt_pendidikan_jm_ruang'];
    ptMasaKerjaJmRuang = json['pt_masa_kerja_jm_ruang'];
    ptJnjJabatanJmRuang = json['pt_jnj_jabatan_jm_ruang'];
    ptTotalJmRuang = json['pt_total_jm_ruang'];
    gtPointJmRuang = json['gt_point_jm_ruang'];
    lebihJam = json['lebih_jam'];
    tambahan = json['tambahan'];
    oncallOk = json['oncall_ok'];
    jmRuangFull = json['jm_ruang_full'];
    jmRuangShare = json['jm_ruang_share'];
    jmAsistenOk = json['jm_asisten_ok'];
    uangMakan = json['uang_makan'];
    potonganJaspel = json['potongan_jaspel'];
    potonganLain = json['potongan_lain'];
    potonganObat = json['potongan_obat'];
    jmBersamaFull = json['jm_bersama_full'];
    jmBersamaShare = json['jm_bersama_share'];
    jmTotalFull = json['jm_total_full'];
    jmTotalShare = json['jm_total_share'];
    jmBersihFull = json['jm_bersih_full'];
    jmBersihShare = json['jm_bersih_share'];
    namaUser = json['nama_user'];
    tglGenerate = json['tgl_generate'];
    statusPayroll = json['status_payroll'];
    statusBuka = json['status_buka'];
    pegawai =
    json['pegawai'] != null ? new JPPegawai.fromJson(json['pegawai']) : null;
    jasaPelayananAkun = json['jasa_pelayanan_akun'] != null
        ? new JasaPelayananAkun.fromJson(json['jasa_pelayanan_akun'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bulan'] = this.bulan;
    data['tahun'] = this.tahun;
    data['nik'] = this.nik;
    data['departemen'] = this.departemen;
    data['departemen_jm'] = this.departemenJm;
    data['stts_kerja'] = this.sttsKerja;
    data['pendidikan'] = this.pendidikan;
    data['jnj_jabatan'] = this.jnjJabatan;
    data['resiko'] = this.resiko;
    data['mulai_kerja'] = this.mulaiKerja;
    data['masa_kerja'] = this.masaKerja;
    data['pt_pendidikan'] = this.ptPendidikan;
    data['pt_masa_kerja'] = this.ptMasaKerja;
    data['pt_jnj_jabatan'] = this.ptJnjJabatan;
    data['pt_departemen'] = this.ptDepartemen;
    data['pt_resiko'] = this.ptResiko;
    data['pt_total'] = this.ptTotal;
    data['grand_total_point'] = this.grandTotalPoint;
    data['pt_pendidikan_jm_ruang'] = this.ptPendidikanJmRuang;
    data['pt_masa_kerja_jm_ruang'] = this.ptMasaKerjaJmRuang;
    data['pt_jnj_jabatan_jm_ruang'] = this.ptJnjJabatanJmRuang;
    data['pt_total_jm_ruang'] = this.ptTotalJmRuang;
    data['gt_point_jm_ruang'] = this.gtPointJmRuang;
    data['lebih_jam'] = this.lebihJam;
    data['tambahan'] = this.tambahan;
    data['oncall_ok'] = this.oncallOk;
    data['jm_ruang_full'] = this.jmRuangFull;
    data['jm_ruang_share'] = this.jmRuangShare;
    data['jm_asisten_ok'] = this.jmAsistenOk;
    data['uang_makan'] = this.uangMakan;
    data['potongan_jaspel'] = this.potonganJaspel;
    data['potongan_lain'] = this.potonganLain;
    data['potongan_obat'] = this.potonganObat;
    data['jm_bersama_full'] = this.jmBersamaFull;
    data['jm_bersama_share'] = this.jmBersamaShare;
    data['jm_total_full'] = this.jmTotalFull;
    data['jm_total_share'] = this.jmTotalShare;
    data['jm_bersih_full'] = this.jmBersihFull;
    data['jm_bersih_share'] = this.jmBersihShare;
    data['nama_user'] = this.namaUser;
    data['tgl_generate'] = this.tglGenerate;
    data['status_payroll'] = this.statusPayroll;
    data['status_buka'] = this.statusBuka;
    if (this.pegawai != null) {
      data['pegawai'] = this.pegawai!.toJson();
    }
    if (this.jasaPelayananAkun != null) {
      data['jasa_pelayanan_akun'] = this.jasaPelayananAkun!.toJson();
    }
    return data;
  }
}

class JPPegawai {
  String? nik;
  String? nama;

  JPPegawai({this.nik, this.nama});

  JPPegawai.fromJson(Map<String, dynamic> json) {
    nik = json['nik'];
    nama = json['nama'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
  Null? jmOkMitra;
  String? status;
  String? namaUser;
  String? tglGenerate;

  JasaPelayananAkun(
      {this.id,
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
        this.tglGenerate});

  JasaPelayananAkun.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    tahun = json['tahun'];
    bulan = json['bulan'];
    idAkun = json['id_akun'];
    nominal = json['nominal'];
    nominalShare = json['nominal_share'];
    nominalJmRuang = json['nominal_jm_ruang'];
    nominalJmBersama = json['nominal_jm_bersama'];
    nominalJmRuangShare = json['nominal_jm_ruang_share'];
    nominalJmBersamaShare = json['nominal_jm_bersama_share'];
    jmRs = json['jm_rs'];
    jmRuang = json['jm_ruang'];
    jmBersama = json['jm_bersama'];
    jmOkMitra = json['jm_ok_mitra'];
    status = json['status'];
    namaUser = json['nama_user'];
    tglGenerate = json['tgl_generate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['tahun'] = this.tahun;
    data['bulan'] = this.bulan;
    data['id_akun'] = this.idAkun;
    data['nominal'] = this.nominal;
    data['nominal_share'] = this.nominalShare;
    data['nominal_jm_ruang'] = this.nominalJmRuang;
    data['nominal_jm_bersama'] = this.nominalJmBersama;
    data['nominal_jm_ruang_share'] = this.nominalJmRuangShare;
    data['nominal_jm_bersama_share'] = this.nominalJmBersamaShare;
    data['jm_rs'] = this.jmRs;
    data['jm_ruang'] = this.jmRuang;
    data['jm_bersama'] = this.jmBersama;
    data['jm_ok_mitra'] = this.jmOkMitra;
    data['status'] = this.status;
    data['nama_user'] = this.namaUser;
    data['tgl_generate'] = this.tglGenerate;
    return data;
  }
}

class JPLinks {
  String? first;
  String? last;
  Null? prev;
  Null? next;

  JPLinks({this.first, this.last, this.prev, this.next});

  JPLinks.fromJson(Map<String, dynamic> json) {
    first = json['first'];
    last = json['last'];
    prev = json['prev'];
    next = json['next'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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

  JPMeta(
      {this.currentPage,
        this.from,
        this.lastPage,
        this.links,
        this.path,
        this.perPage,
        this.to,
        this.total});

  JPMeta.fromJson(Map<String, dynamic> json) {
    currentPage = json['current_page'];
    from = json['from'];
    lastPage = json['last_page'];
    if (json['links'] != null) {
      links = <JPLinks>[];
      json['links'].forEach((v) {
        links!.add(new JPLinks.fromJson(v));
      });
    }
    path = json['path'];
    perPage = json['per_page'];
    to = json['to'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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

  JPMetaLinks({this.url, this.label, this.active});

  JPMetaLinks.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['url'] = this.url;
    data['label'] = this.label;
    data['active'] = this.active;
    return data;
  }
}
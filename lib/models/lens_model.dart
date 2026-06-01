class LensSeansi {
  final DateTime takma;
  final DateTime cikarma;
  final int sureDk;
  String? sikayet;

  LensSeansi({required this.takma, required this.cikarma, required this.sureDk, this.sikayet});

  Map<String, dynamic> toMap() => {'takma': takma.toIso8601String(), 'cikarma': cikarma.toIso8601String(), 'sureDk': sureDk, 'sikayet': sikayet};
  factory LensSeansi.fromMap(Map<String, dynamic> map) => LensSeansi(
    takma: DateTime.parse(map['takma']),
    cikarma: DateTime.parse(map['cikarma']),
    sureDk: map['sureDk'],
    sikayet: map['sikayet'],
  );
}

class GunlukLensKaydi {
  final String tarih;
  List<LensSeansi> seanslar;

  GunlukLensKaydi({required this.tarih, required this.seanslar});

  int get toplamSureDk => seanslar.fold(0, (sum, item) => sum + item.sureDk);
  bool get sikayetVarMi => seanslar.any((s) => s.sikayet != null && s.sikayet!.trim().isNotEmpty);

  Map<String, dynamic> toMap() => {'tarih': tarih, 'seanslar': seanslar.map((s) => s.toMap()).toList()};
  factory GunlukLensKaydi.fromMap(Map<String, dynamic> map) {
    var list = map['seanslar'] as List;
    return GunlukLensKaydi(tarih: map['tarih'], seanslar: list.map((s) => LensSeansi.fromMap(s)).toList());
  }
}
class ReglDonemi {
  final DateTime baslangicTarihi;
  final DateTime? bitisTarihi;

  ReglDonemi({required this.baslangicTarihi, this.bitisTarihi});

  Map<String, dynamic> toMap() => {
    'baslangicTarihi': baslangicTarihi.toIso8601String(),
    'bitisTarihi': bitisTarihi?.toIso8601String(),
  };
  
  factory ReglDonemi.fromMap(Map<String, dynamic> map) => ReglDonemi(
    baslangicTarihi: DateTime.parse(map['baslangicTarihi']),
    bitisTarihi: map['bitisTarihi'] != null ? DateTime.parse(map['bitisTarihi']) : null,
  );
}
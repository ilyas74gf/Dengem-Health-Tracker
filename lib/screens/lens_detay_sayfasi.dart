import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/lens_model.dart';

class LensDetaySayfasi extends StatefulWidget {
  const LensDetaySayfasi({super.key});
  @override
  State<LensDetaySayfasi> createState() => _LensDetaySayfasiState();
}

class _LensDetaySayfasiState extends State<LensDetaySayfasi> {
  DateTime? _aylikBaslangic;
  DateTime? _gunlukTaktigimZaman;
  List<GunlukLensKaydi> _kayitlar = [];
  Timer? _zamanlayici;
  DateTime _gosterilenAy = DateTime.now();

  String _marka = "";
  String _sagNo = "";
  String _solNo = "";

  @override
  void initState() {
    super.initState();
    _verileriYukle();
    _zamanlayici = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_gunlukTaktigimZaman != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  int get _kalanLensGunu {
    if (_aylikBaslangic == null) return 30;
    DateTime baslangicTemiz = DateTime(_aylikBaslangic!.year, _aylikBaslangic!.month, _aylikBaslangic!.day);
    
    int kullanilanGunSayisi = _kayitlar.where((k) {
      try {
        DateTime kt = DateTime.parse(k.tarih);
        return !kt.isBefore(baslangicTemiz) && k.seanslar.isNotEmpty;
      } catch (_) {
        return false;
      }
    }).length;

    int kalan = 30 - kullanilanGunSayisi;
    return kalan < 0 ? 0 : kalan;
  }

  void _bildirimGoster(String mesaj, {bool hata = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(hata ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mesaj, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: hata ? Colors.redAccent : Colors.teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<TimeOfDay?> _saatSec(String baslik, TimeOfDay baslangic) async {
    return await showTimePicker(
      context: context,
      initialTime: baslangic,
      helpText: baslik,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!);
      },
    );
  }

  Future<void> _verileriYukle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? aylikTarih = prefs.getString('aylik_lens_baslangic_v10');
    String? gunlukTarih = prefs.getString('gunluk_takma_zamani_v10');
    List<String> hamVeri = prefs.getStringList('lens_kayitlari_v10') ?? [];

    setState(() {
      if (aylikTarih != null) _aylikBaslangic = DateTime.parse(aylikTarih);
      _gunlukTaktigimZaman = gunlukTarih != null ? DateTime.parse(gunlukTarih) : null;
      _kayitlar = hamVeri.map((e) => GunlukLensKaydi.fromMap(jsonDecode(e))).toList();
      _marka = prefs.getString('lens_markasi') ?? "-";
      _sagNo = prefs.getString('sag_numara') ?? "-";
      _solNo = prefs.getString('sol_numara') ?? "-";
    });
  }

  Future<void> _kaydet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> hamVeri = _kayitlar.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('lens_kayitlari_v10', hamVeri);
  }

  Future<void> _gunlukLensTak() async {
    if (_kalanLensGunu == 0) {
      bool? devamEt = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Lens Süresi Doldu! ⚠️"),
          content: const Text("30 günlük kullanım hakkınız bitmiştir. Yeni seans başlatmak istiyor musunuz?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), onPressed: () => Navigator.pop(context, true), child: const Text("Yine de Başlat", style: TextStyle(color: Colors.white)))
          ],
        ),
      );
      if (devamEt != true) return;
    }

    DateTime suAn = DateTime.now();
    TimeOfDay? secilenSaat = await _saatSec('Lensi Taktığın Saati Seç', TimeOfDay.now());
    if (secilenSaat == null) return;

    DateTime tamZaman = DateTime(suAn.year, suAn.month, suAn.day, secilenSaat.hour, secilenSaat.minute);
    if (tamZaman.isAfter(suAn)) {
      _bildirimGoster("Gelecekteki bir saati seçemezsin!");
      return;
    }

    bool cakisiyorMu = _kayitlar.expand((k) => k.seanslar).any((s) => tamZaman.isBefore(s.cikarma) && suAn.isAfter(s.takma));
    if(cakisiyorMu) {
      _bildirimGoster("Bu saatte zaten kaydedilmiş veya devam eden bir seansın var.");
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gunluk_takma_zamani_v10', tamZaman.toIso8601String());
    _verileriYukle();
    _bildirimGoster("Seans başlatıldı.", hata: false);
  }

  Future<void> _lensiCikarDialog() async {
    if (_gunlukTaktigimZaman == null) return;
    DateTime suAn = DateTime.now();
    TimeOfDay secilenCikarmaSaati = TimeOfDay(hour: suAn.hour, minute: suAn.minute);
    DateTime secilenTamCikarmaZamani = suAn;
    TextEditingController sikayetController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Seansı Sonlandır"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sadece eğer çıkarmayı unutup sonradan giriyorsan saati değiştir.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 15),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.teal.withOpacity(0.3))),
                    leading: const Icon(Icons.access_time, color: Colors.teal),
                    title: const Text("Çıkarma Saati"),
                    trailing: Text("${secilenCikarmaSaati.hour.toString().padLeft(2,'0')}:${secilenCikarmaSaati.minute.toString().padLeft(2,'0')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      TimeOfDay? yeniSaat = await _saatSec('Unutulan Çıkarma Saati', secilenCikarmaSaati);
                      if (yeniSaat != null) {
                        setStateDialog(() {
                          secilenCikarmaSaati = yeniSaat;
                          secilenTamCikarmaZamani = DateTime(suAn.year, suAn.month, suAn.day, yeniSaat.hour, yeniSaat.minute);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: sikayetController, maxLines: 2, decoration: InputDecoration(hintText: "Gözünde yanma vb. oldu mu?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () {
                    int gecenDk = secilenTamCikarmaZamani.difference(_gunlukTaktigimZaman!).inMinutes;
                    if (gecenDk < 0) { _bildirimGoster("Geçersiz zaman aralığı!"); return; }
                    Navigator.pop(context);
                    _lensiCikarIsleminiTamamla(secilenTamCikarmaZamani, gecenDk, sikayetController.text);
                  }, 
                  child: const Text("Kaydet")
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _lensiCikarIsleminiTamamla(DateTime cikarmaZamani, int gecenDk, String sikayetText) async {
    String gunFormat = "${_gunlukTaktigimZaman!.year}-${_gunlukTaktigimZaman!.month.toString().padLeft(2, '0')}-${_gunlukTaktigimZaman!.day.toString().padLeft(2, '0')}";
    int index = _kayitlar.indexWhere((k) => k.tarih == gunFormat);
    List<LensSeansi> mevcutSeanslar = [];
    if (index != -1) { mevcutSeanslar = List.from(_kayitlar[index].seanslar); _kayitlar.removeAt(index); }

    mevcutSeanslar.add(LensSeansi(takma: _gunlukTaktigimZaman!, cikarma: cikarmaZamani, sureDk: gecenDk, sikayet: sikayetText));
    _kayitlar.add(GunlukLensKaydi(tarih: gunFormat, seanslar: mevcutSeanslar));
    await _kaydet();
    
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('gunluk_takma_zamani_v10');
    setState(() { _gunlukTaktigimZaman = null; });
    _verileriYukle();
    _bildirimGoster("Seans kaydedildi.", hata: false);
  }

  Future<void> _gecmisKayitEkle() async {
    DateTime suAn = DateTime.now();
    DateTime? secilenGun = await showDatePicker(context: context, initialDate: suAn, firstDate: DateTime(2023), lastDate: suAn, helpText: 'Lensi Taktığın Gün?');
    if (secilenGun == null || !mounted) return;

    TimeOfDay? takmaSaat = await _saatSec('Takma Saati (24H)', const TimeOfDay(hour: 9, minute: 0));
    if (takmaSaat == null || !mounted) return;
    DateTime takmaTam = DateTime(secilenGun.year, secilenGun.month, secilenGun.day, takmaSaat.hour, takmaSaat.minute);

    TimeOfDay? cikarmaSaat = await _saatSec('Çıkarma Saati (24H)', const TimeOfDay(hour: 17, minute: 0));
    if (cikarmaSaat == null || !mounted) return;
    DateTime cikarmaTam = DateTime(secilenGun.year, secilenGun.month, secilenGun.day, cikarmaSaat.hour, cikarmaSaat.minute);
    
    if (cikarmaTam.isBefore(takmaTam)) cikarmaTam = cikarmaTam.add(const Duration(days: 1)); 

    TextEditingController sikayetController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Şikayet Durumu"),
        content: TextField(controller: sikayetController, decoration: const InputDecoration(hintText: "Şikayet varsa yazın")),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam"))],
      ),
    );

    String gunFormat = "${secilenGun.year}-${secilenGun.month.toString().padLeft(2, '0')}-${secilenGun.day.toString().padLeft(2, '0')}";
    int index = _kayitlar.indexWhere((k) => k.tarih == gunFormat);
    List<LensSeansi> seanslar = [];
    if (index != -1) { seanslar = List.from(_kayitlar[index].seanslar); _kayitlar.removeAt(index); }

    seanslar.add(LensSeansi(takma: takmaTam, cikarma: cikarmaTam, sureDk: cikarmaTam.difference(takmaTam).inMinutes, sikayet: sikayetController.text));
    _kayitlar.add(GunlukLensKaydi(tarih: gunFormat, seanslar: seanslar));
    await _kaydet(); _verileriYukle();
  }

  Future<void> _seansSil(GunlukLensKaydi kayit, LensSeansi silinecekSeans) async {
    bool? onayla = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emin misin?"),
        content: const Text("Bu seansı silmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text("Evet, Sil"))
        ],
      ),
    );

    if (onayla != true) return;

    int gunIndex = _kayitlar.indexWhere((k) => k.tarih == kayit.tarih);
    if (gunIndex != -1) {
      _kayitlar[gunIndex].seanslar.removeWhere((s) => s.takma == silinecekSeans.takma && s.cikarma == silinecekSeans.cikarma);
      if (_kayitlar[gunIndex].seanslar.isEmpty) {
        _kayitlar.removeAt(gunIndex);
        if (mounted) Navigator.pop(context);
      }
      await _kaydet();
      _verileriYukle();
      _bildirimGoster("Seans başarıyla silindi.", hata: false);
    }
  }

  // YENİLENMİŞ DETAY (BOTTOM SHEET) PENCERESİ
  void _gunDetayiniGoster(GunlukLensKaydi kayit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            kayit.seanslar.sort((a, b) => a.takma.compareTo(b.takma));
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(kayit.tarih, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text("${kayit.seanslar.length} Seans Kaydedildi", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: kayit.toplamSureDk > 480 ? Colors.red[50] : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              "T. Süre: ${kayit.toplamSureDk ~/ 60}s ${kayit.toplamSureDk % 60}d", 
                              style: TextStyle(color: kayit.toplamSureDk > 480 ? Colors.red : Colors.blue, fontWeight: FontWeight.bold)
                            ),
                          )
                        ],
                      ),
                      const Divider(height: 30),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: kayit.seanslar.length,
                          itemBuilder: (context, i) {
                            final s = kayit.seanslar[i];
                            
                            // Dinlenme Süresi Hesaplama
                            Widget dinlenmeWidget = const SizedBox.shrink();
                            if (i > 0) {
                              final oncekiSeansCikarma = kayit.seanslar[i-1].cikarma;
                              int dinlenmeDk = s.takma.difference(oncekiSeansCikarma).inMinutes;
                              if (dinlenmeDk > 0) {
                                dinlenmeWidget = Padding(
                                  padding: const EdgeInsets.only(left: 35, bottom: 8, top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_downward_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text("${dinlenmeDk ~/ 60}s ${dinlenmeDk % 60}d dinlenme süresi", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                );
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dinlenmeWidget,
                                Card(
                                  elevation: 0,
                                  color: const Color(0xFFF8FAFC),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.lens_blur_rounded, color: Colors.indigo, size: 20),
                                                const SizedBox(width: 8),
                                                Text("${i+1}. Seans", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
                                              ],
                                            ),
                                            Text("${s.sureDk ~/ 60}s ${s.sureDk % 60}d", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.login_rounded, size: 16, color: Colors.green),
                                            const SizedBox(width: 6),
                                            Text("Takma: ${s.takma.hour.toString().padLeft(2,'0')}:${s.takma.minute.toString().padLeft(2,'0')}"),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                                            const SizedBox(width: 6),
                                            Text("Çıkarma: ${s.cikarma.hour.toString().padLeft(2,'0')}:${s.cikarma.minute.toString().padLeft(2,'0')}"),
                                          ],
                                        ),
                                        if (s.sikayet != null && s.sikayet!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                                                const SizedBox(width: 8),
                                                Expanded(child: Text('Şikayet Notu: "${s.sikayet}"', style: TextStyle(color: Colors.orange.shade900, fontSize: 13, fontStyle: FontStyle.italic))),
                                              ],
                                            ),
                                          )
                                        ],
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () async {
                                              await _seansSil(kayit, s);
                                              setSheetState(() {});
                                            }, 
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), 
                                            label: const Text("Sil", style: TextStyle(color: Colors.redAccent))
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_aylikBaslangic == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              DateTime? sec = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now());
              if (sec != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('aylik_lens_baslangic_v10', sec.toIso8601String());
                _verileriYukle();
              }
            },
            child: const Text("Aylık Başlangıcı Seç"),
          ),
        ),
      );
    }

    int gunlukGecenDakika = _gunlukTaktigimZaman != null ? DateTime.now().difference(_gunlukTaktigimZaman!).inMinutes : 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Lens Yönetim Merkezi", style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Marka: $_marka", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      Chip(label: Text("Kalan Hak: $_kalanLensGunu Gün"), backgroundColor: Colors.indigo.shade50, labelStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold))
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _GozIkonuVeri("Sağ Göz (OD)", _sagNo),
                      _GozIkonuVeri("Sol Göz (OS)", _solNo),
                    ],
                  )
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: _gunlukTaktigimZaman == null 
                  ? const LinearGradient(colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)])
                  : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
                borderRadius: BorderRadius.circular(24)
              ),
              child: Column(
                children: [
                  if (_gunlukTaktigimZaman == null) ...[
                    const Text("Lens kutusunda dezenfekte ediliyor.", style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _gunlukLensTak, icon: const Icon(Icons.play_circle_fill_rounded), label: const Text("Lensi Taktım (Başlat)")
                    )
                  ] else ...[
                    const Text("Gözdeki Aktif Süre", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text("${gunlukGecenDakika ~/ 60} Saat ${gunlukGecenDakika % 60} Dk", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: _lensiCikarDialog, icon: const Icon(Icons.stop_circle_rounded), label: const Text("Lensi Çıkardım")
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 15),
            if (_kalanLensGunu == 0)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                onPressed: () async {
                  DateTime? sec = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2023), lastDate: DateTime.now(), helpText: 'Yeni Paket Açılış Tarihi');
                  if (sec != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('aylik_lens_baslangic_v10', sec.toIso8601String());
                    _verileriYukle();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text("YENİ LENS PAKETİNE GEÇ", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _gosterilenAy = DateTime(_gosterilenAy.year, _gosterilenAy.month - 1, 1))),
                Text(_ayIsmiGetir(_gosterilenAy), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _gosterilenAy = DateTime(_gosterilenAy.year, _gosterilenAy.month + 1, 1))),
              ],
            ),
            const SizedBox(height: 8),
            _miniTakvimCiz(),
            const SizedBox(height: 25),
            OutlinedButton.icon(onPressed: _gecmisKayitEkle, icon: const Icon(Icons.add), label: const Text("Geçmiş Seans Gir")),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _ayIsmiGetir(DateTime tarih) {
    const aylar = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"];
    return "${aylar[tarih.month - 1]} ${tarih.year}";
  }

  // YENİLENMİŞ TAKVİM GÖRÜNÜMÜ
  Widget _miniTakvimCiz() {
    int aydakiGunSayisi = DateUtils.getDaysInMonth(_gosterilenAy.year, _gosterilenAy.month);
    List<Widget> gunKutulari = [];
    
    for (int gun = 1; gun <= aydakiGunSayisi; gun++) {
      String formatliGun = "${_gosterilenAy.year}-${_gosterilenAy.month.toString().padLeft(2, '0')}-${gun.toString().padLeft(2, '0')}";
      int index = _kayitlar.indexWhere((k) => k.tarih == formatliGun);
      GunlukLensKaydi? kayit = index != -1 ? _kayitlar[index] : null;

      bool kullanildiMi = kayit != null && kayit.seanslar.isNotEmpty;
      bool sekizSaatiGectiMi = kullanildiMi && kayit.toplamSureDk > 480;
      bool sikayetVarMi = kullanildiMi && kayit.sikayetVarMi;

      gunKutulari.add(
        GestureDetector(
          onTap: kullanildiMi ? () => _gunDetayiniGoster(kayit) : null,
          child: Container(
            decoration: BoxDecoration(
              color: kullanildiMi ? Colors.transparent : Colors.white,
              gradient: kullanildiMi ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kullanildiMi ? Colors.transparent : Colors.grey.shade300),
              boxShadow: kullanildiMi ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    gun.toString(), 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kullanildiMi ? Colors.white : Colors.black87)
                  )
                ),
                // Şikayet Bildirim İkonu (Sol Alt)
                if (sikayetVarMi)
                  Positioned(
                    bottom: 2, left: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.chat_bubble_rounded, color: Colors.orange, size: 10),
                    ),
                  ),
                // 8 Saati Aşma İkonu (Sağ Üst)
                if (sekizSaatiGectiMi)
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.priority_high_rounded, color: Colors.red, size: 10),
                    ),
                  ),
              ],
            ),
          ),
        )
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.count(
        shrinkWrap: true, 
        physics: const NeverScrollableScrollPhysics(), 
        crossAxisCount: 7, 
        crossAxisSpacing: 8, 
        mainAxisSpacing: 8, 
        children: gunKutulari
      ),
    );
  }
}

class _GozIkonuVeri extends StatelessWidget {
  final String baslik;
  final String deger;
  const _GozIkonuVeri(this.baslik, this.deger);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(deger, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo)),
      ],
    );
  }
}
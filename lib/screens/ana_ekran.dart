import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/regl_model.dart';
import '../services/notification_service.dart';
import 'profil_sayfasi.dart';
import 'lens_detay_sayfasi.dart';
import 'regl_detay_sayfasi.dart';
import 'sikayetler_sayfasi.dart';

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});
  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  String _isim = "";
  int _yas = 0;
  bool _lensKullanimi = true;
  String _aktifKutuMesaj = "";
  String _aktifKutuHedef = "";

  @override
  void initState() {
    super.initState();
    _yukleVeHesapla();
  }

  Future<void> _yukleVeHesapla() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isim = prefs.getString('isim') ?? "Kullanıcı";
    _yas = prefs.getInt('yas') ?? 0;
    _lensKullanimi = prefs.getBool('lens_kullanimi') ?? true;

    String yeniKutuMesaj = "";
    String yeniKutuHedef = "";
    DateTime suAn = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // --- REGL & OVULASYON HESAPLAMA ---
    List<String> hamRegl = prefs.getStringList('regl_donemleri_v10') ?? [];
    if (hamRegl.isNotEmpty) {
      List<ReglDonemi> donemler = hamRegl.map((e) => ReglDonemi.fromMap(jsonDecode(e))).toList();
      donemler.sort((a, b) => b.baslangicTarihi.compareTo(a.baslangicTarihi));
      int dongu = prefs.getInt('dongu_suresi_v10') ?? 28;
      
      DateTime tahmini = donemler.first.baslangicTarihi.add(Duration(days: dongu));
      int kalan = tahmini.difference(suAn).inDays;

      // Ovulasyon (Doğurganlık) Penceresi Hesaplama
      DateTime yumurtlamaGunu = tahmini.subtract(const Duration(days: 14));
      DateTime ovulasyonBaslangic = yumurtlamaGunu.subtract(const Duration(days: 5));
      DateTime ovulasyonBitis = yumurtlamaGunu.add(const Duration(days: 1));

      if (kalan == 3 || kalan == 1 || kalan == 0) {
        yeniKutuHedef = "regl";
        if (kalan == 3) {
          yeniKutuMesaj = "Peryoduna son 3 gün kaldı! Hazırlıklı olmak isteyebilirsin.";
          BildirimServisi.anlikSesliBildirimGoster(id: 101, baslik: "Regl Yaklaşıyor 🩸", govde: "Döngünün başlamasına son 3 gün kaldı.", payload: "regl");
        } else if (kalan == 1) {
          yeniKutuMesaj = "Yarın yeni bir döngü başlıyor gözüküyor. Modunu yüksek tut!";
          BildirimServisi.anlikSesliBildirimGoster(id: 102, baslik: "Regle Son 1 Gün! 🗓️", govde: "Tahmini döngü başlangıcın yarın.", payload: "regl");
        } else {
          yeniKutuMesaj = "Bugün tahmini döngü günün. Detayları girmek için dokun.";
          BildirimServisi.anlikSesliBildirimGoster(id: 103, baslik: "Döngü Günü Geldi! ✨", govde: "Bugün döngünün başlaması öngörülüyor.", payload: "regl");
        }
      } 
      // Eğer regl uyarısı yoksa, ovulasyon döneminde mi ona bakalım
      else if (!suAn.isBefore(ovulasyonBaslangic) && !suAn.isAfter(ovulasyonBitis)) {
        yeniKutuHedef = "regl";
        if (suAn.isAtSameMomentAs(yumurtlamaGunu)) {
          yeniKutuMesaj = "Bugün yumurtlama (ovulasyon) gününüz! Doğurganlık ihtimalinin en yüksek olduğu gün.";
        } else {
          yeniKutuMesaj = "Şu an yüksek doğurganlık (ovulasyon) penceresi içindesiniz.";
        }
      }
    }

    // --- LENS SÜRE KONTROLÜ ---
    String? gunlukLensZamani = prefs.getString('gunluk_takma_zamani_v10');
    if (gunlukLensZamani != null && _lensKullanimi) {
      DateTime takmaZamani = DateTime.parse(gunlukLensZamani);
      int gecenDk = DateTime.now().difference(takmaZamani).inMinutes;
      
      if (gecenDk >= 450 && gecenDk < 480) {
        yeniKutuMesaj = "Gözündeki lenslerin 8 saatlik günlük sınırı aşmak üzere!";
        yeniKutuHedef = "lens";
        BildirimServisi.anlikSesliBildirimGoster(id: 201, baslik: "Lens Sınırı Yaklaşıyor! ⏳", govde: "Lensler yaklaşık 7.5 saattir gözünde.", payload: "lens");
      } else if (gecenDk >= 480) {
        yeniKutuMesaj = "Kritik Süre! Lensler gözünde 8 saati doldurdu, hemen çıkarman önerilir!";
        yeniKutuHedef = "lens";
        BildirimServisi.anlikSesliBildirimGoster(id: 202, baslik: "8 Saatlik Süre Doldu! 🚨", govde: "Göz sağlığınız için lenslerinizi çıkarın.", payload: "lens");
      }
    }

    setState(() {
      _aktifKutuMesaj = yeniKutuMesaj;
      _aktifKutuHedef = yeniKutuHedef;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Günlük Dengem", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilSayfasi()));
              _yukleVeHesapla();
            },
            icon: const Icon(Icons.account_circle, color: Color(0xFF64748B), size: 28)
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Selam, $_isim! ✨", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          if (_yas > 0) Text("Yaş: $_yas • Bugün Harika Bir Gün!", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            if (_aktifKutuMesaj.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, double val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.scale(
                        scale: val,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFE4E6))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.campaign_rounded, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 8),
                                  const Text("Sistem Uyarısı", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9F1239))),
                                  const Spacer(),
                                  IconButton(icon: const Icon(Icons.close, size: 18, color: Color(0xFF9F1239)), onPressed: () => setState(() => _aktifKutuMesaj = ""))
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(_aktifKutuMesaj, style: const TextStyle(color: Color(0xFF4C0519), fontSize: 13)),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    if (_aktifKutuHedef == "lens") Navigator.push(context, MaterialPageRoute(builder: (context) => const LensDetaySayfasi()));
                                    else if (_aktifKutuHedef == "regl") Navigator.push(context, MaterialPageRoute(builder: (context) => const ReglDetaySayfasi()));
                                  },
                                  child: const Text("Detaylara Git ➔", style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(left: 26.0, top: 16, bottom: 8),
              child: Text("YÖNETİM PANELİ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1.1)),
            ),
            if (_lensKullanimi) ...[
              const _ModernArayuzKarti(baslik: "Lens Asistanı", altBaslik: "Kalan aylık gün, numara ve seanslar.", ikon: Icons.remove_red_eye_rounded, baslangicRenk: Color(0xFF0EA5E9), bitisRenk: Color(0xFF2563EB), sayfa: LensDetaySayfasi()),
              const _ModernArayuzKarti(baslik: "Göz Şikayetlerim", altBaslik: "Oturum bazlı batma ve yanma kayıtları.", ikon: Icons.health_and_safety_rounded, baslangicRenk: Color(0xFFF59E0B), bitisRenk: Color(0xFFD97706), sayfa: SikayetlerSayfasi()),
            ],
            const _ModernArayuzKarti(baslik: "Regl Takip Sistemi", altBaslik: "Ovulasyon dönemi ve döngü takibi.", ikon: Icons.auto_awesome_rounded, baslangicRenk: Color(0xFFEC4899), bitisRenk: Color(0xFFBE185D), sayfa: ReglDetaySayfasi()),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ModernArayuzKarti extends StatefulWidget {
  final String baslik;
  final String altBaslik;
  final IconData ikon;
  final Color baslangicRenk;
  final Color bitisRenk;
  final Widget sayfa;

  const _ModernArayuzKarti({required this.baslik, required this.altBaslik, required this.ikon, required this.baslangicRenk, required this.bitisRenk, required this.sayfa});

  @override
  State<_ModernArayuzKarti> createState() => _ModernArayuzKartiState();
}

class _ModernArayuzKartiState extends State<_ModernArayuzKarti> {
  double _olcek = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _olcek = 0.97),
      onTapUp: (_) {
        setState(() => _olcek = 1.0);
        Navigator.push(context, MaterialPageRoute(builder: (context) => widget.sayfa));
      },
      onTapCancel: () => setState(() => _olcek = 1.0),
      child: AnimatedScale(
        scale: _olcek,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.baslangicRenk, widget.bitisRenk], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(widget.ikon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.baslik, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(widget.altBaslik, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
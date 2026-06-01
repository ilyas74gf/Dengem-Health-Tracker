import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/regl_model.dart';

class ReglDetaySayfasi extends StatefulWidget {
  const ReglDetaySayfasi({super.key});
  @override
  State<ReglDetaySayfasi> createState() => _ReglDetaySayfasiState();
}

class _ReglDetaySayfasiState extends State<ReglDetaySayfasi> {
  List<ReglDonemi> _donemler = [];
  int _donguSuresi = 28;
  final TextEditingController _donguController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  @override
  void dispose() {
    _donguController.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> hamListe = prefs.getStringList('regl_donemleri_v10') ?? [];
    setState(() {
      _donemler = hamListe.map((e) => ReglDonemi.fromMap(jsonDecode(e))).toList();
      _donemler.sort((a, b) => b.baslangicTarihi.compareTo(a.baslangicTarihi));
      _donguSuresi = prefs.getInt('dongu_suresi_v10') ?? 28;
      _donguController.text = _donguSuresi.toString();
    });
  }

  Future<void> _verileriKaydet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('regl_donemleri_v10', _donemler.map((e) => jsonEncode(e.toMap())).toList());
    await prefs.setInt('dongu_suresi_v10', _donguSuresi);
  }

  Future<void> _sonReglBaslangiciniGir() async {
    DateTime suAn = DateTime.now();
    DateTime? secilenBaslangic = await showDatePicker(context: context, initialDate: suAn, firstDate: DateTime(2024), lastDate: suAn);

    if (secilenBaslangic == null || !mounted) return;

    bool? devamEdiyor = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Regl Durumu"),
        content: const Text("Bu regl dönemi hala devam ediyor mu?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Bitti (Tarih Seç)")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white), onPressed: () => Navigator.pop(context, true), child: const Text("Devam Ediyor")),
        ],
      ),
    );

    if (devamEdiyor == null) return;
    DateTime? secilenBitis;
    
    if (!devamEdiyor) {
      secilenBitis = await showDatePicker(
        context: context, initialDate: secilenBaslangic, firstDate: secilenBaslangic, lastDate: DateTime.now().add(const Duration(days: 15))
      );
      if (secilenBitis == null) return;
    }

    setState(() {
      _donemler.add(ReglDonemi(baslangicTarihi: secilenBaslangic, bitisTarihi: secilenBitis));
      _donemler.sort((a, b) => b.baslangicTarihi.compareTo(a.baslangicTarihi));
    });
    _verileriKaydet();
  }

  Future<void> _reglSonlandir(int index) async {
    DateTime baslangic = _donemler[index].baslangicTarihi;
    DateTime? secilenBitis = await showDatePicker(
      context: context, initialDate: DateTime.now().isBefore(baslangic) ? baslangic : DateTime.now(), firstDate: baslangic, lastDate: DateTime.now().add(const Duration(days: 15))
    );

    if (secilenBitis != null) {
      setState(() => _donemler[index] = ReglDonemi(baslangicTarihi: _donemler[index].baslangicTarihi, bitisTarihi: secilenBitis));
      _verileriKaydet();
    }
  }

  void _donemSil(int index) {
    setState(() => _donemler.removeAt(index));
    _verileriKaydet();
  }
  
  // Pratik bir tarih formatlayıcı
  String _formatTarih(DateTime d) => "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}";

  @override
  Widget build(BuildContext context) {
    ReglDonemi? enSonDonem = _donemler.isNotEmpty ? _donemler.first : null;
    DateTime? referansBaslangic = enSonDonem?.baslangicTarihi;
    
    DateTime? sonrakiTahminiRegl;
    DateTime? yumurtlamaGunu;
    DateTime? ovulasyonBaslangic;
    DateTime? ovulasyonBitis;
    int kalanGun = 0;

    if (referansBaslangic != null) {
      sonrakiTahminiRegl = referansBaslangic.add(Duration(days: _donguSuresi));
      kalanGun = sonrakiTahminiRegl.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
      
      // Tıbbi Ovulasyon Penceresi Hesabı (Tahmini reglden 14 gün öncesi)
      yumurtlamaGunu = sonrakiTahminiRegl.subtract(const Duration(days: 14));
      ovulasyonBaslangic = yumurtlamaGunu.subtract(const Duration(days: 5));
      ovulasyonBitis = yumurtlamaGunu.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Regl İzleme Paneli"), backgroundColor: Colors.pink.shade50),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]), borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  const Text("Sonraki Periyoda Kalan Gün", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(enSonDonem == null ? "Veri Yok" : "$kalanGun Gün", style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(child: Text("Döngü Süresi (Gün):", style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: _donguController, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.zero),
                    onChanged: (v) { if(v.isNotEmpty) { setState(() => _donguSuresi = int.parse(v)); _verileriKaydet(); } }
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _sonReglBaslangiciniGir, icon: const Icon(Icons.add_circle), label: const Text("Yeni Regl Dönemi Ekle", style: TextStyle(fontWeight: FontWeight.bold))
            ),
            const SizedBox(height: 20),
            if (referansBaslangic == null)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Tahminleri görmek için lütfen bir başlangıç tarihi ekle.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ))
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [Icon(Icons.calendar_today, size: 16, color: Colors.deepOrangeAccent), SizedBox(width: 6), Text("Tahmini Regl", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 10),
                          Text("${sonrakiTahminiRegl!.day}/${sonrakiTahminiRegl.month}/${sonrakiTahminiRegl.year}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(kalanGun > 0 ? "$kalanGun gün kaldı" : (kalanGun == 0 ? "Bugün bekleniyor" : "${kalanGun.abs()} gün gecikti"), style: TextStyle(fontSize: 12, color: kalanGun >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // YENİ OVULASYON DÖNEMİ KARTI
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.purple.shade100)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [Icon(Icons.egg_alt_outlined, size: 16, color: Colors.purple), SizedBox(width: 6), Text("Ovulasyon", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple))]),
                          const SizedBox(height: 8),
                          Text("${_formatTarih(ovulasyonBaslangic!)} - ${_formatTarih(ovulasyonBitis!)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purple)),
                          const SizedBox(height: 2),
                          Text("Yumurtlama: ${_formatTarih(yumurtlamaGunu!)}", style: TextStyle(fontSize: 12, color: Colors.purple.shade800, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Kayıtlı Başlangıç Tarihleri", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 8),
              if (_donemler.isEmpty)
                const Text("Geçmişte kayıtlı bir döngün bulunmuyor.", style: TextStyle(color: Colors.grey, fontSize: 13))
              else
                ListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _donemler.length,
                  itemBuilder: (context, index) {
                    final d = _donemler[index];
                    String tarihMetni = "${d.baslangicTarihi.day}/${d.baslangicTarihi.month}/${d.baslangicTarihi.year} - " + 
                        (d.bitisTarihi == null ? "Devam Ediyor" : "${d.bitisTarihi!.day}/${d.bitisTarihi!.month}/${d.bitisTarihi!.year}");
                    return Card(
                      elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFF1F5F9))),
                      child: ListTile(
                        leading: const Icon(Icons.water_drop_rounded, color: Colors.pink),
                        title: Text(tarihMetni, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (d.bitisTarihi == null) IconButton(icon: const Icon(Icons.stop_circle_outlined, color: Colors.green), onPressed: () => _reglSonlandir(index)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _donemSil(index)),
                          ],
                        ),
                      ),
                    );
                  },
                )
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lens_model.dart';

class SikayetlerSayfasi extends StatefulWidget {
  const SikayetlerSayfasi({super.key});
  @override
  State<SikayetlerSayfasi> createState() => _SikayetlerSayfasiState();
}

class _SikayetlerSayfasiState extends State<SikayetlerSayfasi> {
  List<GunlukLensKaydi> _kayitlar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> hamVeri = prefs.getStringList('lens_kayitlari_v10') ?? [];
    List<GunlukLensKaydi> tumKayitlar = hamVeri.map((e) => GunlukLensKaydi.fromMap(jsonDecode(e))).toList();
    
    setState(() {
      _kayitlar = tumKayitlar.where((g) => g.sikayetVarMi).toList();
      _kayitlar.sort((a, b) => b.tarih.compareTo(a.tarih));
    });
  }

  Future<void> _sikayetDuzenle(String tarih, DateTime takmaZamani, String eskiSikayet) async {
    TextEditingController controller = TextEditingController(text: eskiSikayet);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Şikayeti Düzenle"),
          content: TextField(
            controller: controller, maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Şikayetini güncelle veya sil"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () async {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> hamVeri = prefs.getStringList('lens_kayitlari_v10') ?? [];
                List<GunlukLensKaydi> tumListe = hamVeri.map((e) => GunlukLensKaydi.fromMap(jsonDecode(e))).toList();

                for (var gun in tumListe) {
                  if (gun.tarih == tarih) {
                    for (var seans in gun.seanslar) {
                      if (seans.takma == takmaZamani) {
                        seans.sikayet = controller.text;
                        break;
                      }
                    }
                  }
                }
                await prefs.setStringList('lens_kayitlari_v10', tumListe.map((e) => jsonEncode(e.toMap())).toList());
                if (mounted) Navigator.pop(context);
                _yukle(); 
              },
              child: const Text("Kaydet")
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Şikayet Arşivi", style: TextStyle(fontWeight: FontWeight.bold))),
      body: _kayitlar.isEmpty
          ? const Center(child: Text("Harika! Kaydedilmiş bir göz şikayetin yok. 🌱", style: TextStyle(color: Colors.grey, fontSize: 15)))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _kayitlar.length,
              itemBuilder: (context, index) {
                final gun = _kayitlar[index];
                final sikayetliSeanslar = gun.seanslar.where((s) => s.sikayet != null && s.sikayet!.trim().isNotEmpty).toList();

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 0,
                  color: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFFDE68A))),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(gun.tarih, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                    children: sikayetliSeanslar.map((s) => ListTile(
                      leading: const Icon(Icons.blur_on_rounded, color: Colors.amber),
                      title: Text("${s.takma.hour.toString().padLeft(2,'0')}:${s.takma.minute.toString().padLeft(2,'0')} Seansı", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('"${s.sikayet!}"', style: const TextStyle(fontSize: 14, color: Color(0xFF78350F))),
                      trailing: IconButton(
                        icon: const Icon(Icons.mode_edit_outline_rounded, size: 18, color: Colors.indigo),
                        onPressed: () => _sikayetDuzenle(gun.tarih, s.takma, s.sikayet!),
                      ),
                    )).toList(),
                  ),
                );
              },
            ),
    );
  }
}
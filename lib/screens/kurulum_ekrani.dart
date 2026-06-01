import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ana_ekran.dart';

class KurulumEkrani extends StatefulWidget {
  const KurulumEkrani({super.key});
  @override
  State<KurulumEkrani> createState() => _KurulumEkraniState();
}

class _KurulumEkraniState extends State<KurulumEkrani> {
  final TextEditingController _isimC = TextEditingController();
  final TextEditingController _yasC = TextEditingController();
  final TextEditingController _markaC = TextEditingController();
  final TextEditingController _sagNoC = TextEditingController();
  final TextEditingController _solNoC = TextEditingController();
  bool _lensKullanimi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.spa_rounded, size: 60, color: Color(0xFF6366F1)),
              const SizedBox(height: 14),
              const Text("Dengem'e Hoş Geldin", textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              const Text("Profilinizi ve rutin ayarlarınızı hızlıca yapın.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 30),
              
              TextField(controller: _isimC, decoration: _inputDekorasyonu("İsminiz nedir?", Icons.person)),
              const SizedBox(height: 14),
              TextField(controller: _yasC, keyboardType: TextInputType.number, decoration: _inputDekorasyonu("Yaşınız", Icons.cake)),
              const SizedBox(height: 14),
              
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: SwitchListTile(
                  title: const Text("Lens kullanıyor musun?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  activeColor: const Color(0xFF6366F1), value: _lensKullanimi, onChanged: (v) => setState(() => _lensKullanimi = v),
                ),
              ),
              
              if (_lensKullanimi) ...[
                const Padding(padding: EdgeInsets.only(top: 20.0, bottom: 8, left: 4), child: Text("Lens Bilgileriniz", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
                TextField(controller: _markaC, decoration: _inputDekorasyonu("Lens Markası (Örn: Acuvue)", Icons.bookmark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _sagNoC, keyboardType: TextInputType.number, decoration: _inputDekorasyonu("Sağ (OD)", Icons.remove_red_eye))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _solNoC, keyboardType: TextInputType.number, decoration: _inputDekorasyonu("Sol (OS)", Icons.remove_red_eye))),
                  ],
                )
              ],
              
              const SizedBox(height: 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  if (_isimC.text.isEmpty) return;
                  final SharedPreferences p = await SharedPreferences.getInstance();
                  await p.setBool('kayitli_mi', true);
                  await p.setString('isim', _isimC.text);
                  await p.setInt('yas', int.tryParse(_yasC.text) ?? 0);
                  await p.setBool('lens_kullanimi', _lensKullanimi);
                  
                  if (_lensKullanimi) {
                    await p.setString('lens_markasi', _markaC.text.isEmpty ? "-" : _markaC.text);
                    await p.setString('sag_numara', _sagNoC.text.isEmpty ? "-" : _sagNoC.text);
                    await p.setString('sol_numara', _solNoC.text.isEmpty ? "-" : _solNoC.text);
                  }
                  if (!mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AnaEkran()));
                },
                child: const Text("Kurulumu Tamamla 🚀", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDekorasyonu(String etiket, IconData ikon) {
    return InputDecoration(
      labelText: etiket, prefixIcon: Icon(ikon, size: 20, color: const Color(0xFF64748B)), labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), filled: true, fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
    );
  }
}
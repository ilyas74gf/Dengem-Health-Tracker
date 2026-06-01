import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // ThemeNotifier için
import 'kurulum_ekrani.dart';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});
  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _yasController = TextEditingController();
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _sagNoController = TextEditingController();
  final TextEditingController _solNoController = TextEditingController();
  
  bool _lensKullanimi = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _profilYukle();
  }

  @override
  void dispose() {
    _isimController.dispose();
    _yasController.dispose();
    _markaController.dispose();
    _sagNoController.dispose();
    _solNoController.dispose();
    super.dispose();
  }

  Future<void> _profilYukle() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isimController.text = prefs.getString('isim') ?? "";
      int yas = prefs.getInt('yas') ?? 0;
      _yasController.text = yas > 0 ? yas.toString() : "";
      
      _lensKullanimi = prefs.getBool('lens_kullanimi') ?? false;
      _markaController.text = prefs.getString('lens_markasi') ?? "";
      _sagNoController.text = prefs.getString('sag_numara') ?? "";
      _solNoController.text = prefs.getString('sol_numara') ?? "";
      
      _isDarkMode = prefs.getBool('is_dark_mode') ?? (themeNotifier.value == ThemeMode.dark);
    });
  }

  Future<void> _bilgileriKaydet() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('isim', _isimController.text);
    await prefs.setInt('yas', int.tryParse(_yasController.text) ?? 0);
    await prefs.setBool('lens_kullanimi', _lensKullanimi);
    
    if (_lensKullanimi) {
      await prefs.setString('lens_markasi', _markaController.text);
      await prefs.setString('sag_numara', _sagNoController.text);
      await prefs.setString('sol_numara', _solNoController.text);
    }
    
    if (!mounted) return;
    
    // Başarılı kaydetme bildirimi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text("Profil bilgileri başarıyla güncellendi!", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color kartRengi = isDark ? const Color(0xFF1E293B) : Colors.white;
    Color yaziRengi = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      appBar: AppBar(title: const Text("Profil ve Ayarlar", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // PROFİL DÜZENLEME KARTI
          Card(
            elevation: 0,
            color: const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(radius: 40, backgroundColor: Color(0xFF6366F1), child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _isimController,
                    style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "İsim", labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6366F1)),
                      filled: true, fillColor: isDark ? Colors.black12 : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _yasController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Yaş", labelStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF6366F1)),
                      filled: true, fillColor: isDark ? Colors.black12 : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // TEMA VE LENS KULLANIMI KARTI
          const Padding(
            padding: EdgeInsets.only(left: 4.0, bottom: 8),
            child: Text("Uygulama Ayarları", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
          ),
          Card(
            elevation: 0, color: kartRengi,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(_isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: const Color(0xFF6366F1)),
                  title: Text("Karanlık Mod", style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold)),
                  activeColor: const Color(0xFF6366F1),
                  value: _isDarkMode,
                  onChanged: (val) async {
                    setState(() => _isDarkMode = val);
                    themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    final SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('is_dark_mode', val);
                  },
                ),
                Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                SwitchListTile(
                  secondary: const Icon(Icons.remove_red_eye, color: Color(0xFF3B82F6)),
                  title: Text("Lens Kullanıyorum", style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold)),
                  activeColor: const Color(0xFF3B82F6),
                  value: _lensKullanimi,
                  onChanged: (val) {
                    setState(() => _lensKullanimi = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // LENS BİLGİLERİ DÜZENLEME KARTI
          if (_lensKullanimi) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4.0, bottom: 8),
              child: Text("Lens Bilgilerim", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),
            Card(
              elevation: 0, color: kartRengi,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0))),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _markaController,
                      style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Lens Markası", labelStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.bookmark_outline, color: Color(0xFF3B82F6)), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _sagNoController,
                            style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Sağ (OD)", labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF3B82F6)), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _solNoController,
                            style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Sol (OS)", labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF3B82F6)), 
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          
          // KAYDET BUTONU
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: _bilgileriKaydet,
            icon: const Icon(Icons.save_rounded),
            label: const Text("Bilgilerimi Güncelle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          ),

          const SizedBox(height: 40),
          
          // VERİLERİ SİL BUTONU (Küçük - Sadece Tıklanabilir Yazı)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              bool? onayla = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: kartRengi,
                  title: Text("Tüm Verileri Sil", style: TextStyle(color: yaziRengi, fontWeight: FontWeight.bold)),
                  content: Text("Geçmiş lens seanslarınız, regl döngüleriniz ve profil bilgileriniz kalıcı olarak silinecektir. Bu işlem geri alınamaz. Emin misiniz?", style: TextStyle(color: yaziRengi)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text("Evet, Her Şeyi Sil", style: TextStyle(color: Colors.white))
                    )
                  ],
                ),
              );

              if (onayla == true) {
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KurulumEkrani()), (route) => false);
              }
            }, 
            icon: const Icon(Icons.delete_forever), 
            label: const Text("Tüm Verilerimi Sil ve Sıfırla")
          )
        ],
      ),
    );
  }
}
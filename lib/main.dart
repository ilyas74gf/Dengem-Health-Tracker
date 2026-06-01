import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'screens/kurulum_ekrani.dart';
import 'screens/ana_ekran.dart';

// Tüm uygulamada temayı anlık değiştirebilmek için Global Notifier
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BildirimServisi.init(); 
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool kayitliMi = prefs.getBool('kayitli_mi') ?? false;
  
  // Kayıtlı tema ayarını hafızadan çekiyoruz
  final bool? isDark = prefs.getBool('is_dark_mode');
  if (isDark != null) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  runApp(RutinUygulamam(kayitliMi: kayitliMi));
}

class RutinUygulamam extends StatelessWidget {
  final bool kayitliMi;
  const RutinUygulamam({super.key, required this.kayitliMi});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Rutin Sağlık Takibi', // Uygulama ismi güncellendi
          themeMode: currentMode, // Aydınlık/Karanlık mod dinleyicisi
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A), // Gece mavisi/siyah arka plan
            fontFamily: 'Roboto',
          ),
          home: kayitliMi ? const AnaEkran() : const KurulumEkrani(),
        );
      }
    );
  }
}
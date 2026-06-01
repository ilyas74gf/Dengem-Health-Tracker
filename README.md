# 🪻 Dengem - Kişisel Sağlık ve Rutin Takip Otomasyonu

**Dengem**, kullanıcıların günlük sağlık rutinlerini dijitalleştirerek göz sağlığı (lens kullanımı, şikayet takibi) ve biyolojik döngülerini (menstrüasyon/regl periyotları) tek bir modern arayüz üzerinden analiz etmelerini sağlayan kapsamlı bir kişisel sağlık otomasyon projesidir.

---

## 🎯 Projenin Öne Çıkan Özellikleri ve Modülleri

Uygulama, kullanıcı dostu bir onboarding (kurulum) ekranıyla başlar; kullanıcının yaş, lens markası ve göz numarası (OD/OS) gibi temel sağlık parametrelerini alarak kişiselleştirilmiş bir dashboard (yönetim paneli) oluşturur.

### 👁️ 1. Gelişmiş Lens Asistanı & Göz Sağlığı Takibi
Düzenli lens kullanan bireylerin göz sağlığını korumak amacıyla tasarlanmış, zaman tabanlı bir otomasyon modülüdür.
* **Aktif Süre Sayacı (Kronometre):** Lensin gözde kaldığı süreyi anlık olarak (Saat/Dakika) kaydeder. Kullanıcı "Lensi Çıkardım" dediğinde sistem arka planda lensin kutuda dezenfekte edildiği moda geçer.
* **Kalan Hak Sayacı:** Lensin türüne göre (Örn: Aylık lens) kalan kullanım gün sayısını dinamik olarak takip eder.
* **Göz Şikayetleri ve Seans Günlüğü:** Kullanıcının lens takılıyken yaşadığı semptomları (*"gözüm yandı"*, *"gözüm kanlandı"*) seans bazlı olarak saat ve süre verisiyle kayıt altına alır. Bu sayede olası göz enfeksiyonlarının önüne geçilmesi hedeflenir.

### 🩸 2. Akıllı Regl Takip Sistemi
Kadın sağlığı süreçlerini izlemeyi kolaylaştıran biyolojik döngü yönetim alanıdır.
* **Periyot Tahminleme ve Geri Sayım:** Bir sonraki periyoda kalan gün sayısını ana panelde dinamik olarak gösterir.
* **Yumurtlama (Ovülasyon) Penceresi:** Geçmiş döngü verilerine dayanarak doğurganlığın yüksek olduğu ovülasyon dönemlerini hesaplar ve takvim üzerinde görselleştirir.
* **Döngü Geçmişi:** Kayıtlı başlangıç ve bitiş tarihlerini listeleyerek kullanıcının düzenli bir sağlık geçmişi tutmasını sağlar.

---

## 🛠️ Teknolojik Altyapı
* **Framework:** Flutter & Dart (Cross-platform mobil ve web mimarisi)
* **UI/UX:** Kullanıcıyı yormayan, medikal standartlara uygun, responsive Gece Modu (Dark Mode) tasarımı.
* **State Management:** Zamanlayıcıların (lens sayaçları) ve kullanıcı şikayet notlarının anlık olarak işlendiği, veri tutarlılığı yüksek mimari.

---

## 📸 Uygulama Arayüzü ve Ekran Görüntüleri

Projenin çalışan ekranlarına ve işlevsel modüllerine ait görsellere yukarıdaki dosya listesinden doğrudan erişebilirsiniz.

*(Görselleri bu alanda önizlemek isterseniz, GitHub editöründeki yazı alanına bilgisayarınızdaki o ekran görüntülerini doğrudan kopyalayıp yapıştırabilir veya sürükleyip bırakabilirsiniz. GitHub uzun isimleri otomatik olarak Markdown formatına dönüştürüp sayfaya gömecektir).*

---

## 📬 İletişim & Bağlantılar
* **İlyas Çetin** - [LinkedIn](https://linkedin.com/in/ilyas-çetin-b753082b6)

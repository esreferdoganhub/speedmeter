# SpeedMeter

macOS menü çubuğunda anlık internet indirme ve yükleme hızlarını gösteren hafif bir uygulama.

## Özellikler

- 🚀 Anlık internet hızı gösterimi (indirme/yükleme)
- 📊 **Gerçek zamanlı grafik görünümü** (SwiftUI)
- 🎯 İnteraktif zaman aralığı seçimi (30sn - 10dk)
- 📈 Maksimum ve ortalama hız istatistikleri
- 🔄 Otomatik birim dönüşümü (KB/s, MB/s, Mbps, Kbps)
- ⚙️ Gelişmiş ayarlar penceresi
- 🔄 0.5-5 saniye arasında ayarlanabilir güncelleme aralığı
- 💻 Düşük sistem kaynağı kullanımı
- 🎯 Menü çubuğu entegrasyonu
- 🚫 Dock'ta görünmez (sadece menü çubuğunda)

## Kurulum

### Gereksinimler
- macOS 13.0 veya üzeri (SwiftUI grafik için)
- Xcode 14.0 veya üzeri

### Derleme

```bash
# Projeyi derle
swift build -c release

# Uygulamayı çalıştır
./.build/release/SpeedMeter
```

### App Bundle Oluşturma

```bash
# Release modunda derle
swift build -c release

# App bundle dizinini oluştur
mkdir -p SpeedMeter.app/Contents/MacOS
mkdir -p SpeedMeter.app/Contents/Resources

# Binary'yi kopyala
cp .build/release/SpeedMeter SpeedMeter.app/Contents/MacOS/

# Info.plist oluştur
cat > SpeedMeter.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SpeedMeter</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmeter.app</string>
    <key>CFBundleName</key>
    <string>SpeedMeter</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Applications klasörüne kopyala (isteğe bağlı)
# cp -r SpeedMeter.app /Applications/
```

## Kullanım

1. Uygulamayı çalıştırın
2. Menü çubuğunda hız göstergesi görünecek
3. **Grafik için:** Menü çubuğu öğesine sağ tıklayın → "Hız Grafiğini Göster"
4. **Ayarlar için:** Menü çubuğu öğesine sağ tıklayın → "Ayarlar"
5. Çıkış için menüden "Çıkış" seçeneğini kullanın

## Grafik Özellikleri

- **Gerçek zamanlı çizgi grafikler** - İndirme (mavi) ve yükleme (yeşil) hızları
- **Zaman aralığı seçimi:** 30 saniye, 1 dakika, 5 dakika, 10 dakika
- **Anlık hız göstergesi** - Büyük yazılarla mevcut hızlar
- **İstatistikler:** Maksimum ve ortalama hız değerleri
- **Grid gösterimi** - Kolay okuma için arka plan ızgarası
- **Otomatik ölçeklendirme** - Y ekseni maksimum hıza göre ayarlanır

## Hız Gösterimi

- `↓ 5.2 MB/s ↑ 1.1 MB/s` - Megabyte/saniye
- `↓ 250 KB/s ↑ 50 KB/s` - Kilobyte/saniye

## Otomatik Başlatma

Uygulamanın sistem başlangıcında otomatik olarak çalışması için:

1. **Sistem Tercihleri** > **Kullanıcılar ve Gruplar** > **Giriş Öğeleri**
2. SpeedMeter.app'i ekleyin

## Geliştirme

### Kod Yapısı

- `main.swift` - Ana uygulama ve menü çubuğu yönetimi
- `NetworkSpeedMonitor.swift` - Ağ hızı izleme motoru (netstat tabanlı)
- `SpeedGraphView.swift` - SwiftUI grafik arayüzü
- `SpeedDataStore.swift` - Hız verilerini sakla ve yönet
- `GraphWindowController.swift` - Grafik penceresi kontrolcüsü
- `SettingsWindowController.swift` - Ayarlar penceresi
- `AppSettings.swift` - Uygulama ayarları modeli

### Yapılandırma

Hız güncellemesi aralığını değiştirmek için `NetworkSpeedMonitor.swift` dosyasındaki `updateInterval` değerini düzenleyin.

## Lisans

MIT License - Detaylar için LICENSE dosyasına bakın.

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun
3. Değişikliklerinizi commit edin
4. Pull request gönderin

## Sorun Giderme

### Uygulama çalışmıyor
- macOS sürümünüzün uyumlu olduğundan emin olun
- Terminal'den çalıştırarak hata mesajlarını kontrol edin

### Hızlar gösterilmiyor
- Ağ bağlantınızı kontrol edin
- Uygulamayı yeniden başlatın

### Yüksek CPU kullanımı
- Güncelleme aralığını artırın
- Başka ağ izleme uygulamalarını kapatın

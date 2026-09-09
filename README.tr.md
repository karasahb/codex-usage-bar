<p align="center">
  <img src="Resources/AppIcon.png" width="160" alt="Codex Usage Bar simgesi">
</p>

<h1 align="center">Codex Usage Bar</h1>

<p align="center">Codex kalan kullanımını gösteren özel ve yerel macOS menü çubuğu uygulaması.</p>

<p align="center"><a href="README.md">English</a></p>

## Özellikler

- 5 saatlik ve haftalık kalan kullanım menü çubuğunda `96% | 36%` biçiminde görünür
- Her pencerenin kesin yenilenme tarihini ve saatini gösterir
- 15–120 saniye aralığında otomatik yenilenir ve canlı limit bildirimlerini dinler
- %25'lik dilimlerde yeşil, sarı, turuncu ve kırmızı renk kullanır
- ChatGPT planını ve varsa yenileme hakkı sayısını gösterir
- Ayarlar'dan ChatGPT/Codex uygulaması veya `codex` çalıştırılabilir dosyası seçilebilir

## Gizlilik

Uygulama API anahtarı, OAuth token'ı, e-posta adresi veya hesap kimliği istemez, kaydetmez ve loglamaz. Yalnızca yerel Codex App Server üzerinden limit özeti okunur; kimlik doğrulama mevcut Codex kurulumunuz tarafından yönetilir.

macOS `UserDefaults` içinde sadece isteğe bağlı Codex yolu ve yenileme aralığı saklanır. Ayrıntılar için [PRIVACY.md](PRIVACY.md) dosyasına bakın.

## Gereksinimler

- macOS 14 veya üstü
- Aktif ChatGPT oturumu bulunan ChatGPT Desktop, Codex Desktop veya Codex CLI
- Kaynaktan derlemek için Xcode 16+ / Swift 6

## Çalıştırma

```bash
swift run CodexUsageBar
```

## Uygulama paketi oluşturma

```bash
Scripts/package_app.sh
open "dist/Codex Usage Bar.app"
```

Paket `dist/Codex Usage Bar.app` konumuna oluşturulur. Bundle kimliğini kaynak dosyaları değiştirmeden özelleştirebilirsiniz:

```bash
CODEX_USAGE_BAR_BUNDLE_ID=io.github.KULLANICI_ADINIZ.CodexUsageBar Scripts/package_app.sh
```

Developer ID dağıtımı için `CODEX_USAGE_BAR_SIGN_IDENTITY` değerini sertifika adınız olarak ayarlayın. `CODEX_USAGE_BAR_VERSION` ve `CODEX_USAGE_BAR_BUILD` paket sürüm alanlarını değiştirir. Notarizasyon özel Apple kimlik bilgileri gerektirdiği için yayın sahibine bırakılmıştır.

## Ayarlar

Menü çubuğundaki pencereyi açıp dişli düğmesine basın. Uygulama varsayılan olarak yaygın ChatGPT, Codex Desktop, Homebrew ve `PATH` konumlarını tarar. Özel yol ve yenileme aralığı kaynak kod değiştirilmeden seçilebilir.

## Güvenlik kontrolü

```bash
swift test
Scripts/check_repository.sh
```

## Not

Bu bağımsız bir açık kaynak projesidir; OpenAI tarafından geliştirilmemiş veya desteklenmemiştir.

## Lisans

[MIT](LICENSE)

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
- macOS Giriş Öğeleri üzerinden isteğe bağlı olarak oturum açılışında başlatılabilir
- İlk çalıştırmada bağlantıyı kontrol eden bir karşılama penceresi sunar
- GitHub Releases üzerinden yeni sürümleri denetler ve indirme bağlantısını gösterir
- macOS dil ayarına göre Türkçe veya İngilizce arayüz kullanır

## Gizlilik

Uygulama API anahtarı, OAuth token'ı, e-posta adresi veya hesap kimliği istemez, kaydetmez ve loglamaz. Yalnızca yerel Codex App Server üzerinden limit özeti okunur; kimlik doğrulama mevcut Codex kurulumunuz tarafından yönetilir.

macOS `UserDefaults` içinde sadece isteğe bağlı Codex yolu, yenileme aralığı ve tek seferlik karşılama ekranının tamamlanma durumu saklanır. Otomatik başlangıç tercihi macOS Giriş Öğeleri tarafından yönetilir.

Uygulama açılışta ve yaklaşık altı saatte bir herkese açık GitHub Releases API'sini kontrol eder; yalnızca uygulama sürümünü user-agent içinde gönderir. Codex kimlik bilgileri veya hesap verileri GitHub'a gönderilmez ve güncellemeler otomatik indirilip kurulmaz. Ayrıntılar için [PRIVACY.md](PRIVACY.md) dosyasına bakın.

## Gereksinimler

- macOS 14 veya üstü
- Aktif ChatGPT oturumu bulunan ChatGPT Desktop, Codex Desktop veya Codex CLI
- Kaynaktan derlemek için Xcode 16+ / Swift 6

## Yayın paketini kurma

1. GitHub Releases sayfasından `Codex-Usage-Bar.zip` dosyasını indirip açın.
2. `Codex Usage Bar.app` dosyasını Applications/Uygulamalar klasörüne taşıyın.
3. Yayın sahibinin Developer ID ile imzalayıp noterlediği sürümler normal şekilde açılır. Yerel ad-hoc paketlerde Control tuşuyla tıklayıp **Aç** seçeneğini veya **Sistem Ayarları → Gizlilik ve Güvenlik → Yine de Aç** yolunu kullanmak gerekebilir.
4. Uygulama, giriş yapılmış ChatGPT Desktop, Codex Desktop veya Codex CLI kurulumunu otomatik bulur.

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

Developer ID dağıtımı için `CODEX_USAGE_BAR_SIGN_IDENTITY` değerini sertifika adınız olarak ayarlayın. `CODEX_USAGE_BAR_VERSION` ve `CODEX_USAGE_BAR_BUILD` paket sürüm alanlarını değiştirir.

İmzalı paketi yerel olarak noterlemek için önce bir `notarytool` anahtar zinciri profili oluşturun, ardından:

```bash
CODEX_USAGE_BAR_SIGN_IDENTITY="Developer ID Application: Örnek (TEAMID)" Scripts/package_app.sh
CODEX_USAGE_BAR_SIGN_IDENTITY="Developer ID Application: Örnek (TEAMID)" \
CODEX_USAGE_BAR_NOTARY_PROFILE="notarytool-profili" Scripts/notarize_app.sh
```

Yayın iş akışı aşağıdaki şifreli GitHub Actions secrets değerlerini zorunlu tutar ve noterlenmemiş paket yayınlamaz:

- `APPLE_CERTIFICATE_P12_BASE64`
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`

## Ayarlar

Menü çubuğundaki pencereyi açıp dişli düğmesine basın. Uygulama varsayılan olarak yaygın ChatGPT, Codex Desktop, Homebrew ve `PATH` konumlarını tarar. Özel yol, yenileme aralığı ve oturum açılışında başlatma tercihi kaynak kod değiştirilmeden seçilebilir. Otomatik başlangıç varsayılan olarak kapalıdır ve macOS Giriş Öğeleri tarafından yönetilir.

## Güvenlik kontrolü

```bash
swift test
Scripts/check_repository.sh
```

## Not

Bu bağımsız bir açık kaynak projesidir; OpenAI tarafından geliştirilmemiş veya desteklenmemiştir.

## Lisans

[MIT](LICENSE)

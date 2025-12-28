# Flex Tarm - Supabase Entegrasyonu

Bu proje Supabase ile güvenli kullanıcı kimlik doğrulama ve veri yönetimi sağlar.

## 🚀 Kurulum Adımları

### 1. Supabase Projesi Oluşturma

1. [Supabase](https://supabase.com) hesabınıza giriş yapın
2. "New Project" butonuna tıklayın
3. Proje adını `flex-tarm` olarak ayarlayın
4. Veritabanı şifresini güvenli bir şekilde saklayın
5. Region'ı Türkiye'ye en yakın olanı seçin (Europe West)

### 2. Veritabanı Şeması Kurulumu

**Eğer daha önce hiç database kurulumu yapmadıysanız:**
1. Supabase Dashboard'da **SQL Editor** sekmesine gidin
2. `final_database_setup.sql` dosyasının içeriğini kopyalayın ve çalıştırın
3. Sonra `incremental_database_update.sql` dosyasının içeriğini kopyalayın ve çalıştırın

**Eğer daha önce database kurulumu yaptıysanız (profiles tablosu zaten mevcut):**
1. Supabase Dashboard'da **SQL Editor** sekmesine gidin
2. Sadece `incremental_database_update.sql` dosyasının içeriğini kopyalayın ve çalıştırın
3. Bu script mevcut tabloları kontrol eder ve sadece eksik olanları ekler

4. Tüm tabloların ve politikaların başarıyla oluşturulduğunu kontrol edin

### 3. Edge Functions Kurulumu

1. Supabase Dashboard'da **Edge Functions** sekmesine gidin
2. **Create a new function** butonuna tıklayın
3. Function adını `get-api-key` olarak ayarlayın
4. `supabase_edge_functions/get-api-key/index.ts` dosyasının içeriğini kopyalayın
5. Function kodunu yapıştırın ve **Deploy** butonuna tıklayın
6. Aynı işlemi `secure-api-call` function'ı için tekrarlayın

### 4. Environment Variables Ayarlama

1. Supabase Dashboard'da **Settings** > **API** sekmesine gidin
2. **Project URL** ve **anon public** key'i kopyalayın
3. Proje klasöründe `assets/.env` dosyası oluşturun:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# OpenAI API Key (Server-side için)
OPENAI_API_KEY=your_openai_api_key_here
GROQ_API_KEY=your_groq_api_key_here
```

4. Edge Functions için **Settings** > **Edge Functions** sekmesine gidin
5. Environment variables ekleyin:
   - `OPENAI_API_KEY`: OpenAI API anahtarınız
   - `GROQ_API_KEY`: Groq API anahtarınız (opsiyonel)

### 5. Flutter Bağımlılıklarını Yükleme

```bash
flutter pub get
```

### 6. Uygulamayı Çalıştırma

```bash
flutter run
```

## 🔐 Güvenlik Özellikleri

### API Anahtarı Güvenliği
- API anahtarları APK içinde saklanmaz
- Supabase Edge Functions üzerinden güvenli şekilde yönetilir
- Kullanıcı bazlı erişim kontrolü

### Veri Güvenliği
- Row Level Security (RLS) ile veri izolasyonu
- Kullanıcılar sadece kendi verilerine erişebilir
- Şifreli veri saklama

### Kimlik Doğrulama
- Supabase Auth ile güvenli kullanıcı yönetimi
- E-posta doğrulama
- Şifre sıfırlama desteği

## 📊 Veritabanı Yapısı

### Tablolar
- **profiles**: Kullanıcı profil bilgileri
- **user_api_keys**: Kullanıcı API anahtarları (şifrelenmiş)
- **crops**: Mahsul verileri
- **marketplace_items**: Pazar yeri ürünleri
- **ai_conversations**: AI konuşma geçmişi
- **user_favorites**: Kullanıcı favorileri
- **user_preferences**: Kullanıcı tercihleri
- **user_activity_log**: Kullanıcı aktivite geçmişi
- **user_notification_preferences**: Bildirim tercihleri

### RLS Politikaları
- Kullanıcılar sadece kendi verilerine erişebilir
- Otomatik profil oluşturma
- Güvenli veri silme

## 🆕 Yeni Özellikler

### Kullanıcı Aktivite Takibi
- **Favoriler**: Mahsuller, pazar yeri ürünleri ve AI konuşmalarını favorilere ekleme
- **Tercihler**: Tema, dil, birim sistemi gibi kullanıcı tercihlerini kaydetme
- **Aktivite Geçmişi**: Tüm kullanıcı aktivitelerini otomatik loglama
- **Bildirim Tercihleri**: Kullanıcıya özel bildirim ayarları

### Otomatik Veri Yükleme
- Kullanıcı giriş yaptığında tüm kişisel verileri otomatik yükleme
- Mahsul ekleme, güncelleme ve silme işlemlerinde aktivite loglama
- Favori ekleme/çıkarma işlemlerinde otomatik takip
- Şehir tercihi otomatik kaydetme ve yükleme

### Hava Durumu Entegrasyonu
- **Open Meteo API**: Ücretsiz hava durumu verileri
- **Şehir Seçimi**: Türkiye'deki tüm şehirler destekleniyor
- **Tarımsal Veriler**: Toprak nemi, sıcaklık, UV indeksi
- **Akıllı Öneriler**: Hava durumuna göre tarımsal tavsiyeler
- **24 Saatlik Tahmin**: Detaylı hava durumu öngörüleri

## 🛠️ Geliştirme Notları

### Yeni Özellik Ekleme
1. Veritabanı şemasını güncelleyin
2. RLS politikalarını ekleyin
3. Flutter servislerini güncelleyin
4. UI bileşenlerini entegre edin
5. Aktivite loglama ekleyin

### API Anahtarı Ekleme
1. Edge Function'da yeni servis desteği ekleyin
2. Environment variables'a anahtarı ekleyin
3. Flutter servisinde yeni servis metodunu ekleyin

## 🚨 Önemli Notlar

- `.env` dosyasını `.gitignore`'a ekleyin
- Production'da API anahtarlarını güvenli şekilde saklayın
- RLS politikalarını test edin
- Edge Functions'ları düzenli olarak güncelleyin

## 📞 Destek

Herhangi bir sorun yaşarsanız:
1. Supabase Dashboard'da logları kontrol edin
2. Flutter debug console'unu inceleyin
3. RLS politikalarını doğrulayın
4. Environment variables'ları kontrol edin




-- Hava Durumu Verileri Database Kurulumu
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Şehirler tablosu oluştur
CREATE TABLE IF NOT EXISTS cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Hava durumu verileri tablosu
CREATE TABLE IF NOT EXISTS weather_data (
    id SERIAL PRIMARY KEY,
    city_id INTEGER REFERENCES cities(id) ON DELETE CASCADE,
    temperature DECIMAL(5, 2) NOT NULL,
    humidity INTEGER NOT NULL,
    wind_speed DECIMAL(5, 2) NOT NULL,
    wind_direction INTEGER NOT NULL,
    pressure DECIMAL(7, 2) NOT NULL,
    cloud_cover INTEGER NOT NULL,
    uv_index DECIMAL(4, 2) NOT NULL,
    weather_code INTEGER NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Tarımsal veriler tablosu
CREATE TABLE IF NOT EXISTS agricultural_data (
    id SERIAL PRIMARY KEY,
    city_id INTEGER REFERENCES cities(id) ON DELETE CASCADE,
    soil_temperature_0cm DECIMAL(5, 2) NOT NULL,
    soil_temperature_6cm DECIMAL(5, 2) NOT NULL,
    soil_temperature_18cm DECIMAL(5, 2) NOT NULL,
    soil_moisture_0_to_1cm DECIMAL(4, 3) NOT NULL,
    soil_moisture_1_to_3cm DECIMAL(4, 3) NOT NULL,
    soil_moisture_3_to_9cm DECIMAL(4, 3) NOT NULL,
    soil_moisture_9_to_27cm DECIMAL(4, 3) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. RLS politikaları
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE agricultural_data ENABLE ROW LEVEL SECURITY;

-- Cities tablosu için politikalar
CREATE POLICY "Cities are viewable by everyone" ON cities
    FOR SELECT USING (true);

CREATE POLICY "Cities are insertable by authenticated users" ON cities
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Weather data için politikalar
CREATE POLICY "Weather data is viewable by everyone" ON weather_data
    FOR SELECT USING (true);

CREATE POLICY "Weather data is insertable by authenticated users" ON weather_data
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Agricultural data için politikalar
CREATE POLICY "Agricultural data is viewable by everyone" ON agricultural_data
    FOR SELECT USING (true);

CREATE POLICY "Agricultural data is insertable by authenticated users" ON agricultural_data
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 5. Türkiye'nin 81 ili ekle
INSERT INTO cities (name, latitude, longitude) VALUES
('Adana', 37.0000, 35.3213),
('Adıyaman', 37.7636, 38.2786),
('Afyonkarahisar', 38.7507, 30.5567),
('Ağrı', 39.7191, 43.0503),
('Amasya', 40.6499, 35.8353),
('Ankara', 39.9334, 32.8597),
('Antalya', 36.8969, 30.7133),
('Artvin', 41.1828, 41.8183),
('Aydın', 37.8560, 27.8416),
('Balıkesir', 39.6484, 27.8826),
('Bilecik', 40.1501, 29.9831),
('Bingöl', 38.8847, 40.4981),
('Bitlis', 38.3938, 42.1232),
('Bolu', 40.7396, 31.6060),
('Burdur', 37.7206, 30.2906),
('Bursa', 40.1826, 29.0665),
('Çanakkale', 40.1553, 26.4142),
('Çankırı', 40.6013, 33.6134),
('Çorum', 40.5506, 34.9556),
('Denizli', 37.7765, 29.0864),
('Diyarbakır', 37.9144, 40.2306),
('Edirne', 41.6771, 26.5557),
('Elazığ', 38.6810, 39.2264),
('Erzincan', 39.7500, 39.5000),
('Erzurum', 39.9334, 41.2767),
('Eskişehir', 39.7767, 30.5206),
('Gaziantep', 37.0662, 37.3833),
('Giresun', 40.9128, 38.3895),
('Gümüşhane', 40.4603, 39.5086),
('Hakkâri', 37.5833, 43.7333),
('Hatay', 36.4018, 36.3498),
('Isparta', 37.7648, 30.5566),
('Mersin', 36.8000, 34.6333),
('İstanbul', 41.0082, 28.9784),
('İzmir', 38.4192, 27.1287),
('Kars', 41.3887, 33.7827),
('Kastamonu', 41.3887, 33.7827),
('Kayseri', 38.7312, 35.4787),
('Kırklareli', 41.7350, 27.2256),
('Kırşehir', 39.1425, 34.1709),
('Kocaeli', 40.8533, 29.8815),
('Konya', 37.8667, 32.4833),
('Kütahya', 39.4186, 29.9831),
('Malatya', 38.3552, 38.3095),
('Manisa', 38.6191, 27.4289),
('Kahramanmaraş', 37.5858, 36.9371),
('Mardin', 37.3212, 40.7245),
('Muğla', 37.2153, 28.3636),
('Muş', 38.9462, 41.7539),
('Nevşehir', 38.6939, 34.6857),
('Niğde', 37.9667, 34.6833),
('Ordu', 40.9839, 37.8764),
('Rize', 41.0201, 40.5234),
('Sakarya', 40.7889, 30.4053),
('Samsun', 41.2928, 36.3313),
('Siirt', 37.9274, 41.9403),
('Sinop', 42.0231, 35.1531),
('Sivas', 39.7477, 37.0179),
('Tekirdağ', 40.9833, 27.5167),
('Tokat', 40.3167, 36.5500),
('Trabzon', 41.0015, 39.7178),
('Tunceli', 39.1079, 39.5401),
('Şanlıurfa', 37.1591, 38.7969),
('Uşak', 38.6823, 29.4082),
('Van', 38.4891, 43.4089),
('Yozgat', 39.8181, 34.8147),
('Zonguldak', 41.4564, 31.7987),
('Aksaray', 38.3687, 34.0370),
('Bayburt', 40.2552, 40.2249),
('Karaman', 37.1759, 33.2287),
('Kırıkkale', 39.8468, 33.4987),
('Batman', 37.8812, 41.1351),
('Şırnak', 37.4187, 42.4918),
('Bartın', 41.6344, 32.3375),
('Ardahan', 41.1105, 42.7022),
('Iğdır', 39.9208, 44.0048),
('Yalova', 40.6550, 29.2769),
('Karabük', 41.2061, 32.6204),
('Kilis', 36.7184, 37.1212),
('Osmaniye', 37.0742, 36.2478),
('Düzce', 40.8438, 31.1565)
ON CONFLICT (name) DO NOTHING;

-- 6. Örnek hava durumu verileri ekle (İstanbul için)
INSERT INTO weather_data (city_id, temperature, humidity, wind_speed, wind_direction, pressure, cloud_cover, uv_index, weather_code)
SELECT 
    c.id,
    22.5 + (RANDOM() * 10 - 5), -- 17.5-27.5 arası sıcaklık
    60 + (RANDOM() * 20), -- 60-80 arası nem
    5 + (RANDOM() * 15), -- 5-20 arası rüzgar hızı
    RANDOM() * 360, -- 0-360 arası rüzgar yönü
    1010 + (RANDOM() * 20), -- 1010-1030 arası basınç
    RANDOM() * 100, -- 0-100 arası bulut örtüsü
    2 + (RANDOM() * 8), -- 2-10 arası UV indeksi
    CASE 
        WHEN RANDOM() < 0.3 THEN 0 -- Açık
        WHEN RANDOM() < 0.6 THEN 1 -- Az bulutlu
        WHEN RANDOM() < 0.8 THEN 2 -- Parçalı bulutlu
        ELSE 3 -- Çok bulutlu
    END
FROM cities c
WHERE c.name = 'İstanbul';

-- 7. Örnek tarımsal veriler ekle (İstanbul için)
INSERT INTO agricultural_data (city_id, soil_temperature_0cm, soil_temperature_6cm, soil_temperature_18cm, soil_moisture_0_to_1cm, soil_moisture_1_to_3cm, soil_moisture_3_to_9cm, soil_moisture_9_to_27cm)
SELECT 
    c.id,
    18.5 + (RANDOM() * 5 - 2.5), -- 16-21 arası toprak sıcaklığı
    16.8 + (RANDOM() * 3 - 1.5), -- 15.3-18.3 arası
    15.2 + (RANDOM() * 2 - 1), -- 14.2-16.2 arası
    0.3 + (RANDOM() * 0.4), -- 0.3-0.7 arası toprak nemi
    0.4 + (RANDOM() * 0.3), -- 0.4-0.7 arası
    0.35 + (RANDOM() * 0.3), -- 0.35-0.65 arası
    0.3 + (RANDOM() * 0.25) -- 0.3-0.55 arası
FROM cities c
WHERE c.name = 'İstanbul';

-- 8. İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_weather_data_city_id ON weather_data(city_id);
CREATE INDEX IF NOT EXISTS idx_weather_data_recorded_at ON weather_data(recorded_at);
CREATE INDEX IF NOT EXISTS idx_agricultural_data_city_id ON agricultural_data(city_id);
CREATE INDEX IF NOT EXISTS idx_agricultural_data_recorded_at ON agricultural_data(recorded_at);

-- 9. Trigger fonksiyonları
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger'ları oluştur
DROP TRIGGER IF EXISTS update_cities_updated_at ON cities;
CREATE TRIGGER update_cities_updated_at
    BEFORE UPDATE ON cities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 10. Başarı mesajı
DO $$
BEGIN
    RAISE NOTICE 'Hava durumu veritabanı başarıyla kuruldu!';
    RAISE NOTICE 'Tablolar: cities, weather_data, agricultural_data';
    RAISE NOTICE '81 il eklendi ve örnek veriler oluşturuldu';
END $$;



